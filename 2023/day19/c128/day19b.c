#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <inttypes.h>
#include <c128.h>

#define MAX_LINE_LENGTH 128

#define COMPARE_NIL 0
#define COMPARE_LESS_THAN 1
#define COMPARE_GREATER_THAN 2

#define HASHMAP_CAPACITY 1024
#define HASHMAP_CAPACITY_BITS 10
#define HASHMAP_CAPACITY_MASK (~((uint16_t)0xffff << HASHMAP_CAPACITY_BITS))

#define MAX_NUM_WORKFLOWS 640
#define MAX_STACK_SIZE 16

#define FILENAME "input.txt,s"

struct Rule {
  uint8_t variable;
  uint8_t compare;
  uint16_t value;
  struct Workflow* next_state;
};

struct Workflow {
  uint8_t num_rules;
  struct Rule rules[4];
};

struct HashMap {
  char keys[HASHMAP_CAPACITY][4];
  struct Workflow* values[HASHMAP_CAPACITY];
  uint16_t size;
};

static struct Workflow W[MAX_NUM_WORKFLOWS];
static struct HashMap name_to_workflow;
static struct Workflow* accept_state;
static struct Workflow* reject_state;
static char accept_state_string[] = { 65, 0 };
static char reject_state_string[] = { 82, 0 };
static char in_state_string[] = { 105, 110, 0 };

struct u64 {
  uint32_t lo;
  uint32_t hi;
};

void u64_iadd(struct u64* x, struct u64* y) {
  uint32_t t = x->lo + y->lo;
  x->hi = x->hi + y->hi + (t < x->lo);  
  x->lo = t;
}

void u64_mul32to64(struct u64* w, uint32_t u, uint32_t v) {
  uint32_t u0, u1, v0, v1, k, t;
  uint32_t w1, w2, w3;
  u0 = u >> 16;
  u1 = u & 0xffff;
  v0 = v >> 16;
  v1 = v & 0xffff;
  t = u1*v1;
  w3 = t & 0xffff;
  k = t >> 16;
  t = u0*v1 + k;
  w2 = t & 0xffff;
  w1 = t >> 16;
  t = u1*v0 + w2;
  k = t >> 16;
  w->hi = u0*v0 + k + w1;
  w->lo = (t << 16) + w3;
}

void u64_mul(struct u64* z, struct u64* x, struct u64* y) { 
  struct u64 w;
  u64_mul32to64(z, x->lo, y->lo);
  w.lo = 0;
  w.hi = x->hi * y->lo + x->lo * y->hi;
  u64_iadd(z, &w);
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
  struct u64 q, t;
  uint16_t r;
  static char buffer[21];
  uint8_t i = 20;
  buffer[20] = 0;
  if (x->hi == 0 && x->lo == 0) {
    --i;
    buffer[i] = '0';
  }
  else {
    t.hi = x->hi;
    t.lo = x->lo;
    while (t.hi != 0 || t.lo != 0) {
      u64_divmod16(&q, &r, &t, 10);
      --i;
      buffer[i] = '0' + r;
      t.hi = q.hi;
      t.lo = q.lo;
    }
  }
  strcpy(s, buffer + i);
}



