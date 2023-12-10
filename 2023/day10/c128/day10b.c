#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>
#include <time.h>
#include <stdbool.h>
#include <c128.h>

#define BUFFER_LENGTH 256
#define PIPE_MAP_MAX_COLS 142
#define PIPE_MAP_MAX_ROWS 142
#define FILENAME "input.txt,s"
#define GROUND 0
#define PIPE_E 0x1
#define PIPE_N 0x2
#define PIPE_W 0x4
#define PIPE_S 0x8
#define PIPE_NS 0xa
#define PIPE_EW 0x5
#define PIPE_NE 0x3
#define PIPE_NW 0x6
#define PIPE_SE 0x9
#define PIPE_SW 0xc
#define ON_PATH 0x10
#define INSIDE 0x20
#define TO_FLAT_INDEX(I,J) ((I)*PIPE_MAP_MAX_COLS+(J))
#define HASH_SET_CAPACITY 512
#define HASH_SET_UNOCCUPIED 0xffff
#define HASH_SET_DELETED 0xfffe
#define QUEUE_LENGTH 320

static uint8_t pipe_map[PIPE_MAP_MAX_ROWS][PIPE_MAP_MAX_COLS];
static uint8_t start[2];

struct HashSet {
  uint16_t H[HASH_SET_CAPACITY];
  uint16_t size;
};

static struct HashSet inside;
static struct HashSet queue;

enum Direction {
  EAST,
  WEST,
  NORTH,
  SOUTH
};


void hash_set_init(struct HashSet* H) {
  memset(H->H, HASH_SET_UNOCCUPIED, HASH_SET_CAPACITY*sizeof(uint16_t));
  H->size = 0;
}

uint16_t hash(uint8_t i, uint8_t j) {
  return 1571802787*((((uint32_t)i) << 8) | ((uint32_t)i)) >> 23;
}

bool hash_set_contains(struct HashSet* H, uint8_t i, uint8_t j) {
  uint16_t h = hash(i,j);
  uint16_t f = TO_FLAT_INDEX(i,j);
  while (H->H[h] != HASH_SET_UNOCCUPIED) {
    if (H->H[h] == f)
      return true;
    ++h;
    if (h >= HASH_SET_CAPACITY)
      h = 0;
  }
  return false;
}

void hash_set_insert(struct HashSet* H, uint8_t i, uint8_t j) {
  uint16_t h = hash(i,j);
  uint16_t f = TO_FLAT_INDEX(i,j);
  if (hash_set_contains(H, i, j))
    return;
  while (H->H[h] != HASH_SET_UNOCCUPIED && 
         H->H[h] != HASH_SET_DELETED) {
    ++h;
    if (h >= HASH_SET_CAPACITY)
      h = 0;
  }
  H->H[h] = f;
  ++H->size;
}

void hash_set_pop(struct HashSet* H, uint8_t* u) {
  uint16_t h = 0;
  while (H->H[h] == HASH_SET_UNOCCUPIED || H->H[h] == HASH_SET_DELETED)
    ++h;
  u[0] = H->H[h] / PIPE_MAP_MAX_COLS;
  u[1] = H->H[h] % PIPE_MAP_MAX_COLS;
  H->H[h] = HASH_SET_DELETED;
  --H->size;
}

void read_data() {
  FILE* f;
  char* c;
  uint8_t i,j;
  static char buffer[BUFFER_LENGTH];

  f = fopen(FILENAME, "r");

  i = 0;
  while (fgets(buffer, BUFFER_LENGTH, f)) {
    ++i;
    c = buffer;
    j = 0;
    while (*c != '\n') {
      ++j;
      switch (*c) {
      case 's':
        start[0] = i;
        start[1] = j;
        break;
      case '7':
        pipe_map[i][j] = PIPE_SW;        
        break;
      case 'f':
        pipe_map[i][j] = PIPE_SE;
        break;
      case 'j':
        pipe_map[i][j] = PIPE_NW;
        break;
      case 'l':
        pipe_map[i][j] = PIPE_NE;
        break;
      case '-':
        pipe_map[i][j] = PIPE_EW;
        break;
      case 124:
        pipe_map[i][j] = PIPE_NS;
        break;
      case '.':
        break;
      default:
        printf("unhandled %c (%d)\n", *c, (int)(*c));
        break;
      }
      ++c;
    }
  }  
  fclose(f);
}

