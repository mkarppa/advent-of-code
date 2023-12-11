.PHONY: default clean
FC=gfortran
FCFLAGS=-ffixed-form -std=legacy -Wall -Wextra -O3

default: day11

day11: day11.o
	$(FC) -o $@ $<

%.o: %.f
	$(FC) -c $(FCFLAGS) -o $@ $<

clean:
	rm -vf *~ *.o day11