uint16_t hash(char* s) {
  static const uint8_t T1[] = {
    0x4b, 0xdc, 0x07, 0xb1, 0x7f, 0x80, 0x5d, 0x86, 0x17, 0x9c, 0x77, 0x8e, 
    0x2b, 0x75, 0xa6, 0x03, 0x36, 0xe7, 0xc7, 0xf2, 0x24, 0x0d, 0xcc, 0x98, 
    0xeb, 0x7c, 0x50, 0x42, 0xd1, 0xd3, 0x4c, 0xaf, 0x3f, 0x9d, 0xc8, 0x3e, 
    0x58, 0x56, 0x67, 0x7b, 0xea, 0x04, 0xe1, 0x91, 0xe9, 0xcf, 0xfd, 0xec, 
    0x1d, 0x21, 0x3d, 0x48, 0xce, 0x61, 0xb4, 0x41, 0x8d, 0xa1, 0x25, 0x0b, 
    0x92, 0x37, 0x8b, 0x01, 0xd4, 0xd6, 0x73, 0x35, 0x26, 0xa2, 0x55, 0x6b, 
    0x97, 0x18, 0x87, 0x9a, 0x89, 0xa4, 0x29, 0x6a, 0x6e, 0x0a, 0x02, 0x57, 
    0xed, 0x8f, 0xf7, 0xc9, 0xe8, 0x99, 0xf3, 0x4f, 0x49, 0x08, 0x2e, 0x00, 
    0x2c, 0x69, 0x9f, 0xa5, 0x59, 0xe3, 0x40, 0x3b, 0x81, 0xee, 0x3c, 0xfc, 
    0x84, 0xac, 0xda, 0xe6, 0x05, 0x32, 0x27, 0x20, 0xb6, 0x5f, 0x52, 0x47,
    0x38, 0x5a, 0x9e, 0x11, 0x93, 0xe0, 0xc0, 0x19, 0xd0, 0x1c, 0x54, 0x79, 
    0x4d, 0x5c, 0xdb, 0xaa, 0x65, 0x53, 0xef, 0x64, 0x6d, 0x8c, 0xa8, 0x94, 
    0x6c, 0xbf, 0x76, 0x88, 0xe5, 0xcd, 0x30, 0xa9, 0xca, 0x3a, 0xd7, 0xf9, 
    0xb7, 0x70, 0x7e, 0x34, 0x0f, 0xc3, 0x44, 0x13, 0xdd, 0x14, 0xb2, 0x10, 
    0x95, 0x16, 0x06, 0xc4, 0x09, 0xd2, 0xfe, 0xae, 0xc1, 0xb8, 0xd9, 0xb0, 
    0xb9, 0xdf, 0x83, 0xf1, 0x78, 0xbe, 0x2f, 0x2d, 0xcb, 0xc2, 0x33, 0x51, 
    0xe4, 0x31, 0x66, 0x74, 0xa7, 0x60, 0xab, 0x6f, 0x43, 0xc6, 0x4e, 0x0e, 
    0x45, 0xde, 0x22, 0x82, 0x9b, 0x1f, 0x1b, 0x7d, 0xfb, 0x8a, 0xff, 0x85, 
    0xbb, 0xf0, 0x0c, 0xd5, 0xba, 0xf8, 0x5b, 0xb5, 0x1e, 0xfa, 0xf5, 0x62,
    0x39, 0x12, 0x2a, 0x72, 0x5e, 0x68, 0x63, 0xe2, 0xa0, 0x96, 0x28, 0x90, 
    0xad, 0xbc, 0x23, 0xf4, 0xc5, 0x46, 0x4a, 0xf6, 0x15, 0xbd, 0x7a, 0xa3, 
    0xd8, 0xb3, 0x1a, 0x71
  };
  static uint8_t T2[] = {
    0x87, 0x88, 0x48, 0x6a, 0xad, 0xdb, 0x44, 0xb1, 0xc5, 0x04, 0x73, 0xd5, 
    0x66, 0xcf, 0xd8, 0x63, 0x31, 0xfe, 0xf8, 0x9d, 0x67, 0x79, 0x35, 0xab, 
    0xed, 0xd6, 0x54, 0x46, 0x78, 0x21, 0xa7, 0x3b, 0x14, 0xa9, 0x55, 0x9c, 
    0xea, 0x1c, 0x43, 0x24, 0x77, 0x2b, 0xa1, 0xa8, 0xbb, 0x98, 0x01, 0xef, 
    0xf5, 0x23, 0xb2, 0xd2, 0x15, 0x51, 0x4d, 0x53, 0x97, 0x81, 0xac, 0x45, 
    0xb6, 0xbf, 0x2e, 0xb7, 0x72, 0x3d, 0xf3, 0x95, 0xbd, 0xdc, 0x06, 0x47, 
    0x6c, 0x60, 0x90, 0x37, 0x25, 0x5d, 0x5a, 0x65, 0x4c, 0x12, 0x1f, 0x1a, 
    0x61, 0x2c, 0xc7, 0xc9, 0x3a, 0xde, 0xf0, 0x86, 0xc0, 0xcb, 0x5e, 0x19, 
    0xa3, 0x71, 0xff, 0x10, 0x07, 0xec, 0x0c, 0x32, 0xe6, 0x6d, 0x30, 0xbc, 
    0x62, 0x75, 0x5f, 0xfc, 0x64, 0xee, 0xd0, 0x84, 0xfd, 0x5c, 0x9a, 0x42, 
    0x56, 0x8a, 0x8d, 0xc2, 0x13, 0x3c, 0xba, 0x69, 0x5b, 0x0e, 0x03, 0x0a, 
    0x28, 0xc1, 0xe8, 0x09, 0x85, 0x68, 0x7c, 0xbe, 0xb0, 0xa5, 0x9f, 0x76, 
    0x9b, 0x02, 0xcd, 0xe5, 0x4b, 0x2a, 0xa2, 0xce, 0x20, 0x26, 0x41, 0xfb, 
    0xfa, 0xa4, 0x05, 0xdd, 0x11, 0xb5, 0x8f, 0x8e, 0x1b, 0xcc, 0x0b, 0xd7, 
    0x4e, 0xf1, 0x8b, 0xb3, 0xf2, 0x22, 0x58, 0xd9, 0x36, 0xe9, 0xaf, 0xb9, 
    0x89, 0x7f, 0x59, 0x83, 0xdf, 0x82, 0x27, 0x7a, 0xc4, 0xaa, 0x39, 0xf7, 
    0x96, 0x7b, 0x74, 0xeb, 0x33, 0x4a, 0x08, 0xca, 0xd1, 0x18, 0x9e, 0x50, 
    0xf6, 0x6b, 0x40, 0x7e, 0x70, 0xb8, 0xf9, 0x8c, 0x38, 0xe7, 0xa0, 0x4f, 
    0xae, 0x17, 0xc6, 0x80, 0x3e, 0xe1, 0x6f, 0x49, 0x93, 0x3f, 0x99, 0x57, 
    0x7d, 0xda, 0xa6, 0xb4, 0x29, 0x2d, 0x91, 0xd4, 0xe0, 0xe4, 0x34, 0x16, 
    0x6e, 0xc3, 0xd3, 0x2f, 0xf4, 0x1e, 0x1d, 0xc8, 0x94, 0x00, 0x0f, 0xe2, 
    0x0d, 0xe3, 0x92, 0x52
  };
  uint8_t h1 = 0;
  uint8_t h2 = 0;
  while (*s) {
    h1 = T1[h1^(*s)];
    h2 = T2[h2^(*s)];
    ++s;
  }
  return (((uint16_t)h1) << 8) | ((uint16_t)h2);
}