void determine_start_pipe() {
  uint8_t i,j;
  i = start[0];
  j = start[1];
  if ((pipe_map[i-1][j] & PIPE_S) != 0 && (pipe_map[i+1][j] & PIPE_N) != 0)
    pipe_map[i][j] = PIPE_NS;
  else if ((pipe_map[i][j-1] & PIPE_E) != 0 && (pipe_map[i][j+1] & PIPE_W) != 0)
    pipe_map[i][j] = PIPE_EW;
  else if ((pipe_map[i-1][j] & PIPE_S) != 0 && (pipe_map[i][j+1] & PIPE_W) != 0)
    pipe_map[i][j] = PIPE_NE;
  else if ((pipe_map[i-1][j] & PIPE_S) != 0 && (pipe_map[i][j-1] & PIPE_E) != 0)
    pipe_map[i][j] = PIPE_NW;
  else if ((pipe_map[i+1][j] & PIPE_N) != 0 && (pipe_map[i][j+1] & PIPE_W) != 0)
    pipe_map[i][j] = PIPE_SE;
  else if ((pipe_map[i+1][j] & PIPE_N) != 0 && (pipe_map[i][j-1] & PIPE_E) != 0)
    pipe_map[i][j] = PIPE_SW;
}

void get_neighbors(uint8_t* cur, uint8_t* N) {
  uint8_t u,v,i,j,k;
  i = cur[0];
  j = cur[1];
  u = pipe_map[i][j];
  k = 0;
  v = pipe_map[i][j+1];
  if ((u & PIPE_E) && (v & PIPE_W)) {
    N[k++] = i;
    N[k++] = j+1;
  }
  v = pipe_map[i-1][j];
  if ((u & PIPE_N) && (v & PIPE_S)) {
    N[k++] = i-1;
    N[k++] = j;
  }
  v = pipe_map[i][j-1];
  if ((u & PIPE_W) && (v & PIPE_E)) {
    N[k++] = i;
    N[k++] = j-1;
  }
  v = pipe_map[i+1][j];
  if ((u & PIPE_S) && (v & PIPE_N)) {
    N[k++] = i+1;
    N[k++] = j;
  }
}

void next_node(uint8_t* cur, uint8_t* pre) {
  static uint8_t N[4];
  get_neighbors(cur, N);
  if (N[0] == pre[0] && N[1] == pre[1]) {
    pre[0] = cur[0];
    pre[1] = cur[1];
    cur[0] = N[2];
    cur[1] = N[3];
  }
  else {
    pre[0] = cur[0];
    pre[1] = cur[1];
    cur[0] = N[0];
    cur[1] = N[1];
  }
}

enum Direction vec_to_dir(uint8_t* v, uint8_t* u) {
  if (v[0] > u[0])
    return SOUTH;
  if (v[0] < u[0])
    return NORTH;
  if (v[1] > u[1])
    return EAST;
  if (v[1] < u[1])
    return WEST;
  return WEST;
}

const char* dir_to_string(enum Direction dir) {
  switch (dir) {
  case EAST:
    return "east";
    break;
  case NORTH:
    return "north";
    break;
  case WEST:
    return "west";
    break;
  case SOUTH:
    return "south";
    break;
  }
}

