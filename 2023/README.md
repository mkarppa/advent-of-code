# Advent of Code 2023

This year, I took upon myself the task of implementing as many problems as possible on the Commodore 128. Why C128 and not C64? Because the latter is such a vulgar tool of the masses and lacks the elegance.

The aim has been as follows:
* If possible, implement the solution in CBM BASIC V7.0,
* If this is too slow, implement the solution in C, compiled to 8502 machine language,
* If this is not possible (usually because of memory constraints), then implement the solution in FORTRAN.

Each solution is accompanied by a Makefile for creating a d64 image of the solution. The inputs are passed as files within the floppy image, in Mac format (carriage return as newline), as this is the format assumed by the BASIC interpreter.

BASIC solutions are tokenized into programs using petcat. C solutions are compiled using cc65. FORTRAN solutions are compiled using gfortran.