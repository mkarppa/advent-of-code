#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <assert.h>
#include <stdbool.h>
#include <time.h>

#define PULSE_HIGH 1
#define PULSE_LOW 0
#define FLIPFLOP_ON PULSE_HIGH
#define FLIPFLOP_OFF PULSE_LOW
#define MAX_MODULES 64
#define MAX_OUTPUTS 7
#define MAX_INPUTS 11
#define MAX_LINE_LENGTH 128

#define MODULE_TYPE_DUMMY 0
#define MODULE_TYPE_BROADCASTER 1
#define MODULE_TYPE_FLIPFLOP 2
#define MODULE_TYPE_CONJUNCTION 3
#define HASHMAP_CAPACITY 128
#define HASHMAP_HASH_MASK 0x7f
#define HASHMAP_VALUE_NOT_FOUND 0xff
#define QUEUE_CAPACITY 1024

struct Module {
  uint8_t type;
  uint8_t num_inputs;
  uint8_t num_outputs;
  uint8_t inputs[MAX_INPUTS];
  uint8_t outputs[MAX_OUTPUTS];
  uint8_t memory[MAX_INPUTS];
  uint16_t num_lo;
  uint16_t num_hi;
};

struct HashMap {
  char* keys[HASHMAP_CAPACITY];
  uint8_t values[HASHMAP_CAPACITY];
  uint8_t size;
};

struct QueueElement {
  uint8_t src;
  uint8_t dst;
  uint8_t val;
};

struct Queue {
  struct QueueElement Q[QUEUE_CAPACITY];
  uint16_t begin;
  uint16_t end;
};

uint16_t queue_size(struct Queue* Q) {
  return Q->end - Q->begin;
}

void queue_requeue(struct Queue* Q) {
  uint16_t i = 0;
  if (Q->begin == 0)
    return;
  while (Q->begin < Q->end) {
    Q->Q[i++] = Q->Q[Q->begin++];
  }
  Q->begin = 0;
  Q->end = i;
}

void queue_init(struct Queue* Q) {
  Q->begin = Q->end = 0;
}

void queue_enequeue(struct Queue* Q, uint8_t src, uint8_t dst, uint8_t val) {
  if (Q->end >= QUEUE_CAPACITY)
    queue_requeue(Q);
  if (Q->begin == 0 && Q->end >= QUEUE_CAPACITY) 
    assert(false && "queue capacity exceeded");
  Q->Q[Q->end].src = src;
  Q->Q[Q->end].dst = dst;
  Q->Q[Q->end].val = val;
  ++Q->end;
}

struct QueueElement* queue_dequeue(struct Queue* Q) {
  if (Q->end > Q->begin) {
    return &Q->Q[Q->begin++];
  }
  return NULL;
}

