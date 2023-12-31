#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <inttypes.h>
#include <assert.h>
#include <string.h>
#include <stdbool.h>

#define HASHMAP_CAPACITY_BITS 11
#define HASHMAP_CAPACITY (1<<HASHMAP_CAPACITY_BITS)
#define MAX_VERTICES HASHMAP_CAPACITY
#define MAX_EDGES 1024
#define MAX_LINE_LENGTH 128
#define RANDOM_SEED 1238

struct HashMap {
  char keys[HASHMAP_CAPACITY][3];
  int values[HASHMAP_CAPACITY];
  int size;
};

static void hashmap_init(struct HashMap* H) {
  H->size = 0;
  memset(H->keys, 0, sizeof(H->keys));
}

static uint32_t hash(const char* key) {
  uint64_t h = 13887759482676395459lu;
  for (int i = 0; i < 3; ++i)
    h *= key[i];
  return h >> 32;
}

static void hashmap_insert(struct HashMap* H, const char* key, int val) {
  int h = ((hash(key)) >> (32-HASHMAP_CAPACITY_BITS));
  while (H->keys[h][0] != 0) {
    if (memcmp(H->keys[h], key, 3) == 0)
      return;
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  memcpy(H->keys[h], key, 3);
  H->values[h] = val;
  ++H->size;
}

static int hashmap_find(const struct HashMap* H, const char* key) {
  int h = ((hash(key)) >> (32-HASHMAP_CAPACITY_BITS));
  while (H->keys[h][0] != 0) {
    if (memcmp(H->keys[h], key, 3) == 0)
      return H->values[h];
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  assert(false);
  return -1;
}

struct Graph {
  int num_vertices;
  int V[MAX_VERTICES];
  int Vm[MAX_VERTICES];
  int E[MAX_VERTICES][MAX_EDGES];
  int num_edges[MAX_VERTICES];
};

static void graph_init(struct Graph* G) {
  G->num_vertices = 0;
}

static void graph_add_vertex(struct Graph* G, int u) {
  G->V[G->num_vertices++] = u;
  G->Vm[u] = 1;
  G->num_edges[u] = 0;
}

static void graph_add_edge(struct Graph* G, int u, int v) {
  assert(G->num_edges[u] < MAX_EDGES);
  G->E[u][G->num_edges[u]++] = v;
}

static void graph_copy(struct Graph* dst, const struct Graph* src) {
  dst->num_vertices = src->num_vertices;
  for (int u = 0; u < src->num_vertices; ++u) {
    dst->V[u] = src->V[u];
    dst->Vm[u] = src->Vm[u];
    dst->num_edges[u] = src->num_edges[u];
    for (int i = 0; i < src->num_edges[u]; ++i)
      dst->E[u][i] = src->E[u][i];
  }
}

static void print_graph(const struct Graph* G) {
  for (int u = 0; u < G->num_vertices; ++u) {
    printf("%d:%d ", G->V[u], G->Vm[u]);
  }
  printf("\n");
  for (int i = 0; i < G->num_vertices; ++i) {
    int u = G->V[i];
    printf("%d:", u);
    for (int j = 0; j < G->num_edges[u]; ++j)
      printf(" %d", G->E[u][j]);
    printf("\n");
  }

}

void graph_contract(struct Graph* G, int u, int v) {
  G->Vm[u] += G->Vm[v];
  G->Vm[v] = 0;
  int j = 0;
  for (int i = 0; i < G->num_edges[u]; ++i) {
    if (G->E[u][i] != v) {
      G->E[u][j++] = G->E[u][i];
    }
  }
  G->num_edges[u] = j;
  for (int i = 0; i < G->num_edges[v]; ++i) {
    int l = G->E[v][i];
    if (l != u) {
      graph_add_edge(G, u, l);
      for (int j = 0; j < G->num_edges[l]; ++j) {
        if (G->E[l][j] == v)
          G->E[l][j] = u;
      }
    }
  }
  j = 0;
  for (int i = 0; i < G->num_vertices; ++i) {
    if (G->V[i] != v)
      G->V[j++] = G->V[i];
  }
  --G->num_vertices;
}

uint64_t solve(const struct Graph* G) {
  static struct Graph Gc;
  srand(RANDOM_SEED);
  int cut_size = 0;
  int u, v;
  while (cut_size != 3) {
    graph_copy(&Gc, G);

    while (Gc.num_vertices > 2) {
      u = Gc.V[rand() % Gc.num_vertices];
      v = Gc.E[u][rand() % Gc.num_edges[u]];
      graph_contract(&Gc, u, v);

    }
    u = Gc.V[0];
    v = Gc.V[1];
    cut_size = Gc.num_edges[u];
  }
  return Gc.Vm[u] * Gc.Vm[v];
}

static void read_data(char* filename, struct Graph* G) {
  FILE* f = fopen(filename, "r");

  static char line[MAX_LINE_LENGTH];
  struct HashMap V;
  hashmap_init(&V);
  assert(V.size == 0);
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    line[strlen(line)-1] = 0;
    line[3] = 0;
    hashmap_insert(&V, line, V.size);
    char* p = strtok(line + 4, " ");
    while (p) {
      hashmap_insert(&V, p, V.size);
      p = strtok(NULL, " ");
    }
  }
  fclose(f);

  graph_init(G);
  for (int i = 0; i < V.size; ++i) {
    graph_add_vertex(G, i);
  }

  f = fopen(filename, "r");
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    line[strlen(line)-1] = 0;
    line[3] = 0;
    int u = hashmap_find(&V, line);
    char* p = strtok(line + 4, " ");
    while (p) {
      int v = hashmap_find(&V, p);
      graph_add_edge(G, u, v);
      graph_add_edge(G, v, u);
      p = strtok(NULL, " ");
    }
  }
  fclose(f);
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
  timespec_get(&start, TIME_UTC);

  if (argc != 2) {
    fprintf(stderr, "usage: %s <input.txt>\n", argv[0]);
    return EXIT_FAILURE;
  }

  static struct Graph G;

  read_data(argv[1], &G);
  timespec_get(&end, TIME_UTC);
  printf("data read at %s\n", format_time(time_diff(&start, &end))); 

  // print_graph(&G);


  printf("%" PRIu64 "\n", solve(&G));

  timespec_get(&end, TIME_UTC);
  printf("solved in %s\n", format_time(time_diff(&start, &end)));
  return EXIT_SUCCESS;
}
