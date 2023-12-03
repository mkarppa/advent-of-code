.PRECIOUS: %.prg
.PHONY: default clean
PC=petcat
PCFLAGS=-w70
PRG=day3.prg
DISK=$(PRG:.prg=.d64)
INPUT=input.txt
default: $(DISK)

%.d64: %.prg $(INPUT)
	c1541 -format $(@:.d64=),$(subst day,,$(@:.d64=)) d64 $@ -attach $@ \
		-write $< -write $(INPUT) "$(INPUT),s"

%.prg: %.bas
	$(PC) $(PCFLAGS) -o $@ -- $<

clean:
	rm -vf *~ *.d64 *.prg
