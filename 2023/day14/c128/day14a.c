#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <stdbool.h>
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
#define FILENAME "input.txt,s"

static uint8_t A[MAX_ROWS][MAX_COLS];
static uint8_t R[MAX_ROCKS][2];
static uint8_t num_rows = 0;
static uint8_t num_cols = 0;
static uint16_t num_rocks = 0;

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
        fprintf(stderr, "invalid  character `%s' encountered\n",
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

uint32_t north_load() {
  uint32_t S = 0;
  uint16_t r;
  for (r = 0; r < num_rocks; ++r)
    S += num_rows - R[r][0];
  return S;
}

int main(void) {
  fast();
  read_data(FILENAME);
  printf("data read at: %ld s\n", clock()/CLOCKS_PER_SEC);

  tilt_north();

  printf("%" PRIu32 "\n", north_load());

  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  slow();
  return EXIT_SUCCESS;
}