void get_left_neighbors(uint8_t* u,
                        uint8_t* v,
                        uint8_t* w,
                        uint8_t* N, 
                        uint8_t* num_neighbors) {
  enum Direction dir1, dir2;
  *num_neighbors = 0;
  dir1 = vec_to_dir(v,u);
  dir2 = vec_to_dir(w,v);
  if (dir1 == WEST) {
    if (dir2 == WEST) {
      N[0] = v[0]+1;
      N[1] = v[1];
      *num_neighbors = 1;
    }
    else if (dir2 == SOUTH) {
      N[0] = v[0]+1;
      N[1] = v[1]+1;
      *num_neighbors = 1;
    }
    else if (dir2 == NORTH) {
      N[0] = v[0]+1;
      N[1] = v[1];
      N[2] = v[0]+1;
      N[3] = v[1]-1;
      N[4] = v[0];
      N[5] = v[1]-1;
      *num_neighbors = 3;
    }
    else {
      printf("ERROR %s %s\n", dir_to_string(dir1), dir_to_string(dir2));
      exit(1);
    }
  }
  else if (dir1 == EAST) {
    if (dir2 == EAST) {
      N[0] = v[0]-1;
      N[1] = v[1];
      *num_neighbors = 1;
    }
    else if (dir2 == NORTH) {
      N[0] = v[0]-1;
      N[1] = v[1]-1;
      *num_neighbors = 1;
    }
    else if (dir2 == SOUTH) {
      N[0] = v[0]-1;
      N[1] = v[1];
      N[2] = v[0]-1;
      N[3] = v[1]+1;
      N[4] = v[0];
      N[5] = v[1]+1;
      *num_neighbors = 3;
    }
    else {
      printf("ERROR %s %s\n", dir_to_string(dir1), dir_to_string(dir2));
      exit(1);
    }
  }
  else if (dir1 == SOUTH) {
    if (dir2 == SOUTH) {
      N[0] = v[0];
      N[1] = v[1]+1;
      *num_neighbors = 1;
    }
    else if (dir2 == EAST) {
      N[0] = v[0]-1;
      N[1] = v[1]+1;
      *num_neighbors = 1;
    }
    else if (dir2 == WEST) {
      N[0] = v[0];
      N[1] = v[1]+1;
      N[2] = v[0]+1;
      N[3] = v[1]+1;
      N[4] = v[0]+1;
      N[5] = v[1];
      *num_neighbors = 3;
    }
    else {
      printf("ERROR %s %s\n", dir_to_string(dir1), dir_to_string(dir2));
      exit(1);
    }
  }
  else if (dir1 == NORTH) {
    if (dir2 == NORTH) {
      N[0] = v[0];
      N[1] = v[1]-1;
      *num_neighbors = 1;
    }
    else if (dir2 == WEST) {
      N[0] = v[0]+1;
      N[1] = v[1]-1;
      *num_neighbors = 1;
    }
    else if (dir2 == EAST) {
      N[0] = v[0];
      N[1] = v[1]-1;
      N[2] = v[0]-1;
      N[3] = v[1]-1;
      N[4] = v[0]-1;
      N[5] = v[1];
      *num_neighbors = 3;
    }
    else {
      printf("ERROR %s %s\n", dir_to_string(dir1), dir_to_string(dir2));
      exit(1);
    }
  }
  else {
    printf("ERROR %s %s\n", dir_to_string(dir1), dir_to_string(dir2));
    exit(1);
  }
}

void get_right_neighbors(uint8_t* u,
                         uint8_t* v,
                         uint8_t* w,
                         uint8_t* N, 
                         uint8_t* num_neighbors) {
  get_left_neighbors(w,v,u,N,num_neighbors);
}


