#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>
#include <assert.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>

#define MAX_BRICKS 1419
#define MAX_LINE_LENGTH 128
#define MAX_X 10
#define MAX_Y 10
#define MAX_Z 350
#define MAX_SUPPORT 6
#define QUEUE_CAPACITY 8192
#define HASH_SET_CAPACITY_BITS 14
#define HASH_SET_CAPACITY (1 << HASH_SET_CAPACITY_BITS)

struct Queue {
  int Q[QUEUE_CAPACITY];
  int begin;
  int end;
};

struct HashSet {
  uint32_t keys[HASH_SET_CAPACITY];
  bool occupied[HASH_SET_CAPACITY];
  int size;
};

enum Orientation {
  ALONG_X, ALONG_Y, ALONG_Z, UNITARY
};

struct Brick {
  int min_xyz[3];
  int max_xyz[3];
  enum Orientation orientation;
};

struct Map {
  int A[MAX_X][MAX_Y][MAX_Z];
  int max_xyz[3];
};

struct Support {
  int supports[MAX_BRICKS][MAX_SUPPORT];
  int supported[MAX_BRICKS][MAX_SUPPORT];
  int num_supports[MAX_BRICKS];
  int num_supported[MAX_BRICKS];
};

uint32_t hash(uint32_t x) {
  return (4214180506556308713lu * x) >> (64-HASH_SET_CAPACITY_BITS);
}

void queue_init(struct Queue* q) {
  q->begin = q->end = 0;
}

void queue_requeue(struct Queue* q) {
  assert(q->begin > 0);
  int len = q->end - q->begin;
  int* p = &q->Q[q->begin];
  for (int i = 0; i < len; ++i) {
    q->Q[i] = *p++;
  }
  q->begin = 0;
  q->end = len;
}

void queue_enequeue(struct Queue* q, int x) {
  if (q->end == QUEUE_CAPACITY) {
    queue_requeue(q);
  }
  assert(q->end < QUEUE_CAPACITY);
  q->Q[q->end++] = x;
}

int queue_dequeue(struct Queue* q) {
  return q->Q[q->begin++];
}

void hashset_init(struct HashSet* H) {
  H->size = 0;
  memset(H->occupied, 0, HASH_SET_CAPACITY*sizeof(bool));
}

void hashset_insert(struct HashSet* H, uint32_t key) {
  uint32_t h = hash(key);
  while (H->occupied[h]) {
    if (H->keys[h] == key)
      return;
    ++h;
    if (h == HASH_SET_CAPACITY)
      h = 0;
  }
  H->occupied[h] = true;
  H->keys[h] = key;
  ++H->size;
}

bool hashset_contains(const struct HashSet* H, uint32_t key) {
  uint32_t h = hash(key);
  while (H->occupied[h]) {
    if (H->keys[h] == key)
      return true;
    ++h;
    if (h == HASH_SET_CAPACITY)
      h = 0;
  }
  return false;
}

static void read_data(const char* filename, struct Brick* bricks, 
                      int* num_bricks, int* min_vals, int* max_vals) {
  static char buffer[MAX_LINE_LENGTH];
  FILE* f = fopen(filename,"r");
  int min_xyz[3];
  int max_xyz[3];
  *num_bricks = 0;
  for (int i = 0; i < 3; ++i) {
    min_vals[i] = 9999;
    max_vals[i] = -1;
  }

  while(fgets(buffer, MAX_LINE_LENGTH, f)) {
    int len = strlen(buffer);
    buffer[--len] = '\0';
    char* p = strchr(buffer, '~');
    *p++ = '\0';

    min_xyz[0] = atoi(strtok(buffer, ","));
    min_xyz[1] = atoi(strtok(NULL, ","));
    min_xyz[2] = atoi(strtok(NULL, ","));
    max_xyz[0] = atoi(strtok(p, ","));
    max_xyz[1] = atoi(strtok(NULL, ","));
    max_xyz[2] = atoi(strtok(NULL, ","));

    assert(min_xyz[0] >= 0);
    assert(min_xyz[1] >= 0);
    assert(min_xyz[2] >= 1);

    if (min_xyz[0] == max_xyz[0] && 
        min_xyz[1] == max_xyz[1] && 
        min_xyz[2] == max_xyz[2]) {
      bricks[*num_bricks].orientation = UNITARY;
    }
    else if (min_xyz[0] == max_xyz[0] && 
             min_xyz[1] == max_xyz[1] && 
             min_xyz[2] <= max_xyz[2]) {
      bricks[*num_bricks].orientation = ALONG_Z;
    }
    else if (min_xyz[0] == max_xyz[0] && 
             min_xyz[1] <= max_xyz[1] && 
             min_xyz[2] == max_xyz[2]) {
      bricks[*num_bricks].orientation = ALONG_Y;
    }
    else if (min_xyz[0] <= max_xyz[0] && 
             min_xyz[1] == max_xyz[1] && 
             min_xyz[2] == max_xyz[2]) {
      bricks[*num_bricks].orientation = ALONG_X;
    }
    else {
      assert(false && "invalid brick");
    }

    for (int i = 0; i < 3; ++i) {
      bricks[*num_bricks].min_xyz[i] = min_xyz[i];
      bricks[*num_bricks].max_xyz[i] = max_xyz[i];
      if (min_xyz[i] < min_vals[i])
        min_vals[i] = min_xyz[i];
      if (max_xyz[i] > max_vals[i])
        max_vals[i] = max_xyz[i];
    }

    ++(*num_bricks);
  }
  fclose(f);
}

