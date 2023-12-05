.PHONY: default clean
FC=gfortran
FCFLAGS=-ffixed-form -std=legacy -Wall -Wextra -O3

default: day5a day5b

day5a: day5a.o
	$(FC) -o $@ $<

day5b: day5b.o
	$(FC) -o $@ $<

%.o: %.f
	$(FC) -c $(FCFLAGS) -o $@ $<

clean:
	rm -vf *~ *.o day5a day5b
