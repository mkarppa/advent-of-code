#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <time.h>
#include <inttypes.h>
#include <c128.h>

#define EMPTY 0
#define ROUND_ROCK 1
#define CUBE_ROCK 2
#define EMPTY_CHAR '.'
#define ROUND_ROCK_CHAR 79
#define CUBE_ROCK_CHAR '#'
#define MAX_ROWS 100
#define MAX_COLS 100
#define MAX_ROCKS 2031
#define MAX_LINE_LENGTH 256
#define MAX_LOADS 300
#define FILENAME "input.txt,s"

static uint8_t A[MAX_ROWS][MAX_COLS];
static uint8_t R[MAX_ROCKS][2];
static uint8_t num_rows = 0;
static uint8_t num_cols = 0;
static uint16_t num_rocks = 0;
static uint32_t loads[MAX_LOADS];

void print_map() {
  uint8_t i, j;
  for (i = 0; i < num_rows; ++i) {
    for (j = 0; j < num_cols; ++j) {
      printf("%c", 
             A[i][j] == EMPTY ? '.' :
             A[i][j] == CUBE_ROCK ? '#' :
             A[i][j] == ROUND_ROCK ? 'O' :
             '?');
    }
    printf("\n");
  }
}

void read_data(char* filename) {
  static char line[MAX_LINE_LENGTH];
  FILE* f = fopen(filename, "r");

  num_rows = 0;
  num_rocks = 0;
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    for (num_cols = 0; line[num_cols] != '\n'; ++num_cols) {
      switch(line[num_cols]) {
      case EMPTY_CHAR:
        A[num_rows][num_cols] = EMPTY;
        break;
      case CUBE_ROCK_CHAR:
        A[num_rows][num_cols] = CUBE_ROCK;
        break;
      case ROUND_ROCK_CHAR:
        A[num_rows][num_cols] = ROUND_ROCK;
        R[num_rocks][0] = num_rows;
        R[num_rocks][1] = num_cols;
        ++num_rocks;
        break;
      default:
        fprintf(stderr, "invalid character `%c' encountered\n",
                line[num_cols]);
        assert(false);
        break;
      }
    }
    
    ++num_rows;
  }
  fclose(f);
}

void clear_round() {
  uint16_t r;
  for (r = 0; r < num_rocks; ++r) {
    A[R[r][0]][R[r][1]] = EMPTY;    
  }
}

void tilt_north() {
  uint16_t r;
  uint8_t i, j;
  clear_round();
  for (r = 0; r < num_rocks; ++r) {
    i = R[r][0];
    j = R[r][1];
    while (A[i][j] == ROUND_ROCK)
      ++i;
    while (i > 0 && A[i-1][j] == EMPTY)
      --i;
    A[i][j] = ROUND_ROCK;
    R[r][0] = i;
    R[r][1] = j;
  }
}

void tilt_west() {
  uint16_t r;
  uint8_t i, j;
  clear_round();
  for (r = 0; r < num_rocks; ++r) {
    i = R[r][0];
    j = R[r][1];
    while (A[i][j] == ROUND_ROCK)
      ++j;
    while (j > 0 && A[i][j-1] == EMPTY)
      --j;
    A[i][j] = ROUND_ROCK;
    R[r][0] = i;
    R[r][1] = j;
  }
}

void tilt_south() {
  uint16_t r;
  uint8_t i, j;
  clear_round();
  for (r = 0; r < num_rocks; ++r) {
    i = R[r][0];
    j = R[r][1];
    while (A[i][j] == ROUND_ROCK)
      --i;
    while (i < num_rows-1 && A[i+1][j] == EMPTY)
      ++i;
    A[i][j] = ROUND_ROCK;
    R[r][0] = i;
    R[r][1] = j;
  }
}

void tilt_east() {
  uint16_t r;
  uint8_t i, j;
  clear_round();
  for (r = 0; r < num_rocks; ++r) {
    i = R[r][0];
    j = R[r][1];
    while (A[i][j] == ROUND_ROCK)
      --j;
    while (j < num_cols-1 && A[i][j+1] == EMPTY)
      ++j;
    A[i][j] = ROUND_ROCK;
    R[r][0] = i;
    R[r][1] = j;
  }
}


uint32_t north_load() {
  uint32_t S = 0;
  uint16_t r;
  for (r = 0; r < num_rocks; ++r)
    S += num_rows - R[r][0];
  return S;
}

void cycle() {
  tilt_north();
  tilt_west();
  tilt_south();
  tilt_east();
}

uint8_t find_cycle_length() {
  uint16_t load_idx = 0;
  uint16_t start_idx = 0;
  uint16_t i, j;
  uint8_t cycle_length;
  bool found;
  loads[load_idx++] = north_load();
  for (cycle_length = 1; cycle_length < MAX_LOADS; ++cycle_length) {
    for (start_idx = 0; start_idx < 2*cycle_length; ++start_idx) {
      found = true;
      for (i = start_idx; i < start_idx + cycle_length; ++i) {
        for (j = i + cycle_length; j < start_idx + 3*cycle_length;
             j += cycle_length) {
          while (j >= load_idx) {
            assert(load_idx < MAX_LOADS);
            cycle();
            loads[load_idx++] = north_load();
          }
          if (loads[i] != loads[j]) {
            found = false;
            break;
          }
        }
        if (!found)
          break;
      }
      if (found)
        return cycle_length;
    }
  }
  return 0;
}

int main(void) {
  uint32_t cycle_length;
  fast();
  read_data(FILENAME); 
  printf("data read at: %ld s\n", clock()/CLOCKS_PER_SEC);
  cycle_length = find_cycle_length();
  printf("%" PRIu32 "\n", 
         loads[1000000000 % cycle_length + 2*cycle_length]);
  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  slow();
  return EXIT_SUCCESS;
}
