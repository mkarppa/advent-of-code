.PHONY: default clean
FC=gfortran
FCFLAGS=-ffixed-form -std=legacy -Wall -Wextra

default: day5a

day5a: day5a.o
	$(FC) -o $@ $<

%.o: %.f
	$(FC) -c $(FCFLAGS) -o $@ $<

clean:
	rm -vf *~ day5a day5b
