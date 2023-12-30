#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <inttypes.h>
#include <assert.h>
#include <string.h>
#include <time.h>

#define FOREST 0
#define PATH 1
#define SLOPE_EAST 2
#define SLOPE_NORTH 4
#define SLOPE_WEST 8
#define SLOPE_SOUTH 16
#define MAX_ROWS 143
#define MAX_COLS 143
#define MAX_LINE_LENGTH 256
#define HASHMAP_CAPACITY_BITS 7
#define HASHMAP_CAPACITY (1 << HASHMAP_CAPACITY_BITS)
#define HASHMAP_UNOCCUPIED 0xffff
#define GRAPH_MAX_NODES 36
#define GRAPH_MAX_NEIGHBORS 4
#define GRAPH_UNNEIGHBOR 0xff
#define QUEUE_CAPACITY 16

struct Map {
  uint8_t A[MAX_ROWS][MAX_COLS];
  int num_rows;
  int num_cols;
  uint8_t S[2];
  uint8_t E[2];
};

struct HashMap {
  uint16_t keys[HASHMAP_CAPACITY];
  uint8_t values[HASHMAP_CAPACITY];
  int size;
};

void hashmap_init(struct HashMap* H) {
  H->size = 0;
  memset(H->keys, 0xff, sizeof(H->keys));
}

struct Graph {
  uint16_t V[GRAPH_MAX_NODES];
  struct HashMap ij_to_v;
  uint8_t E[GRAPH_MAX_NODES][GRAPH_MAX_NEIGHBORS];
  uint16_t W[GRAPH_MAX_NODES][GRAPH_MAX_NODES];
  int num_nodes;
};

static uint8_t hash(uint16_t key) {
  return (4984394598638080197lu * key) >> (64-HASHMAP_CAPACITY_BITS);
}


static void graph_init(struct Graph* G) {
  G->num_nodes = 0;
  hashmap_init(&G->ij_to_v);
  memset(G->E, GRAPH_UNNEIGHBOR, sizeof(G->E));
}

