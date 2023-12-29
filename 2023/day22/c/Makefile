.PHONY: all
CC=clang
CFLAGS=-Wall -Wextra -pedantic -std=c17 -O3
LDFLAGS=

all: day22a day22b

day22a: day22a.o
	$(CC) $(LDFLAGS) -o $@ $<

day22b: day22b.o
	$(CC) $(LDFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

