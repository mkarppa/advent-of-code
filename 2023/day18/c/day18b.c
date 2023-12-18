#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <assert.h>
#include <stdbool.h>
#include <string.h>

#define MAX_PAIRS 766
#define MAX_LINE_LENGTH 128

static int32_t data[MAX_PAIRS][2];
static int num_coords;

void read_data(char* filename) {
  FILE* f = fopen(filename,"r");
  char d;
  uint32_t n;
  uint8_t l;
  static char line[MAX_LINE_LENGTH];
  static int32_t xy[2];
  
  num_coords = 0;
  xy[0] = xy[1] = 0;
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    data[num_coords][0] = xy[0];
    data[num_coords][1] = xy[1];
    ++num_coords;
    l = strlen(line);
    d = line[l-3];
    line[l-3] = '\0';
    sscanf(line + l - 8, "%" SCNx32, &n);
    switch(d) {
    case '0':
      xy[0] += (int32_t)n;
      break;
    case '1':
      xy[1] -= (int32_t)n;
      break;
    case '2':
      xy[0] -= (int32_t)n;
      break;
    case '3':
      xy[1] += (int32_t)n;
      break;      
    default:
      assert(false && "invalid direction");
      break;
    }
  }  
  fclose(f);
}

uint64_t area(void) {
  int i;
  uint64_t A;
  uint64_t t;
  A = data[0][0]*(data[1][0] - data[num_coords-1][1]) + 
    data[num_coords-1][0] * (data[0][1] - data[num_coords-2][1]);
  for (i = 1; i < num_coords - 1; ++i) {
    t = data[i+1][1]-data[i-1][1];
    t *= data[i][0];
    A += t;
  }
  if ((A >> 63) & 1)
    A = -A;
  return A/2;
}

uint64_t perimeter(void) {
  uint64_t P = labs(data[0][0]-data[num_coords-1][0]) +
    labs(data[0][1]-data[num_coords-1][1]);
  for (int i = 0; i < num_coords-1; ++i) {
    P += labs(data[i+1][0]-data[i][0]) + labs(data[i+1][1]-data[i][1]);
  }
  return P/2+1;
}

int main(int argc, char* argv[]) {
  uint64_t A, P, S;
  if (argc != 2) {
    fprintf(stderr, "usage: %s <input.txt>\n", argv[0]);
    return EXIT_FAILURE;
  }
  read_data(argv[1]);
  A = area();
  P = perimeter();
  S = A + P;
  printf("%" PRIu64 "\n", S);
  return EXIT_SUCCESS;
}
