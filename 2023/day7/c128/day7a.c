#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>
#include <time.h>
#include <stdbool.h>
#include <c128.h>

#define MAX_DATA 1000

struct hand_and_bid {
  char hand[5];
  uint32_t bid;
};

static struct hand_and_bid data[MAX_DATA];
static char line[256];

char card_to_value(char c) {
  switch(c) {
  case 't':
    return 8;
    break;
  case 'j':
    return 9;
    break;
  case 'q':
    return 10;
    break;
  case 'k':
    return 11;
    break;
  case 'a':
    return 12;
    break;
  default:
    return c - '2';
    break;
  }
}

void parse_line(struct hand_and_bid* hb) {
  char i;
  for (i = 0; i < 5; ++i) {
    hb->hand[i] = card_to_value(line[i]);
    sscanf(line+6, "%" SCNu32 , &hb->bid);
  }
}

char hand_value(char* hand) {
  char i, c, m = 0, count2 = 0;
  bool has3 = false;
  static char count[13];
  memset(count, 0, 13);
  for (i = 0; i < 5; ++i) {
    c = hand[i];
    ++count[c];
  }
  for (i = 0; i < 13; ++i) {
    c = count[i];
    if (c > m)
      m = c;
    if (c == 3)
      has3 = true;
    if (c == 2)
      ++count2;
  }
  if (m == 5)
    return 7;
  if (m == 4)
    return 6;
  if (has3) {
    if (count2 == 1)
      return 5;
    else
      return 4;
  }
  if (count2 == 2)
    return 3;
  if (count2 == 1)
    return 2;
  return 1;
}

int cmp(const void* left, const void* right) {
  struct hand_and_bid *a, *b;
  char hvl, hvr, i;
  a = left;
  b = right;
  hvl = hand_value(a->hand);
  hvr = hand_value(b->hand);
  if (hvl < hvr)
    return -1;
  if (hvl > hvr)
    return 1;
  for (i = 0; i < 5; ++i) {
    if (a->hand[i] < b->hand[i])
      return -1;
    if (a->hand[i] > b->hand[i])
      return 1;
  }
  return 0;
}

int main(void) {
  FILE* f;
  int n = 0, i;
  uint32_t S = 0;
  fast();
  f = fopen("input.txt,s","r");
  while (fgets(line, 256, f) ) {
    parse_line(&data[n++]);
  }
  fclose(f);

  qsort(data, n, sizeof(struct hand_and_bid), cmp);

  for (i = 0; i < n; ++i) {
    S += (i+1) * data[i].bid;
  }
  printf("%" PRIu32 "\n", S);

  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  slow();
  return EXIT_SUCCESS;
}
