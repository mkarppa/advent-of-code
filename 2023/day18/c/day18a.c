#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <assert.h>
#include <stdbool.h>

#define MAX_PAIRS 766
#define MAX_LINE_LENGTH 128

static int32_t data[MAX_PAIRS][2];
static int num_coords;

void read_data(char* filename) {
  FILE* f = fopen(filename,"r");
  char d;
  uint8_t n;
  static char line[MAX_LINE_LENGTH];
  static int32_t xy[2];
  
  num_coords = 0;
  xy[0] = xy[1] = 0;
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    data[num_coords][0] = xy[0];
    data[num_coords][1] = xy[1];
    ++num_coords;
    sscanf(line, "%c %" SCNu8, &d, &n);
    switch(d) {
    case 'R':
      xy[0] += n;
      break;
    case 'D':
      xy[1] -= n;
      break;
    case 'L':
      xy[0] -= n;
      break;
    case 'U':
      xy[1] += n;
      break;      
    default:
      assert(false && "invalid direction");
      break;
    }
  }  
  fclose(f);
}

uint32_t area(void) {
  int i;
  int32_t A = data[0][0]*(data[1][0] - data[num_coords-1][1]) +
    data[num_coords-1][0] * (data[0][1] - data[num_coords-2][1]);
  for (i = 1; i < num_coords - 1; ++i) {
    A += data[i][0]*(data[i+1][1]-data[i-1][1]);
  }
  if (A < 0)
    A = -A;
  return A/2;
}

uint32_t perimeter(void) {
  uint32_t P = labs(data[0][0]-data[num_coords-1][0]) +
    labs(data[0][1]-data[num_coords-1][1]);
  for (int i = 0; i < num_coords-1; ++i)
    P += labs(data[i+1][0]-data[i][0]) + labs(data[i+1][1]-data[i][1]);
  return P/2+1;
}

int main(int argc, char* argv[]) {
  uint32_t S;
  if (argc != 2) {
    fprintf(stderr, "usage: %s <input.txt>\n", argv[0]);
    return EXIT_FAILURE;
  }
  read_data(argv[1]);
  S = area() + perimeter();
  printf("%" PRIu32 "\n", S);
  return EXIT_SUCCESS;
}