static void print_brick(FILE* out, const struct Brick* b) {
  fprintf(out, "(%d,%d,%d)~(%d,%d,%d) %c\n",
          b->min_xyz[0], b->min_xyz[1], b->min_xyz[2], 
          b->max_xyz[0], b->max_xyz[1], b->max_xyz[2], 
          b->orientation == UNITARY ? 'u' :
          b->orientation == ALONG_X ? 'x' :
          b->orientation == ALONG_Y ? 'y' :
          b->orientation == ALONG_Z ? 'z' :
          '?');
}


static void populate_map_with_brick(struct Map* map,
                                    const struct Brick* brick,
                                    int brick_num) {
  int x0, y0, z0;
  if (brick->orientation == UNITARY) {
      x0 = brick->min_xyz[0];
      y0 = brick->min_xyz[1];
      z0 = brick->min_xyz[2];
      map->A[x0][y0][z0] = brick_num;
  }
  else if (brick->orientation == ALONG_X) {
    y0 = brick->min_xyz[1];
    z0 = brick->min_xyz[2];
    for (int x = brick->min_xyz[0]; x <= brick->max_xyz[0]; ++x) {
      map->A[x][y0][z0] = brick_num;
    }
  }
  else if (brick->orientation == ALONG_Y) {
    x0 = brick->min_xyz[0];
    z0 = brick->min_xyz[2];
    for (int y = brick->min_xyz[1]; y <= brick->max_xyz[1]; ++y) {
      map->A[x0][y][z0] = brick_num;
    }
  }
  else if (brick->orientation == ALONG_Z) {
    x0 = brick->min_xyz[0];
    y0 = brick->min_xyz[1];
    for (int z = brick->min_xyz[2]; z <= brick->max_xyz[2]; ++z) {
      map->A[x0][y0][z] = brick_num;
    }
  }
  else {
    assert(false && "invalid brick");
  }
}

static void populate_map(struct Map* map,
                         const struct Brick* bricks,
                         int num_bricks) {
  memset(map->A, 0, sizeof(map->A));
  for (int j = 0; j < 3; ++j)
    map->max_xyz[j] = 0;

  for (int i = 0; i < num_bricks; ++i) {
    const struct Brick* brick = bricks + i;
    for (int j = 0; j < 3; ++j)
      if (brick->max_xyz[j] > map->max_xyz[j])
        map->max_xyz[j] = brick->max_xyz[j];
    populate_map_with_brick(map, brick, i+1);
  }
}

static void print_map_x(FILE* out, const struct Map* map) {
  for (int z = map->max_xyz[2]; z >= 0; --z) {
    for (int x = 0; x <= map->max_xyz[0]; ++x) {
      if (z > 0) {
        bool empty = true;
        for (int y = 0; y <= map->max_xyz[1]; ++y) {
          if (map->A[x][y][z] > 0) {
            fprintf(out, "%c", 'A' + map->A[x][y][z] - 1);
            empty = false;
            break;
          }
        }
        if (empty)
          fprintf(out, "%c", '.');
      }
      else {
        fprintf(out, "%c", '-');
      }
    }
    fprintf(out, "\n");
  }
}

