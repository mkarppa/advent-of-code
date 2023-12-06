10 fast : dopen #5,"input.txt,s" : c$ = "" : nu$ = ""
20 for i = 1 to 6 : get#5, c$ : next
30 do while c$ <> chr$(13)
40     if c$ <> " " then nu$ = nu$ + c$
50     get#5, c$
60 loop
70 t = val(nu$) : for i = 1 to 10 : get#5, c$ : next : nu$ = ""
80 do while c$ <> chr$(13)
90     if c$ <> " " then nu$ = nu$ + c$
100    get#5, c$
110 loop
120 d = val(nu$)
130 dclose #5
140 s = sqr(t*t-4*d) : x0 = (t-s)/2 : x1 = (t+s)/2
150 if x0 = int(x0) then x0 = x0 + 1 : else x0 = int(x0+1)
160 if x1 = int(x1) then x1 = x1 - 1 : else x1 = int(x1)
170 w = x1-x0+1
180 print w
190 t = ti : m = int(ti/3600) : s = int((t-m*3600)/60)
200 print "time elapsed"; m; " min"; s; " s"
210 slow
