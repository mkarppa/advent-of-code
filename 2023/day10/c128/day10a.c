#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>
#include <c128.h>
#include <time.h>

#define BUFFER_LENGTH 256
#define PIPE_MAP_MAX_COLS 142
#define PIPE_MAP_MAX_ROWS 142
#define FILENAME "input.txt,s"
#define GROUND 0
#define PIPE_E 0x1
#define PIPE_N 0x2
#define PIPE_W 0x4
#define PIPE_S 0x8
#define PIPE_NS 0xa
#define PIPE_EW 0x5
#define PIPE_NE 0x3
#define PIPE_NW 0x6
#define PIPE_SE 0x9
#define PIPE_SW 0xc
#define TO_FLAT_INDEX(I,J) ((I)*PIPE_MAP_MAX_COLS+(J))
#define FROM_FLAT_INDEX(IDX) (((IDX)/PIPE_MAP_MAX_COLS) + \
                              ((IDX)%PIPE_MAP_MAX_COLS))
#define MAX_PATH_LENGTH 13886

static uint8_t pipe_map[PIPE_MAP_MAX_ROWS][PIPE_MAP_MAX_COLS];
static uint8_t start[2];

void read_data() {
  FILE* f;
  char* c;
  uint8_t i,j;
  static char buffer[BUFFER_LENGTH];

  f = fopen(FILENAME, "r");

  i = 0;
  while (fgets(buffer, BUFFER_LENGTH, f)) {
    ++i;
    c = buffer;
    j = 0;
    while (*c != '\n') {
      ++j;
      switch (*c) {
      case 's':
        start[0] = i;
        start[1] = j;
        break;
      case '7':
        pipe_map[i][j] = PIPE_SW;        
        break;
      case 'f':
        pipe_map[i][j] = PIPE_SE;
        break;
      case 'j':
        pipe_map[i][j] = PIPE_NW;
        break;
      case 'l':
        pipe_map[i][j] = PIPE_NE;
        break;
      case '-':
        pipe_map[i][j] = PIPE_EW;
        break;
      case 124:
        pipe_map[i][j] = PIPE_NS;
        break;
      case '.':
        break;
      default:
        printf("unhandled %c (%d)\n", *c, (int)(*c));
        break;
      }
      ++c;
    }
  }  
  fclose(f);
}

void determine_start_pipe() {
  uint8_t i,j;
  i = start[0];
  j = start[1];
  if ((pipe_map[i-1][j] & PIPE_S) != 0 && (pipe_map[i+1][j] & PIPE_N) != 0)
    pipe_map[i][j] = PIPE_NS;
  else if ((pipe_map[i][j-1] & PIPE_E) != 0 && (pipe_map[i][j+1] & PIPE_W) != 0)
    pipe_map[i][j] = PIPE_EW;
  else if ((pipe_map[i-1][j] & PIPE_S) != 0 && (pipe_map[i][j+1] & PIPE_W) != 0)
    pipe_map[i][j] = PIPE_NE;
  else if ((pipe_map[i-1][j] & PIPE_S) != 0 && (pipe_map[i][j-1] & PIPE_E) != 0)
    pipe_map[i][j] = PIPE_NW;
  else if ((pipe_map[i+1][j] & PIPE_N) != 0 && (pipe_map[i][j+1] & PIPE_W) != 0)
    pipe_map[i][j] = PIPE_SE;
  else if ((pipe_map[i+1][j] & PIPE_N) != 0 && (pipe_map[i][j-1] & PIPE_E) != 0)
    pipe_map[i][j] = PIPE_SW;
}

void get_neighbors(uint8_t* cur, uint8_t* N) {
  uint8_t u,v,i,j,k;
  i = cur[0];
  j = cur[1];
  u = pipe_map[i][j];
  k = 0;
  v = pipe_map[i][j+1];
  if ((u & PIPE_E) && (v & PIPE_W)) {
    N[k++] = i;
    N[k++] = j+1;
  }
  v = pipe_map[i-1][j];
  if ((u & PIPE_N) && (v & PIPE_S)) {
    N[k++] = i-1;
    N[k++] = j;
  }
  v = pipe_map[i][j-1];
  if ((u & PIPE_W) && (v & PIPE_E)) {
    N[k++] = i;
    N[k++] = j-1;
  }
  v = pipe_map[i+1][j];
  if ((u & PIPE_S) && (v & PIPE_N)) {
    N[k++] = i+1;
    N[k++] = j;
  }
}

void next_node(uint8_t* cur, uint8_t* pre) {
  static uint8_t N[4];
  get_neighbors(cur, N);
  if (N[0] == pre[0] && N[1] == pre[1]) {
    pre[0] = cur[0];
    pre[1] = cur[1];
    cur[0] = N[2];
    cur[1] = N[3];
  }
  else {
    pre[0] = cur[0];
    pre[1] = cur[1];
    cur[0] = N[0];
    cur[1] = N[1];
  }
}

void solve() {
  uint8_t cur[2];
  uint8_t pre[2];
  uint16_t path_length = 0;
  determine_start_pipe();
  pre[0] = start[0];
  pre[1] = start[1];
  cur[0] = start[0];
  cur[1] = start[1];
  do {
    next_node(cur, pre);
    ++path_length;
  }
  while (cur[0] != start[0] || cur[1] != start[1]);
  printf("%u\n",path_length/2);
}

int main(void) {
  fast();
  memset(pipe_map, 0, PIPE_MAP_MAX_COLS*PIPE_MAP_MAX_ROWS*sizeof(uint8_t));

  read_data();
  printf("data read at: %ld s\n", clock()/CLOCKS_PER_SEC);

  solve();
  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  slow();
  return EXIT_SUCCESS;
}
