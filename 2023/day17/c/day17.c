#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <inttypes.h>
#include <time.h>
#include <stdbool.h>

#define MAX_ROWS 141
#define MAX_COLS 141
#define MAX_LINE_LENGTH 256
#define MAX_NODES 65536
#define MAX_NEIGHBORS 14
#define START 0xfffe
#define END 0xffff
#define HORIZONTAL 0
#define VERTICAL 1
#define MIN_HEAP_CAPACITY 8192
#define INFINITY 65535

static uint8_t A[MAX_ROWS][MAX_COLS];
static uint8_t num_rows;
static uint8_t num_cols;
static uint16_t neighbors[MAX_NODES][MAX_NEIGHBORS];
static uint8_t num_neighbors[MAX_NODES];
static uint8_t min_distance;
static uint8_t max_distance;

struct HeapElement {
  uint16_t score;
  uint16_t node;
};

struct MinHeap {
  uint16_t size;
  struct HeapElement heap[MIN_HEAP_CAPACITY];
};

void minheap_init(struct MinHeap* H) {
  H->size = 0;
}

void minheap_push(struct MinHeap* H, struct HeapElement e) {
  uint16_t i = H->size;
  uint16_t p;
  H->heap[i] = e;
  ++H->size;
  p = (i-1)/2;
  while (i > 0 && H->heap[p].score > H->heap[i].score) {
    e = H->heap[p];
    H->heap[p] = H->heap[i];
    H->heap[i] = e;
    i = p;
    p = (i-1)/2;
  }
}

void minheap_heapify(struct MinHeap* H, uint16_t root) {
  uint16_t smallest = root, left = 2*root+1, right = 2*root+2;
  struct HeapElement e;
  if (left < H->size && H->heap[left].score < H->heap[root].score)
    smallest = left;
  if (right < H->size && H->heap[right].score < H->heap[smallest].score)
    smallest = right;
  if (smallest != root) {
    e = H->heap[root];
    H->heap[root] = H->heap[smallest];
    H->heap[smallest] = e;
    minheap_heapify(H, smallest);
  }
}

struct HeapElement minheap_pop(struct MinHeap* H) {
  struct HeapElement e;
  --H->size;
  e = H->heap[0];
  H->heap[0] = H->heap[H->size];
  minheap_heapify(H,0);
  return e;
}

static void read_data(char* filename) {
  FILE* f;
  char c;
  static char line[MAX_LINE_LENGTH];
  f = fopen(filename,"r");
  num_rows = 0;
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    num_cols = 0;
    while ((c = line[num_cols]) != '\n') {
      A[num_rows][num_cols++] = c - '0';
    }
    ++num_rows;
  }
  fclose(f);
}

static uint16_t compress_node(uint8_t i, uint8_t j, uint8_t hv) {
  return (MAX_COLS*((uint16_t)i)+j) | (hv ? (1 << 15) : 0);
}

static void get_neighbors(uint16_t u, uint16_t* neighbors, uint8_t* n) {
  uint8_t i0, j0, hv, d;
  *n = 0;
  i0 = (u&0x7fff) / MAX_COLS;
  j0 = (u&0x7fff) % MAX_COLS;
  hv = (u >> 15) & 1;
  if (hv == HORIZONTAL) {
    for (d = min_distance; d <= max_distance; ++d) {
      if (d <= j0) 
        neighbors[(*n)++] = compress_node(i0,j0-d,VERTICAL);
      if (j0+d < num_cols) 
        neighbors[(*n)++] = compress_node(i0,j0+d,VERTICAL);
    }
  }
  else {
    for (d = min_distance; d <= max_distance; ++d) {
      if (d <= i0)
        neighbors[(*n)++] = compress_node(i0-d,j0,HORIZONTAL);
      if (i0+d < num_rows)
        neighbors[(*n)++] = compress_node(i0+d,j0,HORIZONTAL);
    }
  }
}

