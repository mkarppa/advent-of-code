.PRECIOUS: %.prg
.PHONY: default clean
CC=cl65
CFLAGS=-Oi -t c128
PRGS=day7a.prg day7b.prg
DISKS=$(PRGS:.prg=.d64)
INPUT=input.txt
default: $(DISKS)

%.d64: %.prg $(INPUT)
	c1541 -format $(@:.d64=),$(subst day,,$(@:.d64=)) d64 $@ -attach $@ \
		-write $< -write $(INPUT) "$(INPUT),s"

%.prg: %.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -vf *~ *.d64 *.prg
