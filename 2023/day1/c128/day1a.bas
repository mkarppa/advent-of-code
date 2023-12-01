10 dopen #5,"input.txt,s"
20 s = 0
25 fast
30 do while st = 0
40     input#5,ln$
50     n = len(ln$) : fi = -1 : la = -1
60     for i = 1 to n
70         c$ = mid$(ln$,i,1) : a = asc(c$)
80         if (48 <= a) and (a < 58) then d = a - 48 : else d = -1
90         if fi = -1 then fi = d
100        if d >= 0 then la = d
110     next
120     s = s + fi*10 + la
130 loop
135 slow
140 print s
150 t = ti : m = int(t/60/60) : se = int((t-3600*m)/60)
160 print "elapsed time"; m; "min"; se; "s"
