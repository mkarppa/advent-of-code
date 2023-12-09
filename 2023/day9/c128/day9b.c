#include <c128.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <inttypes.h>
#include <string.h>
#include <time.h>

#define MAX_ROWS 200
#define MAX_COLS 21
#define MAX_INTERPOLATION_DEPTH 19
#define FILENAME "input.txt,s"
#define BUFFER_LENGTH 256

static int32_t data[MAX_ROWS][MAX_COLS];
static uint8_t num_rows = 0;
static int8_t num_cols = 0;

void read_data(void) {
  static char buffer[BUFFER_LENGTH];
  FILE* f; 
  char* c;
  int8_t j;
  f = fopen(FILENAME,"r");
  while (fgets(buffer, BUFFER_LENGTH, f)) {
    j = 0;
    c = strtok(buffer, " ");
    while (c) {
      sscanf(c, "%" SCNd32, &data[num_rows][j]);
      ++j;
      c = strtok(NULL, " ");
    }
    ++num_rows;
  }
  num_cols = j;
  fclose(f);
}

int32_t interpolate(uint8_t row) {
  static int32_t interp[MAX_INTERPOLATION_DEPTH][MAX_COLS];
  int8_t i, j;
  bool all_zero;
  for (i = 0; i < num_cols - 1; ++i) {
    interp[0][i] = data[row][i+1] - data[row][i];
  }
  for (i = 1; i < num_cols-1; ++i) {
    all_zero = true;
    for (j = 0; j < num_cols-i-1; ++j) {
      interp[i][j] = interp[i-1][j+1] - interp[i-1][j];
      if (interp[i][j])
        all_zero = false;
    }
    if (all_zero)
      break;
  }
  interp[i][num_cols-i-1] = 0;
  for (i = i-1; i >= 0; --i) {
    interp[i][num_cols-i-1] = interp[i][0]-interp[i+1][num_cols-i-2];
  }
  return data[row][0] - interp[0][num_cols-1];
}

int32_t solve() {
  uint8_t i;
  int32_t S = 0;
  for (i = 0; i < num_rows; ++i) {
    S += interpolate(i);
  }
  return S;
}

int main(void) {
  fast();
  read_data();

  printf("%" PRId32 "\n", solve());
      
  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  slow();
  return EXIT_SUCCESS;
}

