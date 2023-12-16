#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <inttypes.h>
#include <c128.h>

#define MAX_DATA_LENGTH 23000
#define FILENAME "input.txt,s"

static char buffer[MAX_DATA_LENGTH];

uint8_t hash(char* s) {
  uint8_t h = 0;
  while (*s) {
    h = 17*(h+*s++);
  }
  return h;
}

void read_data() {
  FILE* f;
  f = fopen(FILENAME,"r");
  fgets(buffer, MAX_DATA_LENGTH, f);
  buffer[strlen(buffer)-1] = 0;
  fclose(f);
}

void solve() {
  uint32_t S = 0;
  char* p;
  p = strtok(buffer, ",");
  while (p) {
    S += hash(p);
    p = strtok(NULL, ",");
  }
  printf("%" PRIu32 "\n", S);
}

int main(void) {
  fast();
  read_data();
  printf("data read at: %ld s\n", clock()/CLOCKS_PER_SEC);

  solve();

  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  slow();
  return EXIT_SUCCESS;
}