void hashmap_init(struct HashMap* H) {
  H->size = 0;
  memset(H->keys, 0, 4*HASHMAP_CAPACITY);  
}

void hashmap_insert_key(struct HashMap* H, char* key) {
  uint16_t h = hash(key) & HASHMAP_CAPACITY_MASK;
  while (H->keys[h][0]) {
    if (strcmp(key, H->keys[h]) == 0)
      return;
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  strcpy(H->keys[h], key);
  H->values[h] = &W[H->size];
  ++H->size;
}

struct Workflow* hashmap_find(struct HashMap* H, char* key) {
  uint16_t h = hash(key) & HASHMAP_CAPACITY_MASK;
  while (H->keys[h][0]) {
    if (strcmp(key, H->keys[h]) == 0) 
      return H->values[h];
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  return NULL;  
}

void print_rule(struct Rule* r) {
  if (r->compare == COMPARE_NIL) {
    printf("  -> %ld\n",
           r->next_state - W);
  }
  else {
    printf("  %u %c %u -> %ld\n",
           r->variable,
           (r->compare == COMPARE_LESS_THAN ? '<' :
            r->compare == COMPARE_GREATER_THAN ? '>' :
            '?'),
           r->value,
           r->next_state - W);
  }
}

void print_workflow(struct Workflow* w)  {
  uint8_t i;
  printf("{\n");
  for (i = 0; i < w->num_rules; ++i) {
    print_rule(&w->rules[i]);
  }  
}


void read_data(char* filename) {
  static char line[MAX_LINE_LENGTH];
  FILE* f; 
  int len;
  char* p;
  char* q;
  struct Workflow* w;
  struct Rule* r;

  hashmap_init(&name_to_workflow);
  hashmap_insert_key(&name_to_workflow, accept_state_string);
  hashmap_insert_key(&name_to_workflow, reject_state_string);
  accept_state = hashmap_find(&name_to_workflow, accept_state_string);
  reject_state = hashmap_find(&name_to_workflow, reject_state_string);
    
  f = fopen(filename,"r");
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    len = strlen(line);
    if (len == 1)
      break;
    line[len-2] = '\0';
    p = strchr(line, 123);
    *p = '\0';
    hashmap_insert_key(&name_to_workflow, line);
  }
  fclose(f);

  f = fopen(filename,"r");
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    len = strlen(line);
    if (len == 1)
      break;
    line[len-2] = '\0';
    p = strchr(line, 123);
    *p = '\0';
    ++p;
    w = hashmap_find(&name_to_workflow, line);
    w->num_rules = 0;

    p = strtok(p, ",");
    while (p) {
      q = strchr(p, ':');
      if (q) {
        r = &w->rules[w->num_rules];
        switch (p[0]) {
          case 120:
            r->variable = 0;
            break;
          case 109:
            r->variable = 1;
            break;
          case 97:
            r->variable = 2;
            break;
          case 115:
            r->variable = 3;
            break;
          default:
            assert(false);
            break;
        }
        switch (p[1]) {
          case '<':
            r->compare = COMPARE_LESS_THAN;
            break;
          case '>':
            r->compare = COMPARE_GREATER_THAN;
            break;
          default:
            assert(false);
            break;
        }
        *q++ = '\0';
        sscanf(p+2, "%" SCNu16, &r->value);
        r->next_state = hashmap_find(&name_to_workflow, q);
        ++w->num_rules;
      }
      else {
        r = &w->rules[w->num_rules];
        r->compare = COMPARE_NIL;
        r->next_state = hashmap_find(&name_to_workflow, p);
        ++w->num_rules;
      }
      p = strtok(NULL, ",");
    }
  }

  fclose(f);
}

