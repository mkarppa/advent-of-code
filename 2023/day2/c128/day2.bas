100 dopen #5,"input.txt,s" : sa = 0 : sb = 0
110 do while st = 0
120     mr = 0 : mg = 0 : mb = 0 : ln$ = "" : get#5, c$
130     do while c$ <> chr$(13)
140         ln$ = ln$ + c$ : get#5, c$
150     loop
160     le = len(ln$) : id = val(mid$(ln$,6))
170     i = 7 : do while mid$(ln$,i,1) <> ":" : i = i + 1 : loop : i = i + 2
180     do
190         j = i + 1 : do while mid$(ln$,j,1) <> " " : j = j + 1 : loop
200         n = val(mid$(ln$,i,j-i+1)) : a = asc(mid$(ln$,j+1,1)) : i = j + 2
210         do while asc(mid$(ln$,i,1)) > 96 : i = i + 1 : loop : i = i + 2
220         if a = 114 and n > mr then mr = n
230         if a = 103 and n > mg then mg = n
240         if a = 98 and n > mb then mb = n
250     loop while i < le
260     if mr <= 12 and mg <= 13 and mb <= 14 then sa = sa + id
270     sb = sb + mr*mg*mb
280 loop
290 print sa
300 print sb
310 t = ti : m = int(ti/3600) : s = int((t-m*3600)/60)
320 print "time elapsed"; m; " min"; s; " s"