static uint8_t get_weight(uint16_t u, uint16_t v) {
  uint8_t w = 0, i, j, i0, j0, i1, j1;
  i0 = (u&0x7fff) / MAX_COLS;
  j0 = (u&0x7fff) % MAX_COLS;
  i1 = (v&0x7fff) / MAX_COLS;
  j1 = (v&0x7fff) % MAX_COLS;
  if ((u == START && i1 == 0 && j1 == 0) ||
      (v == END && i0 == num_rows - 1 && j0 == num_cols - 1))
    return 0;
  if (i0 < i1) {
    for (i = i0+1; i <= i1; ++i)
      w += A[i][j0];
  }
  else if (i0 > i1) {
    for (i = i1; i < i0; ++i)
      w += A[i][j0];
  }
  else if (j0 < j1) {
    for (j = j0+1; j <= j1; ++j)
      w += A[i0][j];
  }
  else if (j0 > j1) {
    for (j = j1; j < j0; ++j)
      w += A[i0][j];
  }
  return w;
}

static void preprocess() {
  uint8_t i0, j0, hv;
  uint16_t u;
  u = compress_node(0,0,HORIZONTAL);
  neighbors[START][0] = u;
  u = compress_node(0,0,VERTICAL);
  neighbors[START][1] = u;
  num_neighbors[START] = 2;
  for (i0 = 0; i0 < num_rows; ++i0) {
    for (j0 = 0; j0 < num_cols; ++j0) {
      for (hv = HORIZONTAL; hv <= VERTICAL; ++hv) {
        u = compress_node(i0,j0,hv);
        get_neighbors(u, neighbors[u], &num_neighbors[u]);
      }
    }
  }
  u = compress_node(num_rows-1,num_cols-1,HORIZONTAL);
  neighbors[u][num_neighbors[u]++] = END;
  u = compress_node(num_rows-1,num_cols-1,VERTICAL);
  neighbors[u][num_neighbors[u]++] = END;
}

static uint16_t heuristic(uint16_t u) {
  uint8_t i, j;
  i = (u&0x7fff) / MAX_COLS;
  j = (u&0x7fff) % MAX_COLS;
  return num_rows + num_cols - i  - j;
}

static uint16_t astar(void) {
  static struct MinHeap open_set;
  struct HeapElement e;
  static uint16_t g_score[MAX_NODES];
  static uint16_t f_score[MAX_NODES];
  uint16_t u, current, neighbor;
  uint8_t n;
  uint16_t tentative_g_score;

  minheap_init(&open_set);
  e.score = 0;
  e.node = START;
  minheap_push(&open_set, e);

  u = 0;
  do {
    g_score[u] = f_score[u] = INFINITY;
    ++u;
  }
  while (u > 0);
  g_score[START] = 0;
  f_score[START] = heuristic(START);

  while (open_set.size > 0) {
    e = minheap_pop(&open_set);
    current = e.node;
    if (current == END) {
      return g_score[current];
    }
    for (n = 0; n < num_neighbors[current]; ++n) {
      neighbor = neighbors[current][n];
      tentative_g_score = g_score[current] + get_weight(current,neighbor);
      if (tentative_g_score < g_score[neighbor]) {
        g_score[neighbor] = tentative_g_score;
        e.score = tentative_g_score + heuristic(neighbor);
        e.node = neighbor;
        f_score[neighbor] = e.score;
        minheap_push(&open_set, e);
      }
    }
  }
  assert(false && "failed");
  return 0;
}

int main(int argc, char* argv[]) {
  struct timespec start_time, end_time;
  timespec_get(&start_time, TIME_UTC);
  if (argc != 4) {
    fprintf(stderr, 
            "usage: %s <input.txt> <min> <max>\n"
            "for part 1, min = 1 and max = 3\n"
            "for part 2, min = 4 and max = 10\n",
            argv[0]);
    return EXIT_FAILURE;
  }

  read_data(argv[1]);
  sscanf(argv[2], "%" SCNu8, &min_distance);
  sscanf(argv[3], "%" SCNu8, &max_distance);

  preprocess();

  printf("%" PRIu16 "\n",
         astar());

  timespec_get(&end_time, TIME_UTC);
  
  printf("time elapsed: %f s\n",
         end_time.tv_sec + end_time.tv_nsec/1e9 -
         start_time.tv_sec - start_time.tv_nsec/1e9);

  return EXIT_SUCCESS;
}
