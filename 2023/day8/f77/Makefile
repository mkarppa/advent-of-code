.PHONY: default clean
FC=gfortran
FCFLAGS=-ffixed-form -std=legacy -Wall -Wextra -O3

default: day8a day8b

day8a: day8a.o
	$(FC) -o $@ $<

day8b: day8b.o
	$(FC) -o $@ $<

%.o: %.f
	$(FC) -c $(FCFLAGS) -o $@ $<

clean:
	rm -vf *~ *.o day8a day8b
