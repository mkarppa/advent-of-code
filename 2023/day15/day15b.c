#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <inttypes.h>
#include <stdbool.h>
#include <c128.h>

#define MAX_DATA_LENGTH 128
#define FILENAME "input.txt,s"
#define NUM_BOXES 256
#define MAX_BOX_SIZE 8
#define MAX_LENS_LABEL_LENGTH 8

struct Lens {
  char label[MAX_LENS_LABEL_LENGTH];
  uint8_t focal_length;
};

struct Box {
  struct Lens lenses[MAX_BOX_SIZE];
  uint8_t size;
};

struct Box boxes[NUM_BOXES];


void box_init(struct Box* b) {
  b->size = 0;
}

void box_add(uint8_t b, char* label, uint8_t focal_length) {
  struct Box* box = &boxes[b];
  struct Lens* L;
  for (L = box->lenses; L < box->lenses + box->size; ++L) {
    if (strcmp(L->label,label) == 0) {
      L->focal_length = focal_length;
      return;
    }
  }
  strcpy(L->label, label);
  L->focal_length = focal_length;
  ++box->size;
}

void box_remove(uint8_t b, char* label) {
  struct Box* box = &boxes[b];
  uint8_t i;
  for (i = 0; i < box->size; ++i) {
    if (strcmp(box->lenses[i].label, label) == 0)
      break;
  }
  if (i < box->size) {
    for (; i < box->size - 1; ++i) {
      strcpy(box->lenses[i].label, box->lenses[i+1].label);
      box->lenses[i].focal_length = box->lenses[i+1].focal_length;
    }
    --box->size;
  }
}


uint8_t hash(char* s) {
  uint8_t h = 0;
  while (*s) {
    h = 17*(h+*s++);
  }
  return h;
}


void solve() {
  static char line[MAX_DATA_LENGTH];
  uint32_t S = 0;
  int c = 0;
  uint8_t i;
  char op;
  uint8_t l, focal_length = 0, h;
  FILE* f;
  int j;
  uint32_t p, q, r;
  l = 0;
  do {
    box_init(&boxes[l++]);
  }
  while (l > 0);
  f = fopen(FILENAME,"r");
  while (c != '\n') {
    i = 0;
    while (true) {
      c = fgetc(f);
      if (c == ',' || c == '\n')
        break;
      line[i++] = c;
    }
    if (line[i-1] == '-') {
      op = '-';
      line[i-1] = '\0';
    }
    else {
      op = '=';
      focal_length = line[i-1] - '0';
      line[i-2] = '\0';
    }

    h = hash(line);
    if (op == '=')
      box_add(h, line, focal_length);
    else
      box_remove(h, line);
  }
  for (j = 0; j < NUM_BOXES; ++j) {
    p = j+1;
    for (l = 0; l < boxes[j].size; ++l) {
      q = l+1;
      r = boxes[j].lenses[l].focal_length;
      S += p*q*r;
    }
  }
  fclose(f);
  printf("%" PRIu32 "\n", S);

}

int main(void) {
  fast();

  solve();

  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  slow();
  return EXIT_SUCCESS;
}
