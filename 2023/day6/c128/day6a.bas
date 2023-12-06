10 fast : dopen #5,"input.txt,s"
20 dim ts(4) : dim ds(4) : n = 0 : c$ = ""
30 for i = 1 to 6 : get#5, c$ : next
40 do while c$ <> chr$(13)
50     do while c$ = " " : get#5, c$ : loop
60     nu$ = ""
70     do : nu$ = nu$+c$ : get#5,c$ : a=asc(c$) : loop while a >= 48 and a < 58
80     n = n+1 : ts(n) = val(nu$)
90 loop
100 for i = 1 to 10 : get#5, c$ : next
110 i = 0
120 do while c$ <> chr$(13)
130     do while c$ = " " : get#5, c$ : loop
140     nu$ = ""
150     do : nu$ = nu$+c$ : get#5,c$ : a=asc(c$) : loop while a >= 48 and a < 58
160     i = i + 1 : ds(i) = val(nu$)
170 loop
180 dclose #5
190 w = 1
200 for i = 1 to n
210     t = ts(i) : d = ds(i)
220     s = sqr(t*t-4*d) : x0 = (t-s)/2 : x1 = (t+s)/2
230     if x0 = int(x0) then x0 = x0 + 1 : else x0 = int(x0+1)
240     if x1 = int(x1) then x1 = x1 - 1 : else x1 = int(x1)
250     w = w * (x1-x0+1)
260 next
270 print w
280 t = ti : m = int(ti/3600) : s = int((t-m*3600)/60)
290 print "time elapsed"; m; " min"; s; " s"
300 slow
