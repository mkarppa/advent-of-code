.PHONY: all
CC=clang
CFLAGS=-Wall -Wextra -pedantic -std=c17 -O3
LDFLAGS=-lm

all: day25

day25: day25.o
	$(CC) $(LDFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

