.PHONY: all
CC=clang
CFLAGS=-Wall -Wextra -pedantic -std=c17 -O3
LDFLAGS=

all: day23a day23b

day23a: day23a.o
	$(CC) $(LDFLAGS) -o $@ $<

day23b: day23b.o
	$(CC) $(LDFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

