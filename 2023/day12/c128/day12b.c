#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h>
#include <c128.h>

#define MAX_LINE_LENGTH 256
#define MAX_COUNTS 30
#define HASHMAP_CAPACITY_BITS 11
#define HASHMAP_CAPACITY 2048
#define HASHMAP_KEY_UNOCCUPIED 0xffff
#define FILENAME "input.txt,s"

struct u64 {
  uint32_t lo;
  uint32_t hi;
};

void u64_from_uint32(struct u64* z, uint32_t x) {
  z->lo = x;
  z->hi = 0;
}

void u64_add(struct u64* z, struct u64* x, struct u64* y) {
  z->lo = x->lo + y->lo;
  z->hi = x->hi + y->hi + (z->lo < x->lo);  
}

void u64_iadd(struct u64* x, struct u64* y) {
  static uint32_t t;
  t = x->lo + y->lo;
  x->hi = x->hi + y->hi + (t < x->lo);  
  x->lo = t;
}


void u64_setbit(struct u64* x, uint8_t i) {
  if (i >= 32)
    x->hi |= 1ul << (i-32);
  else 
    x->lo |= 1ul << i;
}

uint8_t u64_getbit(struct u64* x, uint8_t i) {
  if (i >= 32)
    return (x->hi >> (i-32)) & 1;
  else
    return (x->lo >> i) & 1;
}

bool u64_ge(struct u64* x, struct u64* y) {
  if (x->hi == y-> hi)
    return x->lo >= y->lo;
  else if (x->hi > y->hi)
    return true;
  else
    return false;
}

void u64_shl(struct u64* x, uint8_t l) {
  if (l >= 32) {
    x->hi = x->lo << (l-32);
    x->lo = 0;
  }
  else if (l > 0) {
    x->hi <<= l;
    x->hi |= (x->lo >> (32-l));
    x->lo <<= l;
  }
}

void u64_isub(struct u64* x, struct u64* y) {
  uint32_t t = x->lo - y->lo;
  x->hi = x->hi - y->hi - (t > x->lo);
  x->lo = t;
}

void u64_divmod(struct u64* q, struct u64* r, struct u64* n, struct u64* d) {
  int8_t i;
  q->hi = q->lo = 0;
  r->hi = r->lo = 0;
  if (n->hi == 0) {
    if (d->hi > 0) {
      r->lo = n->lo;
      return;
    }
    else {
      q->lo = n->lo / d->lo;
      r->lo = n->lo % d->lo;
      return;
    }
  }
  for (i = 63; i >= 0; --i) {
    u64_shl(r,1);
    if (u64_getbit(n,i))
      r->lo |= 1;
    if (u64_ge(r,d)) {
      u64_isub(r,d);
      u64_setbit(q,i);
    }
  }
}

void u64_divmod16(struct u64* z, uint16_t* w, struct u64* x, uint16_t y) {
  uint32_t a;
  uint32_t q, r;
  z->hi = z->lo = 0;
  a = (x->hi >> 16) & 0xffff;
  q = a/y;
  r = a%y;
  z->hi |= q << 16;
  a = (r << 16) | (x->hi & 0xffff);
  q = a/y;
  r = a%y;
  z->hi |= q;
  a = (r << 16) | ((x->lo >> 16) & 0xffff);
  q = a/y;
  r = a%y;
  z->lo |= (q << 16);
  a = (r << 16) | (x->lo & 0xffff);
  q = a/y;
  r = a%y;
  z->lo |= q;
  if (w)
    *w = r;
}

void u64_to_str(char* s, struct u64* x) {
  struct u64 p10a = { 0x89e80000, 0x8ac72304 };
  struct u64 p10b;
  struct u64 *p10 = &p10a;
  struct u64 *p10t = &p10b;
  struct u64 a;
  struct u64 b;
  struct u64 q, *r = &b, *y = &a;
  struct u64 *tp;
  bool nz_seen = false;
  a.lo = x->lo;
  a.hi = x->hi;
  if (x->hi == 0) {
    sprintf(s, "%" PRIu32, x->lo);
    return;
  }
  while (p10->hi > 0 || p10->lo > 0) {
    u64_divmod(&q, r, y, p10);
    if (q.lo > 0)
      nz_seen = true;
    if (nz_seen)
      *s++ = '0' + q.lo;
    u64_divmod16(p10t,NULL,p10,10);
    tp = r;
    r = y;
    y = tp;
    tp = p10;
    p10 = p10t;
    p10t = tp;
  }
  if (!nz_seen)
    *s++ = '0';
  *s++ = '\0';
}

struct HashMap {
  uint16_t size;
  uint16_t keys[HASHMAP_CAPACITY];
  struct u64 values[HASHMAP_CAPACITY];
};

void hashmap_init(struct HashMap* H) {
  H->size = 0;
  memset(H->keys, 0xff, HASHMAP_CAPACITY * sizeof(uint16_t));
}


uint16_t hash(uint16_t x) {
  x = 22321*x;
  return x >> 5;
}