struct StackElement {
  struct Workflow* state;
  uint16_t lb[4];
  uint16_t ub[4];
};

void solve(struct u64* S) {
  static struct StackElement stack[MAX_STACK_SIZE];
  struct StackElement* sp = stack;
  struct StackElement* tp;
  int8_t i,j;
  struct u64 t1, t2, t3;
  struct Workflow* w;
  struct Rule* r;
  S->hi = S->lo = 0;

  sp->state = hashmap_find(&name_to_workflow, in_state_string);
  for (i = 0; i < 4; ++i) {
    sp->lb[i] = 1;
    sp->ub[i] = 4000;
  }
  ++sp;
  while (sp > stack) {
    --sp;
    if (sp->state == accept_state) {
      t1.hi = 0;
      t1.lo = sp->ub[0] - sp->lb[0] + 1;
      t2.hi = 0;
      t2.lo = sp->ub[1] - sp->lb[1] + 1;
      u64_mul32to64(&t3, t1.lo, t2.lo);
      t1.lo = sp->ub[2] - sp->lb[2] + 1;
      u64_mul(&t2, &t1, &t3);
      t3.hi = 0;
      t3.lo = sp->ub[3] - sp->lb[3] + 1;
      u64_mul(&t1, &t2, &t3);
      u64_iadd(S, &t1);
    }
    else if (sp->state != reject_state) {
      w = sp->state;
      for (i = 0; i < w->num_rules; ++i) {
        r = &w->rules[i];
        if (r->compare == COMPARE_NIL) {
          sp->state = r->next_state;
          ++sp;
          break;
        }
        else if (r->compare == COMPARE_LESS_THAN) { 
          if (sp->ub[r->variable] < r->value) {
            sp->state = r->next_state;
            ++sp;
            break;
          }
          else if (sp->lb[r->variable] < r->value) {
            tp = sp++;
            for (j = 0; j < 4; ++j) {
              sp->lb[j] = tp->lb[j];
              sp->ub[j] = tp->ub[j];
            }
            sp->state = tp->state;
            tp->state = r->next_state;
            tp->ub[r->variable] = r->value - 1;
            sp->lb[r->variable] = r->value;
          } 
        } 
        else if (r->compare == COMPARE_GREATER_THAN) {
          if (sp->lb[r->variable] > r->value) {
            sp->state = r->next_state;
            ++sp;
            break;
          }
          else if (sp->ub[r->variable] > r->value) {
            tp = sp++;
            for (j = 0; j < 4; ++j) {
              sp->lb[j] = tp->lb[j];
              sp->ub[j] = tp->ub[j];
            }
            sp->state = tp->state;
            tp->state = r->next_state;
            tp->lb[r->variable] = r->value + 1;
            sp->ub[r->variable] = r->value;
          }
        }
      }
    }
  }
}

int main(void) {
  struct u64 S;
  char buffer[21];
  read_data(FILENAME);
  solve(&S);
  u64_to_str(buffer, &S);
  printf("%s\n", buffer);

  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  return EXIT_SUCCESS;
}
