10 fast
20 dim a(17,17) : s = 0
30 dopen #5,"input.txt,s"
40 do while st = 0
50     gosub 170
60     gosub 330
70     if v > 0 then s = s + v : goto 100
80     gosub 470
90     if h > 0 then s = s + 100*h : goto 100
100 loop
110 dclose #5
120 print s
130 t = ti : m = int(ti/3600) : s = int((t-m*3600)/60)
140 print "time elapsed"; m; " min"; s; " s"
150 slow
160 end
170 nr = 0 : nc = 0
180 do while st = 0
190     gosub 280
200     if len(ln$) = 0 then return
210     nr = nr + 1
220     nc = len(ln$)
230     for j = 1 to nc 
240         if mid$(ln$,j,1) = "#" then a(nr,j) = 1 : else a(nr,j) = 0
250     next 
260 loop 
270 return
280 ln$ = "" : get#5,c$
290 do while asc(c$) <> 13
300     ln$ = ln$ + c$ : get#5,c$
310 loop
320 return
330 v = -1 
340 for k = 1 to nc-1
350     v = k : e = 0
360     for i = 1 to nr
370         m = k : if nc-k < k then m = nc-k
380         for j = 0 to m-1
390             j1 = k-j : j2 = k+j+1
400             if a(i,j1) <> a(i,j2) then e = e+1
405             if e > 1 then v = -1 : j = m-1
410         next
420         if v = -1 then i = nr
430     next
435     if e = 0 then v = -1
440     if v > 0 then k = nc-1
450 next
460 return
470 h = -1
480 for k = 1 to nr-1
490     h = k : e = 0
500     for j = 1 to nc
510         m = k : if nr-k < k then m = nr-k
520         for i = 0 to m-1
530             i1 = k-i : i2 = k+i+1
540             if a(i1,j) <> a(i2,j) then e = e + 1
545             if e > 1 then h = -1 : i = m-1
550         next
560         if h = -1 then j = nc
570     next 
575     if e = 0 then h = -1
580     if h > 0 then k = nr-1
590 next
600 return
