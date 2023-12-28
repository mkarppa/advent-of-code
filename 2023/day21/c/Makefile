.PHONY: all
CC=clang
CFLAGS=-O3 -Wall -Wextra -pedantic -std=c17
LDFLAGS=

all: day21a day21b

day21a: day21a.o
	$(CC) $(LDFLAGS) -o $@ $<

day21b: day21b.o
	$(CC) $(LDFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