static void print_map_y(FILE* out, const struct Map* map) {
  for (int z = map->max_xyz[2]; z >= 0; --z) {
    for (int y = 0; y <= map->max_xyz[1]; ++y) {
      if (z > 0) {
        bool empty = true;
        for (int x = 0; x <= map->max_xyz[0]; ++x) {
          if (map->A[x][y][z] > 0) {
            fprintf(out, "%c", 'A' + map->A[x][y][z] - 1);
            empty = false;
            break;
          }
        }
        if (empty)
          fprintf(out, "%c", '.');
      }
      else {
        fprintf(out, "%c", '-');
      }
    }
    fprintf(out, "\n");
  }
}

int clear_below(const struct Map* map, const struct Brick* brick) {
  int c = 0;
  int x0 = brick->min_xyz[0];
  int y0 = brick->min_xyz[1];
  int z0 = brick->min_xyz[2];
  while (z0 - c > 1) {
    bool blocked = false;
    if (brick->orientation == UNITARY || brick->orientation == ALONG_Z) {
      if (map->A[x0][y0][z0-c-1] != 0) {
        blocked = true;
      }
    }
    else if (brick->orientation == ALONG_X) {
      for (int x = x0; x <= brick->max_xyz[0]; ++x) {
        if (map->A[x][y0][z0-c-1] != 0) {
          blocked = true;
          break;
        }
      }
    }
    else if (brick->orientation == ALONG_Y) {
      for (int y = y0; y <= brick->max_xyz[1]; ++y) {
        if (map->A[x0][y][z0-c-1] != 0) {
          blocked = true;
          break;
        }
      }
    }
    else {
      assert(false && "invalid brick");
    }
    if (blocked)
      break;
    ++c;
  }
  return c;
}

static void move_brick_down(struct Map* map, struct Brick* brick, int c) {
  int x0 = brick->min_xyz[0];
  int y0 = brick->min_xyz[1];
  int z0 = brick->min_xyz[2];
  int x1 = brick->max_xyz[0];
  int y1 = brick->max_xyz[1];
  int z1 = brick->max_xyz[2];
  int brick_num = map->A[x0][y0][z0];
  if (brick->orientation == UNITARY) {
    map->A[x0][y0][z0] = 0;
    map->A[x0][y0][z0-c] = brick_num;
  }
  else if (brick->orientation == ALONG_X) {
    for (int x = x0; x <= x1; ++x) {
      map->A[x][y0][z0] = 0;
      map->A[x][y0][z0-c] = brick_num;
    }
  }
  else if (brick->orientation == ALONG_Y) {
    for (int y = y0; y <= y1; ++y) {
      map->A[x0][y][z0] = 0;
      map->A[x0][y][z0-c] = brick_num;
    }
  }
  else if (brick->orientation == ALONG_Z) {
    for (int z = z0; z <= z1; ++z) {
      map->A[x0][y0][z] = 0;
      map->A[x0][y0][z-c] = brick_num;
    }
  }
  else {
    assert(false && "invalid brick");
  }
  brick->min_xyz[2] -= c;
  brick->max_xyz[2] -= c;
}

static void move_all_down(struct Map* map, struct Brick* bricks, 
                          int num_bricks) {
  bool moved = true;
  while (moved) {
    moved = false;
    for (int i = 0; i < num_bricks; ++i) {
      int c = clear_below(map, &bricks[i]);
      if (c > 0) {
        move_brick_down(map, &bricks[i], c);
        moved = true;
      }
    }
  }
}

void add_support(struct Support* support, int i, int j) {
  bool supports_exists = false;
  bool supported_exists = false;
  for (int k = 0; k < support->num_supports[i]; ++k) {
    if (support->supports[i][k] == j) {
      supports_exists = true;
      break;
    }
  }
  for (int k = 0; k < support->num_supported[j]; ++k) {
    if (support->supported[j][k] == i) {
      supported_exists = true;
      break;
    }
  }
  if (!supports_exists)
    support->supports[i][support->num_supports[i]++] = j;
  if (!supported_exists)
    support->supported[j][support->num_supported[j]++] = i;
}

