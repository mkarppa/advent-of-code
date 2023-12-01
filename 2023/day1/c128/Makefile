.PRECIOUS: %.prg
.PHONY: default clean
PC=petcat
PCFLAGS=-w70
PRGS=day1a.prg day1b.prg
DISKS=$(PRGS:.prg=.d64)
default: $(DISKS)

day1a.d64: day1a.prg input1.txt
	c1541 -format day1a,1a d64 day1a.d64 -attach day1a.d64 \
		-write day1a.prg -write input1.txt "input.txt,s"

day1b.d64: day1b.prg input2.txt
	c1541 -format day1b,1b d64 day1b.d64 -attach day1b.d64 \
		-write day1b.prg -write input2.txt "input.txt,s"

%.prg: %.bas
	$(PC) $(PCFLAGS) -o $@ -- $<

clean:
	rm -vf *~ *.d64 *.prg
