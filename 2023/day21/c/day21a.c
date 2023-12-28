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
#define HASH_SET_CAPACITY_BITS 12
#define HASH_SET_CAPACITY (1 << HASH_SET_CAPACITY_BITS)

struct HashSet {
  uint16_t keys[HASH_SET_CAPACITY];
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

static void hash_set_insert(struct HashSet* H, uint16_t key) {
  assert(H->size < HASH_SET_CAPACITY);
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

static void check_and_insert(const struct Map* map, struct HashSet* H, 
                             uint8_t i, uint8_t j) {
  if (i < map->num_rows &&
      j < map->num_cols &&
      map->A[i][j] == EMPTY)
    hash_set_insert(H, (i << 8) | j);
}

static int solve(const struct Map* map, int target_steps) {
  struct HashSet hs1;
  struct HashSet hs2;
  struct HashSet* hp1 = &hs1;
  struct HashSet* hp2 = &hs2;
  struct HashSet* hpt;
  hash_set_init(hp1);
  hash_set_insert(hp1, (map->start_row << 8) | map->start_col);
  for (int s = 1; s <= target_steps; ++s) {
    hash_set_init(hp2);    
    for (int k = 0; k < HASH_SET_CAPACITY; ++k) {
      if (hp1->occupied[k]) {
        uint16_t ij = hp1->keys[k];
        uint8_t i0 = ij >> 8;
        uint8_t j0 = ij & 0xff;
        check_and_insert(map, hp2, i0-1, j0);
        check_and_insert(map, hp2, i0+1, j0);
        check_and_insert(map, hp2, i0, j0-1);
        check_and_insert(map, hp2, i0, j0+1);
      }
    }
    hpt = hp1;
    hp1 = hp2;
    hp2 = hpt;
  }
  return hp1->size;
}

int main(int argc, char* argv[]) {
  if (argc != 3) {
    fprintf(stderr, "usage: %s <input.txt> <target_steps>\n", argv[0]);
    return EXIT_FAILURE;
  }
  struct timespec start, end;
  struct Map map;
  timespec_get(&start, TIME_UTC);
  read_data(argv[1], &map);
  timespec_get(&end, TIME_UTC);
  printf("data read in %s\n", format_time(time_diff(&start, &end))); 
  timespec_get(&start, TIME_UTC);
  printf("%d\n", solve(&map, atoi(argv[2])));
  timespec_get(&end, TIME_UTC);
  printf("solved in %s\n", format_time(time_diff(&start, &end))); 
  return EXIT_SUCCESS;
}
