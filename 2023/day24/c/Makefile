.PHONY: all
CC=clang
CFLAGS=-Wall -Wextra -pedantic -std=c17 -O3
LDFLAGS=-lm

all: day24a day24b

day24a: day24a.o
	$(CC) $(LDFLAGS) -o $@ $<

day24b: day24b.o
	$(CC) $(LDFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