void solve() {
  static uint8_t u[2];
  static uint8_t v[2];
  static uint8_t w[2];
  uint16_t path_length = 0;
  uint8_t min_i, min_j, max_i, max_j;
  static uint8_t neighbors[6];
  uint8_t num_neighbors;
  bool inside_is_left = false;
  bool inside_is_right = false;
  uint8_t i,j,k;
  determine_start_pipe();
  u[0] = start[0];
  u[1] = start[1];
  v[0] = start[0];
  v[1] = start[1];
  pipe_map[start[0]][start[1]] |= ON_PATH;
  min_i = max_i = start[0];
  min_j = max_j = start[1];
  do {
    next_node(u, v);
    pipe_map[u[0]][u[1]] |= ON_PATH;
    if (min_i > u[0])
      min_i = u[0];
    if (max_i < u[0])
      max_i = u[0];
    if (min_j > u[1])
      min_j = u[1];
    if (max_j < u[1])
      max_j = u[1];
    ++path_length;
  }
  while (u[0] != start[0] || u[1] != start[1]);

  u[0] = start[0];
  u[1] = start[1];
  v[0] = start[0];
  v[1] = start[1];
  w[0] = start[0];
  w[1] = start[1];
  next_node(w,v);
  do {
    u[0] = v[0];
    u[1] = v[1];
    next_node(w,v);
    get_left_neighbors(u,v,w,neighbors,&num_neighbors);
    for (k = 0; k < num_neighbors; ++k) {
      if (neighbors[2*k] < min_i ||
          neighbors[2*k] > max_i ||
          neighbors[2*k+1] < min_j ||
          neighbors[2*k+1] > max_j) {
        inside_is_right = true;
        goto found_inside;
      }
    }
    get_right_neighbors(u,v,w,neighbors,&num_neighbors);
    for (k = 0; k < num_neighbors; ++k) {
      if (neighbors[2*k] < min_i ||
          neighbors[2*k] > max_i ||
          neighbors[2*k+1] < min_j ||
          neighbors[2*k+1] > max_j) {
        inside_is_left = true;
        goto found_inside;
      }
    }
  }
  while (v[0] != start[0] || v[1] != start[1]);

 found_inside:

  hash_set_init(&queue);

  u[0] = start[0];
  u[1] = start[1];
  v[0] = start[0];
  v[1] = start[1];
  w[0] = start[0];
  w[1] = start[1];
  next_node(w,v);
  do {
    u[0] = v[0];
    u[1] = v[1];
    next_node(w,v);
    if (inside_is_left)
      get_left_neighbors(u,v,w,neighbors,&num_neighbors);
    if (inside_is_right)
      get_right_neighbors(u,v,w,neighbors,&num_neighbors);
    for (k = 0; k < num_neighbors; ++k) {
      i = neighbors[2*k];
      j = neighbors[2*k+1];
      if ((pipe_map[i][j] & ON_PATH) == 0) {
        hash_set_insert(&queue, i, j);
      }
    }
  }
  while (v[0] != start[0] || v[1] != start[1]);

  hash_set_init(&inside);
  while (queue.size > 0) {
    hash_set_pop(&queue,u);
    if ((pipe_map[u[0]][u[1]] & ON_PATH) == 0 &&
        (pipe_map[u[0]][u[1]] & INSIDE) == 0) {
      hash_set_insert(&inside, u[0], u[1]);
      pipe_map[u[0]][u[1]] |= INSIDE;
      i = u[0]+1;
      j = u[1];
      if ((pipe_map[i][j] & ON_PATH) == 0 &&
          (pipe_map[i][j] & INSIDE) == 0)
        hash_set_insert(&queue, i, j);
      i = u[0]-1;
      if ((pipe_map[i][j] & ON_PATH) == 0 &&
          (pipe_map[i][j] & INSIDE) == 0)
        hash_set_insert(&queue, i, j);
      i = u[0];
      j = u[1]+1;
      if ((pipe_map[i][j] & ON_PATH) == 0 &&
          (pipe_map[i][j] & INSIDE) == 0)
        hash_set_insert(&queue, i, j);
      j = u[1]-1;
      if ((pipe_map[i][j] & ON_PATH) == 0 &&
          (pipe_map[i][j] & INSIDE) == 0)
        hash_set_insert(&queue, i, j);
    }
  }
  printf("%" PRIu16 "\n", inside.size);
}

int main(void) {
  fast();
  memset(pipe_map, 0, PIPE_MAP_MAX_COLS*PIPE_MAP_MAX_ROWS*sizeof(uint8_t));

  read_data();
  printf("data read at: %ld s\n", clock()/CLOCKS_PER_SEC);

  solve();
  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  slow();
  return EXIT_SUCCESS;
}