uint8_t hash(char* s) {
  static uint8_t T[] = {
    0x10, 0xd2, 0x22, 0x57, 0x50, 0x42, 0x85, 0x1a, 0xf5, 0x2c, 0x46, 0xec, 
    0xc4, 0xe4, 0xe6, 0xcc, 0x9e, 0xf8, 0xb8, 0x77, 0xba, 0x06, 0x49, 0x58, 
    0xf2, 0xe1, 0xa5, 0xbb, 0x4b, 0x20, 0x19, 0x92, 0x8c, 0x29, 0x13, 0xdf, 
    0xb6, 0xad, 0xeb, 0xf3, 0x78, 0x7b, 0xc5, 0xe8, 0xbd, 0xd3, 0x17, 0x5a,
    0x18, 0x82, 0xc2, 0x02, 0x32, 0x28, 0xf1, 0xfb, 0x93, 0xfa, 0xe7, 0xcb, 
    0xc6, 0xaa, 0xa3, 0xf0, 0xb9, 0xd6, 0xf6, 0x89, 0x2a, 0xcf, 0x9a, 0x6c, 
    0x6f, 0xd5, 0xb5, 0xf7, 0x21, 0x40, 0x4d, 0x04, 0x96, 0xc3, 0x0f, 0x11, 
    0x5f, 0x2e, 0x0b, 0x60, 0x1f, 0x31, 0x7e, 0x9d, 0x90, 0xb4, 0xea, 0x09, 
    0x8b, 0xe9, 0x84, 0x95, 0x1c, 0x30, 0x74, 0x24, 0xa7, 0x3e, 0x39, 0xff, 
    0xcd, 0x9b, 0x6a, 0xfc, 0xc9, 0xdd, 0x34, 0x91, 0xa1, 0x3d, 0x4f, 0xe2, 
    0xbe, 0x07, 0x33, 0x48, 0x47, 0xf4, 0x54, 0x7a, 0x65, 0x70, 0x35, 0xdc, 
    0xb0, 0x81, 0x00, 0xc1, 0x14, 0x0e, 0xa9, 0xfd, 0xe3, 0x8e, 0x5c, 0xd0, 
    0x15, 0x2d, 0x1e, 0x83, 0xa6, 0x8a, 0x7f, 0x1b, 0x87, 0x05, 0xd4, 0x98, 
    0x41, 0xc8, 0x12, 0xaf, 0x7d, 0x5e, 0x62, 0xb7, 0x27, 0x43, 0xed, 0x68, 
    0x99, 0x52, 0x8f, 0x25, 0x2f, 0xfe, 0xe5, 0x01, 0x80, 0x88, 0x37, 0x55, 
    0xa4, 0x1d, 0xee, 0x79, 0x8d, 0xa2, 0x59, 0xae, 0x71, 0xbf, 0x36, 0x6b, 
    0xa8, 0x5d, 0x51, 0x53, 0x3c, 0xc7, 0x03, 0x69, 0xf9, 0x75, 0x3f, 0x2b, 
    0xd7, 0x16, 0xbc, 0xda, 0xa0, 0xce, 0xac, 0x45, 0x0d, 0x9f, 0xc0, 0x61, 
    0xdb, 0x44, 0xd1, 0x63, 0x64, 0xb2, 0x6d, 0xe0, 0x97, 0x38, 0x08, 0x56, 
    0x3a, 0xd8, 0x3b, 0xab, 0xef, 0xca, 0x0a, 0x73, 0x67, 0x0c, 0x94, 0x9c, 
    0xb3, 0x4a, 0xd9, 0x23, 0x7c, 0x4c, 0x6e, 0x4e, 0xb1, 0x76, 0x26, 0x86, 
    0x72, 0xde, 0x66, 0x5b
  };
  uint8_t h = 0;
  while (*s) {
    h = T[h ^ (*s++)];
  }
  return h & HASHMAP_HASH_MASK;
}

void hashmap_init(struct HashMap* H) {
  memset(H->keys, 0, sizeof(char*)*HASHMAP_CAPACITY);
  H->size = 0;
}

void hashmap_insert(struct HashMap* H, char* key, uint8_t value) {
  uint8_t h = hash(key);
  while (H->keys[h] != NULL) {
    if (strcmp(key,H->keys[h]) == 0)
      assert(false && "tried to reinsert");
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;
  }
  H->keys[h] = key;
  H->values[h] = value;
  ++H->size;
}

uint8_t hashmap_find(struct HashMap* H, char* key) {
  uint8_t h = hash(key);
  while (H->keys[h] != NULL) {
     if (strcmp(key,H->keys[h]) == 0)
       return H->values[h];
    ++h;
    if (h == HASHMAP_CAPACITY)
      h = 0;     
  }
  return HASHMAP_VALUE_NOT_FOUND;
}



static struct Module modules[MAX_MODULES];
static char module_names[MAX_MODULES][3];
static uint8_t num_modules;
static struct HashMap names_to_modules;
static struct Queue queue;
static uint8_t broadcaster;
static uint32_t num_lo = 0;
static uint32_t num_hi = 0;



void print_module(uint8_t i) {
  uint8_t j;
  printf("%s%s(", 
         modules[i].type == MODULE_TYPE_FLIPFLOP ? "%" :
         modules[i].type == MODULE_TYPE_CONJUNCTION ? "&" :
         "",
         module_names[i]);
  switch(modules[i].type) {
  case MODULE_TYPE_DUMMY:
    break;
  case MODULE_TYPE_BROADCASTER:
    break;
  case MODULE_TYPE_FLIPFLOP:
    printf("%s", 
           modules[i].memory[0] == FLIPFLOP_OFF ? "OFF" :
           modules[i].memory[0] == FLIPFLOP_ON ? "ON" :
           "???");
    break;
  case MODULE_TYPE_CONJUNCTION:
    for (j = 0; j < modules[i].num_inputs; ++j)
      printf("%s%s:%s",
             j > 0 ? ", " : "",
             module_names[modules[i].inputs[j]],
             modules[i].memory[j] == PULSE_LOW ? "LO" :
             modules[i].memory[j] == PULSE_LOW ? "HI" :
             "??");
    break;
  default:
      assert(false);
      break;
  }
  printf(")\n");
}



