#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <string.h>
#include <assert.h>
#include <stdbool.h>
#include <time.h>

#define MAX_ROWS 131
#define MAX_COLS 131
#define MAX_LINE_LENGTH 256
#define EMPTY 0
#define ROCK 1
#define EMPTY_CHAR '.'
#define ROCK_CHAR '#'
#define START_CHAR 'S'
#define HASH_SET_CAPACITY_BITS 17
#define HASH_SET_CAPACITY (1 << HASH_SET_CAPACITY_BITS)
#define TARGET_STEPS 26501365

struct HashSet {
  int16_t keys[HASH_SET_CAPACITY][2];
  bool occupied[HASH_SET_CAPACITY];
  int size;
};

struct Map {
  uint8_t A[MAX_ROWS][MAX_COLS];
  int num_rows;
  int num_cols;
  uint8_t start_row;
  uint8_t start_col;
};

uint32_t hash(uint32_t x) {
  return (15508228807837039897lu * x) >> (64-HASH_SET_CAPACITY_BITS);
}

static void hash_set_init(struct HashSet* H) {
  H->size = 0;
  memset(H->occupied, 0, sizeof(bool)*HASH_SET_CAPACITY);
}

static void hash_set_insert(struct HashSet* H, int16_t i, int16_t j) {
  assert(H->size < HASH_SET_CAPACITY);

  uint32_t h = hash((i << 16) | j);
  while (H->occupied[h]) {
    if (H->keys[h][0] == i && H->keys[h][1] == j)
      return;
    ++h;
    if (h == HASH_SET_CAPACITY)
      h = 0;
  }
  H->occupied[h] = true;
  H->keys[h][0] = i;
  H->keys[h][1] = j;
  ++H->size;
}

static void read_data(const char* filename, struct Map* map) {
  static char buffer[MAX_LINE_LENGTH];
  FILE* f = fopen(filename, "r");
  int len;
  map->num_rows = 0;
  map->num_cols = 0;
  while (fgets(buffer, MAX_LINE_LENGTH, f)) {
    len = strlen(buffer);
    buffer[--len] = '\0';
    if (map->num_cols == 0)
      map->num_cols = len;
    else
      assert(map->num_cols == len);
    for (int c = 0; c < len; ++c) {
      switch(buffer[c]) {
      case EMPTY_CHAR:
        map->A[map->num_rows][c] = EMPTY;
        break;
      case ROCK_CHAR:
        map->A[map->num_rows][c] = ROCK;
        break;
      case START_CHAR:
        map->A[map->num_rows][c] = EMPTY;
        map->start_row = map->num_rows;
        map->start_col = c;
        break;
      default:
        assert(false && "invalid character");
        break;
      }
    }
    ++map->num_rows;
  }
  fclose(f);
}

void print_map(FILE* out, const struct Map* map) {
  for (int i = 0; i < map->num_rows; ++i) {
    for (int j = 0; j < map->num_cols; ++j) {
      fprintf(out, "%c",
              i == map->start_row && j == map->start_col ? START_CHAR :
              map->A[i][j] == ROCK ? ROCK_CHAR :
              map->A[i][j] == EMPTY ? EMPTY_CHAR :
              '?');
    }
    fprintf(out, "\n");
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
    sprintf(buffer, "%.3f μs", secs*1e6);
  }
  else if (secs >= 1e-9) {
    sprintf(buffer, u8"%.3f ns", secs*1e9);
  }
  else {
    sprintf(buffer, "0");
  }
  return buffer;
}

static int mod(int a, int b) {
  return ((a % b) + b) % b;
}

static void check_and_insert(const struct Map* map, struct HashSet* H, 
                             int16_t i, int16_t j) {
  if (map->A[mod(i,map->num_rows)][mod(j,map->num_cols)] == EMPTY) {
    hash_set_insert(H, i, j);
  }
}

static void simulate(const struct Map* map, int* target_steps, int num_targets,
                     int* res) {
  struct HashSet hs1;
  struct HashSet hs2;
  struct HashSet* hp1 = &hs1;
  struct HashSet* hp2 = &hs2;
  struct HashSet* hpt;
  hash_set_init(hp1);
  hash_set_insert(hp1, map->start_row, map->start_col);
  int* current_target = target_steps;
  int s = 0;
  while (current_target < target_steps + num_targets) {
    ++s;
    hash_set_init(hp2);    
    for (int k = 0; k < HASH_SET_CAPACITY; ++k) {
      if (hp1->occupied[k]) {
        int16_t i0 = hp1->keys[k][0];
        int16_t j0 = hp1->keys[k][1];
        check_and_insert(map, hp2, i0-1, j0);
        check_and_insert(map, hp2, i0+1, j0);
        check_and_insert(map, hp2, i0, j0-1);
        check_and_insert(map, hp2, i0, j0+1);
      }
    }
    hpt = hp1;
    hp1 = hp2;
    hp2 = hpt;
    if (s == *current_target) {
      *res++ = hp1->size;
      ++current_target;
    }
  }
}

int64_t solve(const struct Map* map) {
  int targets[3];
  int res[3];
  for (int i = 0; i < 3; ++i)
    targets[i] = (TARGET_STEPS % map->num_rows) + i*map->num_rows;
  simulate(map, targets, 3, res);

  int x1 = targets[0];
  int x2 = targets[1];
  int x3 = targets[2];
  int y1 = res[0];
  int y2 = res[1];  
  int y3 = res[2];

  int Z = (x1-x2)*(x1-x3)*(x2-x3);
  int c = x2*x3*(x2-x3)*y1-x1*x3*(x1-x3)*y2+x1*x2*(x1-x2)*y3;
  int b = x3*x3*(y1-y2)+x1*x1*(y2-y3)+x2*x2*(y3-y1);
  int a = x3*(y2-y1)+x2*(y1-y3)+x1*(y3-y2);
  __int128 x = TARGET_STEPS; 
  int64_t y = (a*x*x + b*x + c)/Z;
  return y;
}

int main(int argc, char* argv[]) {
  if (argc != 2) {
    fprintf(stderr, "usage: %s <input.txt>\n", argv[0]);
    return EXIT_FAILURE;
  }
  struct timespec start, end;
  struct Map map;
  timespec_get(&start, TIME_UTC);
  read_data(argv[1], &map);
  timespec_get(&end, TIME_UTC);
  printf("data read in %s\n", format_time(time_diff(&start, &end))); 
  timespec_get(&start, TIME_UTC);
  printf("%" PRId64 "\n", solve(&map));
  timespec_get(&end, TIME_UTC);
  printf("solved in %s\n", format_time(time_diff(&start, &end))); 
  return EXIT_SUCCESS;
}
