10 fast : le = 0 : dim a(100) : dim w(10) : dim c(220) : s = 0 : s2 = 0
20 for i = 1 to 220 : c(i) = 1 : next
30 dopen #5,"input.txt,s"
40 do while st = 0
50     gosub 370
60     if le = 0 then gosub 430
70     id = val(mid$(ln$,6,n0))
80     j = i1
90     for i = 1 to n1
100        k = val(mid$(ln$,j,2))
110        a(k) = 1
120        w(i) = k
130        j = j + 3
140    next
150    v = 0
160    for i = i2 to le step 3
170        if a(val(mid$(ln$,i,2))) = 1 then v = v+1
180    next
190    for i = 1 to n1
200        a(w(i)) = 0
210    next
220    if v > 0 then begin
230        s = s + 2^(v-1)
240        for i = 1 to v
250            c(id+i) = c(id+i) + c(id)
260        next
270    bend
280    s2 = s2 + c(id)
290 loop
300 dclose #5
310 print s
320 print s2
330 t = ti : m = int(ti/3600) : s = int((t-m*3600)/60)
340 print "time elapsed"; m; " min"; s; " s"
350 slow
360 end
370 ln$ = "" : get#5, c$
380 do 
390     ln$ = ln$ + c$
400     get#5, c$
410 loop until c$ = chr$(13)
420 return
430 le = len(ln$)
440 for i = 1 to le
450     c$ = mid$(ln$,i,1)
460     if c$ = ":" then n0 = i-6 : i1 = i+2
470     if c$ = chr$(124) then i2 = i+2 : n1 = (i2-i1-2)/3
480 next
490 return