void find_supports(struct Support* support, struct Map* map, 
                   const struct Brick* bricks, int num_bricks) {
  for (int i = 0; i < num_bricks; ++i) {
    const struct Brick* brick = &bricks[i];
    int x0 = brick->min_xyz[0];
    int y0 = brick->min_xyz[1];
    int z0 = brick->min_xyz[2];
    int x1 = brick->max_xyz[0];
    int y1 = brick->max_xyz[1];
    int z1 = brick->max_xyz[2];
    if (brick->orientation == UNITARY || brick->orientation == ALONG_Z) {
      int j = map->A[x1][y1][z1+1];
      if (j != 0) {
        add_support(support, i, j-1);
      }
    }
    else if (brick->orientation == ALONG_X) {
      for (int x = x0; x <= x1; ++x) {
        int j = map->A[x][y0][z0+1];
        if (j != 0) {
          add_support(support, i, j-1);
        }
      }
    }
    else if (brick->orientation == ALONG_Y) {
      for (int y = y0; y <= y1; ++y) {
        int j = map->A[x0][y][z0+1];
        if (j != 0) {
          add_support(support, i, j-1);
        }
      }
    }
  }
}

static double time_diff(struct timespec* start, struct timespec* end) {
  double ed = end->tv_sec + end->tv_nsec/1e9;
  double sd = start->tv_sec + start->tv_nsec/1e9;
  return ed - sd;  
}

static char* format_time(double secs) {
  static char buffer[256];
  if (secs >= 3600) {
    int hs = secs / 3600;
    int mins = (secs - hs*3600) / 60;
    int ss = secs - hs*3600 - mins*60;
    sprintf(buffer, "%d h %d min %d s", hs, mins, ss);
  }
  else if (secs >= 60) {
    int mins = secs / 60;
    int ss = secs - mins*60;
    sprintf(buffer, "%d min %d s", mins, ss);
  }
  else if (secs >= 1) {
    sprintf(buffer, "%.3f s", secs);
  }
  else if (secs >= 1e-3) {
    sprintf(buffer, "%.3f ms", secs*1e3);
  }
  else if (secs >= 1e-6) {
    sprintf(buffer, u8"%.3f μs", secs*1e6);
  }
  else if (secs >= 1e-9) {
    sprintf(buffer, "%.3f ns", secs*1e9);
  }
  else {
    sprintf(buffer, "0");
  }
  return buffer;
}



int main(int argc, char* argv[]) {
  struct Brick bricks[MAX_BRICKS];
  int num_bricks;
  int min_vals[3];
  int max_vals[3];
  struct Map map;
  struct Support support;
  struct timespec start, end;
  timespec_get(&start, TIME_UTC);
  memset(support.supports, 0, sizeof(support.supports));
  memset(support.supported, 0, sizeof(support.supported));
  memset(support.num_supports, 0, sizeof(support.num_supports));
  memset(support.num_supported, 0, sizeof(support.num_supported));

  if (argc != 2) {
    fprintf(stderr, "usage: %s <input.txt>\n", argv[0]);
    return EXIT_FAILURE;
  }

  read_data(argv[1], bricks, &num_bricks, min_vals, max_vals);
  timespec_get(&end, TIME_UTC);
  printf("data read in %s\n", format_time(time_diff(&start, &end))); 

  populate_map(&map, bricks, num_bricks);

  move_all_down(&map, bricks, num_bricks);

  find_supports(&support, &map, bricks, num_bricks);

  struct HashSet disintegrated;
  struct Queue queue;

  int S = 0;
  for (int i = 0; i < num_bricks; ++i) {
    hashset_init(&disintegrated);
    queue_init(&queue);
    hashset_insert(&disintegrated,i);
    for (int k = 0; k < support.num_supports[i]; ++k)
      queue_enequeue(&queue, support.supports[i][k]);
    while (queue.begin < queue.end) {
      int j = queue_dequeue(&queue);
      bool falls = true;
      for (int k = 0; k < support.num_supported[j]; ++k) {
        if (!hashset_contains(&disintegrated, support.supported[j][k])) {
          falls = false;
          break;
        }
      }
      if (falls) {
        hashset_insert(&disintegrated, j);
        for (int k = 0; k < support.num_supports[j]; ++k)
          queue_enequeue(&queue, support.supports[j][k]);
      }
    }
    S += disintegrated.size - 1;
  }

  printf("%d\n", S);


  timespec_get(&end, TIME_UTC);
  printf("solved in %s\n", format_time(time_diff(&start, &end))); 

  return EXIT_SUCCESS;
}