void add_module(char* name) {
  uint8_t type; 
  uint8_t i;
  if (name[0] == '%') {
    type = MODULE_TYPE_FLIPFLOP;
    ++name;
  }
  else if (name[0] == '&') {
    type = MODULE_TYPE_CONJUNCTION;
    ++name;
  }
  else if (strcmp(name,"broadcaster") == 0) {
    type = MODULE_TYPE_BROADCASTER;
    broadcaster = num_modules;
  }
  else {
    type = MODULE_TYPE_DUMMY;
  }
  module_names[num_modules][0] = name[0];
  module_names[num_modules][1] = name[1];
  if (name[1] != '\0') {
    module_names[num_modules][2] = '\0';
  }

  modules[num_modules].type = type;
  modules[num_modules].num_inputs = 0;
  modules[num_modules].num_outputs = 0;
  if (type == MODULE_TYPE_FLIPFLOP) {
    modules[num_modules].memory[0] = FLIPFLOP_OFF;
  }
  else if (type == MODULE_TYPE_CONJUNCTION) {
    memset(modules[num_modules].memory, PULSE_LOW, MAX_INPUTS);
  }

  modules[num_modules].num_hi = 0;
  modules[num_modules].num_lo = 0;

  hashmap_insert(&names_to_modules, module_names[num_modules], num_modules);

  ++num_modules;
}

void add_connection(uint8_t src, uint8_t dst) {
  struct Module* m = &modules[src];
  struct Module* n = &modules[dst];
  m->outputs[m->num_outputs++] = dst;
  n->inputs[n->num_inputs++] = src;
}

void read_data(char* filename) {
  FILE* f;
  static char line[MAX_LINE_LENGTH];
  size_t len;
  char* p;
  char* q;
  uint8_t i, j;
  hashmap_init(&names_to_modules);
  num_modules = 0;
  f = fopen(filename, "r");
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    len = strlen(line);
    line[len-1] = '\0';
    p = strchr(line, ' ');
    *p = '\0';
    add_module(line);
  }

  fseek(f, 0, SEEK_SET);
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    len = strlen(line);
    line[len-1] = '\0';
    p = strchr(line, ' ');
    *p = '\0';
    if (line[0] == '%' || line[0] == '&')
      q = line + 1;
    else
      q = line;
    i = strlen(q);
    if (i > 2)
      q[2] = '\0';
    i = hashmap_find(&names_to_modules, q);
    p += 3;
    p = strtok(p, ",");
    while (p) {
      j = strlen(p+1);
      if (j > 2)
        p[3] = '\0';
      j = hashmap_find(&names_to_modules, p+1);
      if (j == HASHMAP_VALUE_NOT_FOUND) {
        add_module(p+1);
        j = hashmap_find(&names_to_modules, p+1);
      }
      add_connection(i,j);
      p = strtok(NULL, ",");
    }
  }
  fclose(f);
}

void print_queue(struct Queue* Q) {
  uint16_t i;
  printf("[");
  for (i = Q->begin; i < Q->end; ++i) {
    printf("%s(%u,%u,%s)",
           i == Q->begin ? "" : ", ",
           Q->Q[i].src,
           Q->Q[i].dst,
           Q->Q[i].val == PULSE_HIGH ? "HI" :
           Q->Q[i].val == PULSE_LOW ? "LO" :
           "??");
  }
  printf("]\n");
}

void send_pulse(uint8_t src, uint8_t dst, uint8_t val) {
  if (val == PULSE_HIGH)
    ++num_hi;
  else if (val == PULSE_LOW)
    ++num_lo;
  else
    assert (false && "invalid pulse");
  queue_enequeue(&queue,src,dst,val);
}