void hashmap_insert(struct HashMap* H,
		    uint8_t line_idx,
		    uint8_t count_idx,
		    struct u64* value) {
  uint16_t key = (line_idx << 8) | count_idx;
  uint16_t h = hash(key);
  assert(key != HASHMAP_KEY_UNOCCUPIED);
  while (H->keys[h] != HASHMAP_KEY_UNOCCUPIED) {
    if (H->keys[h] == key) {
      assert(false && "Should not try to reinsert");
      return;
    }
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  H->keys[h] = key;
  H->values[h].lo = value->lo;
  H->values[h].hi = value->hi;
  ++H->size;
}

struct u64* hashmap_find(struct HashMap* H,
			 uint8_t line_idx,
			 uint8_t count_idx) {
  uint16_t key = (line_idx << 8) | count_idx;
  uint16_t h = hash(key);
  while (H->keys[h] != HASHMAP_KEY_UNOCCUPIED) {
    if (H->keys[h] == key) {
      return &H->values[h];
    }
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  return NULL;
}
	 

static struct HashMap cache;
static char line[MAX_LINE_LENGTH];
static uint8_t counts[MAX_COUNTS];
static uint8_t num_counts;

void clean_line() {
  char *p, *q;
  bool in_op = true;
  p = line;
  q = line;
  while (*p != '\n') {
    if (*p == '.') {
      if (!in_op) {
	*q++ = '.';
	in_op = true;
      }
      ++p;
    }
    else {
      *q++ = *p++;
      in_op = false;
    }
  }
  *q = '\0';
}

void get_counts(char* line) {
  char* p;
  num_counts = 0;
  p = strtok(line, ",");
  while (p) {
    counts[num_counts++] = atoi(p);
    p = strtok(NULL, ",");
  }
}

void solve(struct u64* res,
	   uint8_t line_idx,
	   uint8_t len,
	   uint8_t count_idx,
	   uint8_t num_counts,
	   uint8_t sum_counts) {
  struct u64 sol1 = { 0, 0 };
  struct u64 sol2 = { 0, 0 };
  struct u64* cached = NULL;
  bool ok = true;
  char* ln = line + line_idx;
  uint8_t* cnt = counts + count_idx;
  uint8_t i;
  cached = hashmap_find(&cache, line_idx, count_idx);
  if (cached) {
    res->lo = cached->lo;
    res->hi = cached->hi;
    return;
  }
  if (len < sum_counts) {
    hashmap_insert(&cache, line_idx, count_idx, res);
    res->hi = res->lo = 0;
    return;
  }
  if (sum_counts == 0) {
    if (len == 0) {
      res->hi = 0;
      res->lo = 1;
      hashmap_insert(&cache, line_idx, count_idx, res);
      return;
    }
    else if (*ln == '#') {
      res->hi = res->lo = 0;
      hashmap_insert(&cache, line_idx, count_idx, res);
      return;
    }
    else {
      solve(res, line_idx+1, len-1, count_idx, num_counts, sum_counts);
      hashmap_insert(&cache, line_idx, count_idx, res);
      return;
    }
  }

  if (*ln != '#') {
    solve(&sol1, line_idx + 1, len-1, count_idx, num_counts, sum_counts);
  }

  if (*ln != '.') {
    for (i = 0; i < *cnt; ++i) {
      if (ln[i] == '.') {
	ok = false;
	break;
      }
    }
    ok = ok && ln[*cnt] != '#';
    if (ok)
      solve(&sol2, line_idx + *cnt + 1, len - *cnt - 1, count_idx + 1,
	    num_counts - 1, sum_counts - *cnt);
  }

  u64_add(res, &sol1, &sol2);
  hashmap_insert(&cache, line_idx, count_idx, res);
}


int main(void) {
  FILE* f;
  char* p;
  uint8_t len, i, j, sum_counts;
  uint8_t* c;
  struct u64 S = { 0, 0 };
  struct u64 res;
  fast();
  f = fopen(FILENAME,"r");

  while (fgets(line, MAX_LINE_LENGTH, f)) {
    hashmap_init(&cache);
    p = strchr(line, ' ');
    *p = '\0';
    get_counts(p + 1);
    c = counts + num_counts;
    for (j = 0; j < 4; ++j) {
      for (i = 0; i < num_counts; ++i) {
        *c++ = counts[i];
      }
    }
    num_counts *= 5;
        
    len = strlen(line);
    p = line + len;
    for (j = 0; j < 4; ++j) {
      *p++ = '?';
      for (i = 0; i < len; ++i)
        *p++ = line[i];
    }
    *p++ = '\n';
    clean_line();
    len = strlen(line);
    if (line[len-1] != '.') {
      line[len++] = '.';      
      line[len] = '\0';
    }
    sum_counts = 0;
    for (i = 0; i < num_counts; ++i)
      sum_counts += counts[i];
    solve(&res, 0, len, 0, num_counts, sum_counts);
    u64_iadd(&S, &res);
  }

  u64_to_str(line, &S);
  printf("%s\n", line);

  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  
  fclose(f);
  slow();
  return EXIT_SUCCESS;
}