static void hashmap_insert(struct HashMap* H, uint16_t key, uint8_t value) {
  uint8_t h = hash(key);
  while (H->keys[h] != HASHMAP_UNOCCUPIED) {
    assert(H->keys[h] != key);
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  H->keys[h] = key;
  H->values[h] = value;
  ++H->size;
}

void graph_add_node(struct Graph* G, uint8_t i, uint8_t j) {
  assert(G->num_nodes < GRAPH_MAX_NODES);
  uint16_t key = (i << 8) | j;
  G->V[G->num_nodes] = key;
  hashmap_insert(&G->ij_to_v, key, G->num_nodes);
  ++G->num_nodes;
}

static bool hashmap_contains(struct HashMap* H, uint16_t key) {
  uint8_t h = hash(key);
  while (H->keys[h] != HASHMAP_UNOCCUPIED) {
    if (H->keys[h] == key)
      return true;
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  return false;
}

static uint8_t hashmap_find(struct HashMap* H, uint16_t key) {
  uint8_t h = hash(key);
  while (H->keys[h] != HASHMAP_UNOCCUPIED) {
    if (H->keys[h] == key)
      return H->values[h];
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  return GRAPH_UNNEIGHBOR;
}


static bool graph_contains(struct Graph* G, uint8_t i, uint8_t j) {
  uint16_t key = (i << 8) | j;
  return hashmap_contains(&G->ij_to_v, key);
}

static void graph_add_edge(struct Graph* G, uint8_t u, uint8_t v, uint16_t w) {
  int k = 0;
  while (G->E[u][k] != GRAPH_UNNEIGHBOR)
    ++k;
  assert(k < 4);
  G->E[u][k] = v;
  G->W[u][v] = w;
}


struct QueueElement {
  uint8_t start[2];
  uint8_t prev[2];
  uint8_t cur[2];
};

struct Queue {
  struct QueueElement Q[QUEUE_CAPACITY];
  int begin;
  int end;
};

static void queue_init(struct Queue* Q) {
  Q->begin = Q->end = 0;
}

static void queue_requeue(struct Queue* Q) {
  int siz = Q->end - Q->begin;
  assert(siz < QUEUE_CAPACITY);
  for (int i = 0; i < siz; ++i) {
    Q->Q[i] = Q->Q[Q->begin+i];
  }
  Q->begin = 0;
  Q->end = siz;
}

static void queue_enequeue(struct Queue* Q, struct QueueElement e) {
  if (Q->end == QUEUE_CAPACITY)
    queue_requeue(Q);
  Q->Q[Q->end++] = e;
}

static struct QueueElement queue_dequeue(struct Queue* Q) {
  assert(Q->begin < Q->end);
  return Q->Q[Q->begin++];
}


static bool is_intersection(const struct Map* map, uint8_t i, uint8_t j) {
  if (i > 0 && j > 0 && i < map->num_rows && j < map->num_cols &&
      map->A[i][j] == PATH) {
    int c = 0;
    if (map->A[i-1][j] != FOREST)
      ++c;
    if (map->A[i+1][j] != FOREST)
      ++c;
    if (map->A[i][j-1] != FOREST)
      ++c;
    if (map->A[i][j+1] != FOREST)
      ++c;
    return c > 2;
  }
  return false;
}

static void step_east(uint8_t* cur, uint8_t* prev, int* d) {
  prev[0] = cur[0];
  prev[1] = cur[1];
  ++cur[1];
  ++*d;
}

static void step_north(uint8_t* cur, uint8_t* prev, int* d) {
  prev[0] = cur[0];
  prev[1] = cur[1];
  --cur[0];
  ++*d;
}

static void step_west(uint8_t* cur, uint8_t* prev, int* d) {
  prev[0] = cur[0];
  prev[1] = cur[1];
  --cur[1];
  ++*d;
}

static void step_south(uint8_t* cur, uint8_t* prev, int* d) {
  prev[0] = cur[0];
  prev[1] = cur[1];
  ++cur[0];
  ++*d;
}

static void construct_graph(struct Graph* G, const struct Map* map) {
  graph_init(G);
  graph_add_node(G, map->S[0], map->S[1]);
  graph_add_node(G, map->E[0], map->E[1]);

  struct Queue Q;
  queue_init(&Q);
  struct QueueElement e = {
    .start = { map->S[0], map->S[1] },
    .prev = { map->S[0], map->S[1] },
    .cur = { map->S[0]+1, map->S[1] },
  };
  queue_enequeue(&Q, e);

  while (Q.begin < Q.end) {
    e = queue_dequeue(&Q);
    int d = 1;
    while (true) {
      if (map->A[e.cur[0]][e.cur[1]] == SLOPE_EAST) {
        step_east(e.cur, e.prev, &d);
      }
      else if (map->A[e.cur[0]][e.cur[1]] == SLOPE_NORTH) {
        step_north(e.cur, e.prev, &d);
      }
      else if (map->A[e.cur[0]][e.cur[1]] == SLOPE_WEST) {
        step_west(e.cur, e.prev, &d);
      }
      else if (map->A[e.cur[0]][e.cur[1]] == SLOPE_SOUTH) {
        step_south(e.cur, e.prev, &d);
      }
      else if (is_intersection(map, e.cur[0], e.cur[1]) ||
               (e.cur[0] == map->E[0] && e.cur[1] == map->E[1])) {
        bool visited = graph_contains(G, e.cur[0], e.cur[1]);
        if (!visited)
          graph_add_node(G, e.cur[0], e.cur[1]);
        assert(graph_contains(G, e.cur[0], e.cur[1]));
        assert(graph_contains(G, e.start[0], e.start[1]));
        uint8_t u = hashmap_find(&G->ij_to_v, (e.start[0] << 8) | e.start[1]);
        uint8_t v = hashmap_find(&G->ij_to_v, (e.cur[0] << 8) | e.cur[1]);
        graph_add_edge(G, u, v, d);

        if (!visited && (e.cur[0] != map->E[0] || e.cur[1] != map->E[1])) {
            uint8_t i = e.cur[0];
            uint8_t j = e.cur[1];
            e.prev[0] = e.start[0] = i;
            e.prev[1] = e.start[1] = j;
            if (map->A[i][j+1] == SLOPE_EAST) {
              e.cur[0] = i;
              e.cur[1] = j+1;
              queue_enequeue(&Q, e);
            }
            if (map->A[i-1][j] == SLOPE_NORTH) {
              e.cur[0] = i-1;
              e.cur[1] = j;
              queue_enequeue(&Q, e);
            }
            if (map->A[i][j-1] == SLOPE_WEST) {
              e.cur[0] = i;
              e.cur[1] = j-1;
              queue_enequeue(&Q, e);
            }
            if (map->A[i+1][j] == SLOPE_SOUTH) {
              e.cur[0] = i+1;
              e.cur[1] = j;
              queue_enequeue(&Q, e);
            }
        }
        break;
      }
      else if (map->A[e.cur[0]][e.cur[1]+1] != FOREST &&
               (e.cur[0] != e.prev[0] || e.cur[1]+1 != e.prev[1])) {
        step_east(e.cur, e.prev, &d);
      }
      else if (map->A[e.cur[0]-1][e.cur[1]] != FOREST &&
               (e.cur[0]-1 != e.prev[0] || e.cur[1] != e.prev[1])) {
        step_north(e.cur, e.prev, &d);
      }
      else if (map->A[e.cur[0]][e.cur[1]-1] != FOREST &&
               (e.cur[0] != e.prev[0] || e.cur[1]-1 != e.prev[1])) {
        step_west(e.cur, e.prev, &d);
      }
      else if (map->A[e.cur[0]+1][e.cur[1]] != FOREST &&
               (e.cur[0]+1 != e.prev[0] || e.cur[1] != e.prev[1])) {
        step_south(e.cur, e.prev, &d);
      }
      else {
        printf("%u %u\n", e.cur[0], e.cur[1]);
        assert(false);
      }
    }
  }
}

static void print_map(FILE* f, const struct Map* map) {
  for (int i = 0; i < map->num_rows; ++i) {
    for (int j = 0; j < map->num_cols; ++j) {
      if (i == map->S[0] && j == map->S[1]) {
        fprintf(f, "S");
      }
      else if (i == map->E[0] && j == map->E[1]) {
        fprintf(f, "E");
      }
      else {
        switch(map->A[i][j]) {
        case FOREST:
          fprintf(f, "#");
          break;
        case PATH:
          fprintf(f, ".");
          break;
        case SLOPE_EAST:
          fprintf(f, ">");
          break;
        case SLOPE_NORTH:
          fprintf(f, "^");
          break;
        case SLOPE_WEST:
          fprintf(f, "<");
          break;
        case SLOPE_SOUTH:
          fprintf(f, "v");
          break;
        default:
          assert(false);
          break;
        }
      }
    }
    fprintf(f, "\n");
  }
}

void read_data(char* filename, struct Map* map) {
  static char line[MAX_LINE_LENGTH];
  FILE* f = fopen(filename,"r");
  map->num_rows = 0;
  memset(map->A, 0, sizeof(map->A));
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    int len = strlen(line);
    line[--len] = '\0';
    map->num_cols = len;
    for (int j = 0; j < len; ++j) {
      switch(line[j]) {
      case '.':
        if (map->num_rows == 0) {
          map->S[0] = 0;
          map->S[1] = j;
        }
        else {
          map->E[0] = map->num_rows;
          map->E[1] = j;
        }
        map->A[map->num_rows][j] = PATH;
        break;
      case '>':
        map->A[map->num_rows][j] = SLOPE_EAST;        
        break;
      case '^':
        map->A[map->num_rows][j] = SLOPE_NORTH;
        break;
      case '<':
        map->A[map->num_rows][j] = SLOPE_WEST;
        break;
      case 'v':
        map->A[map->num_rows][j] = SLOPE_SOUTH;
        break;
      default:
        break;
      }
    }
    ++map->num_rows;      
  }
  fclose(f);
}

uint16_t longest_path_backtrack(const struct Graph* G, uint8_t u, uint8_t E,
                                bool* visited, uint16_t acc) {
  assert(!visited[u]);
  if (u == E)
    return acc;
  visited[u] = true;
  uint16_t L = 0;
  for (int i = 0; i < 4; ++i) {
    uint8_t v = G->E[u][i];
    if (v == GRAPH_UNNEIGHBOR)
      break;
    if (!visited[v]) {
      uint16_t d = longest_path_backtrack(G, v, E, visited, acc + G->W[u][v]);
      if (d > L)
        L = d;
    }
  }
  visited[u] = false;
  return L;
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
  struct timespec start, end;
  struct Map map;
  if (argc != 2) {
    fprintf(stderr, "usage: %s <input.txt>\n", argv[0]);
    return EXIT_FAILURE;
  }

  timespec_get(&start, TIME_UTC);
  read_data(argv[1], &map);
  timespec_get(&end, TIME_UTC);
  printf("data read in %s\n", format_time(time_diff(&start, &end))); 

  // print_map(stdout, &map);

  timespec_get(&start, TIME_UTC);
  struct Graph G;
  construct_graph(&G, &map);

  bool visited[GRAPH_MAX_NODES] = { 0 };
  printf("%" PRIu16 "\n", longest_path_backtrack(&G, 0, 1, visited, 0));
  timespec_get(&end, TIME_UTC);
  printf("solved in %s\n", format_time(time_diff(&start, &end))); 

  return EXIT_SUCCESS;
}