void process_flipflop(uint8_t dst, uint8_t val) {
  struct Module* d = &modules[dst];
  uint8_t i;
  if (val == PULSE_LOW) {
    if (d->memory[0] == FLIPFLOP_OFF) {
      d->memory[0] = FLIPFLOP_ON;
      for (i = 0; i < d->num_outputs; ++i)
        send_pulse(dst, d->outputs[i], PULSE_HIGH);
    }
    else if (d->memory[0] == FLIPFLOP_ON) {
      d->memory[0] = FLIPFLOP_OFF;
      for (i = 0; i < d->num_outputs; ++i)
        send_pulse(dst, d->outputs[i], PULSE_LOW);
    }
    else {
      assert(false && "invalid state");
    }
  }
}

void process_conjunction(uint8_t src, uint8_t dst, uint8_t val) {
  struct Module* d = &modules[dst];
  uint8_t i, j;
  if (val == PULSE_LOW)
    ++d->num_lo;
  else if (val == PULSE_HIGH)
    ++d->num_hi;
  j = num_modules;
  for (i = 0; i < d->num_inputs; ++i) {
    if (d->inputs[i] == src) {
      j = i;
      break;
    }
  }
  assert(j < num_modules);
  d->memory[j] = val;
  for (i = 0; i < d->num_inputs; ++i) {
    if (d->memory[i] == PULSE_LOW) {
      for (j = 0; j < d->num_outputs; ++j) {
        send_pulse(dst, d->outputs[j], PULSE_HIGH);
      }
      return;
    }
  }
  for (i = 0; i < d->num_outputs; ++i) {
    send_pulse(dst, d->outputs[i], PULSE_LOW);
  }
}

void process(uint8_t src, uint8_t dst, uint8_t val) {
  uint8_t i;
  struct Module* d = &modules[dst];
  switch (d->type) {
  case MODULE_TYPE_CONJUNCTION:
    process_conjunction(src,dst,val);
    break;
  case MODULE_TYPE_FLIPFLOP:
    process_flipflop(dst,val);
    break;
  case MODULE_TYPE_BROADCASTER:
    for (i = 0; i < d->num_outputs; ++i)
      send_pulse(dst, d->outputs[i], val);
    break;
  case MODULE_TYPE_DUMMY:
    break;
  default:
    assert(false && "no such type");
    break;
  }
}

void push_button(void) {
  struct QueueElement* q;
  send_pulse(num_modules, broadcaster, PULSE_LOW);
  while ((q = queue_dequeue(&queue))) {
    process(q->src, q->dst, q->val);
  }
}

void print_modules(void) {
  uint8_t i;
  for (i = 0; i < num_modules; ++i) {
    printf("%u ", i);
    print_module(i);
  }
}

uint64_t gcd(uint64_t a, uint64_t b) {
  uint64_t c;
  while (b > 0) {
    c = a % b;
    a = b;
    b = c;
  }
  return a;
}

uint64_t lcm(uint64_t a, uint64_t b) {
  return a*b/gcd(a,b);
}

uint64_t solve(void) {
  static char rx_str[] = { 114, 120, 0 };
  int8_t rx_idx = hashmap_find(&names_to_modules, rx_str);
  struct Module* rx = &modules[rx_idx];
  struct Module* y = &modules[rx->inputs[0]];
  struct Module* conjunctions[4];
  uint8_t i;
  uint16_t j;
  uint16_t cycles[4];
  bool keep_trucking;
  assert(rx->num_inputs == 1);
  assert(y->num_inputs == 4);
  for (i = 0; i < 4; ++i) {
    conjunctions[i] = &modules[y->inputs[i]];
    cycles[i] = 0;
  }

  j = 0;
  
  keep_trucking = true;
  while (keep_trucking) {
    ++j;
    push_button();
    for (i = 0; i < 4; ++i) {
      if (conjunctions[i]->num_lo == 1 && cycles[i] == 0)
        cycles[i] = j;
    }
    keep_trucking = false;
    for (i = 0; i < 4; ++i) {
      if (cycles[i] == 0) {
        keep_trucking = true;
        break;
      }
    }
  }
  return lcm(lcm(lcm(cycles[0],cycles[1]),cycles[2]),cycles[3]);
}

int main(int argc, char* argv[]) {
  uint16_t i;
  read_data(argv[1]);
  printf("data read at: %ld s\n", clock()/CLOCKS_PER_SEC);
  queue_init(&queue);
  printf("%" PRIu64 "\n", solve());
  printf("time elapsed: %ld s\n", clock()/CLOCKS_PER_SEC);
  
  return EXIT_SUCCESS;
}
