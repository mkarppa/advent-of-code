#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <assert.h>
#include <stdbool.h>
#include <c128.h>

#define DIR_EAST 1
#define DIR_NORTH 2
#define DIR_WEST 4
#define DIR_SOUTH 8
#define DIR_HORIZONTAL 5
#define DIR_VERTICAL 10
#define EMPTY 0
#define EMPTY_CHAR '.'
#define MIRROR_LEFT 16
#define MIRROR_LEFT_CHAR '/'
#define MIRROR_RIGHT 32
#define MIRROR_RIGHT_CHAR 92
#define HORIZONTAL_SPLITTER 64
#define HORIZONTAL_SPLITTER_CHAR '-'
#define VERTICAL_SPLITTER 128
#define VERTICAL_SPLITTER_CHAR 124
#define ENERGIZED 0xf

#define STACK_CAPACITY 128
#define MAX_ROWS 110
#define MAX_COLS 110
#define MAX_LINE_LENGTH 128
#define FILENAME "input.txt,s"

struct Beam {
  uint8_t row;
  uint8_t col;
  uint8_t dir;
};

static struct Beam stack[STACK_CAPACITY];
static struct Beam* stack_pointer = stack;
static uint8_t map[MAX_ROWS][MAX_COLS];
static uint8_t visited[MAX_ROWS][MAX_COLS];
static uint8_t num_rows;
static uint8_t num_cols;

void stack_pop() {
  --stack_pointer;
}

void stack_push(uint8_t row, uint8_t col, uint8_t dir) {
  stack_pointer->row = row;
  stack_pointer->col = col;
  stack_pointer->dir = dir;
  ++stack_pointer;
}

struct Beam* stack_peek() {
  return stack_pointer - 1;
}

void clear_visited() {
  uint8_t i, j;
  for (i = 0; i < MAX_ROWS; ++i)
    for (j = 0; j < MAX_COLS; ++j)
      visited[i][j] = EMPTY;
}

uint8_t mirror_left(uint8_t dir) {
  switch(dir) {
  case DIR_EAST:
    return DIR_NORTH;
    break;
  case DIR_NORTH:
    return DIR_EAST;
    break;
  case DIR_WEST:
    return DIR_SOUTH;
    break;
  case DIR_SOUTH:
    return DIR_WEST;
    break;
  }
  return 0;
}

uint8_t mirror_right(uint8_t dir) {
  switch(dir) {
  case DIR_EAST:
    return DIR_SOUTH;
    break;
  case DIR_NORTH:
    return DIR_WEST;
    break;
  case DIR_WEST:
    return DIR_NORTH;
    break;
  case DIR_SOUTH:
    return DIR_EAST;
    break;
  }
  return 0;
}

uint16_t simulate(uint8_t start_row, uint8_t start_col, uint8_t start_dir) {
  uint16_t S = 0;
  uint8_t i, j, d;
  struct Beam* beam;
  clear_visited();
  stack_push(start_row, start_col, start_dir);
  while (stack_pointer != stack) {
    beam = stack_peek();
    i = beam->row;
    j = beam->col;
    d = beam->dir;
    assert(d > 0);
    if (i >= num_rows || j >= num_cols || (visited[i][j] & d) != 0) {
      stack_pop();
    }
    else {
      visited[i][j] |= d;
      if ((visited[i][j] & ENERGIZED) == d)
        ++S;
      if ((map[i][j] & VERTICAL_SPLITTER) && (d & DIR_HORIZONTAL)) {
        beam->dir = DIR_NORTH;
        stack_push(i,j,DIR_SOUTH);
      }
      else if ((map[i][j] & HORIZONTAL_SPLITTER) && (d & DIR_VERTICAL)) {
        beam->dir = DIR_EAST;
        stack_push(i,j,DIR_WEST);
      }
      else {
        if (map[i][j] & MIRROR_LEFT) {
          d = beam->dir = mirror_left(d);
        }
        else if (map[i][j] & MIRROR_RIGHT) {
          d = beam->dir = mirror_right(d); 
        }     
        switch(d) {
        case DIR_EAST:
          ++beam->col;
          break;
        case DIR_NORTH:
          --beam->row;
          break;
        case DIR_WEST:
          --beam->col;
          break;
        case DIR_SOUTH:
          ++beam->row;
          break;
        }
      }
    }
  }
  return S;
}

void print_map() {
  uint8_t i,j;
  char c;
  for (i = 0; i < num_rows; ++i) { 
    for (j = 0; j < num_cols; ++j) {
      switch(map[i][j]) {
      case EMPTY:
        c = EMPTY_CHAR;
        break;
      case MIRROR_LEFT:
        c = MIRROR_LEFT_CHAR;
        break;
      case MIRROR_RIGHT:
        c = MIRROR_RIGHT_CHAR;
        break;
      case HORIZONTAL_SPLITTER:
        c = HORIZONTAL_SPLITTER_CHAR;
        break;
      case VERTICAL_SPLITTER:
        c = VERTICAL_SPLITTER_CHAR;
        break;
      default:
        assert(false && "invalid value");
      }
      printf("%c",c);
    }
    printf("\n");
  }
}

void read_data(char* filename) {
  static char line[MAX_LINE_LENGTH];
  FILE* f = fopen(filename,"r");
  char c;
  num_rows = 0;
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    num_cols = 0;
    while ((c = line[num_cols]) != '\n') {
      switch(c) {
      case EMPTY_CHAR:
        map[num_rows][num_cols] = EMPTY;
        break;
      case MIRROR_LEFT_CHAR:
        map[num_rows][num_cols] = MIRROR_LEFT;
        break;
      case MIRROR_RIGHT_CHAR:
        map[num_rows][num_cols] = MIRROR_RIGHT;
        break;
      case HORIZONTAL_SPLITTER_CHAR:
        map[num_rows][num_cols] = HORIZONTAL_SPLITTER;
        break;
      case VERTICAL_SPLITTER_CHAR:
        map[num_rows][num_cols] = VERTICAL_SPLITTER;
        break;
      default:
        printf("%c %u invalid\n", c, c);
        assert(false);
      }
      ++num_cols;
    }
    ++num_rows;
  }
  fclose(f);
}


int main(void) {
  fast();
  read_data(FILENAME);
  printf("data read at: %ld s\n", clock()/CLOCKS_PER_SEC);
 
  printf("%u\n", simulate(0, 0, DIR_EAST));
  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);

  slow();

  return EXIT_SUCCESS;
}

