10 fast
20 dim a%(142,142) : dim p%(1200,4) : dim g%(360,2) 
30 sy = 32767 : nx = 0 : ny = 0 : pi = 1 : gi = 0 : ip = 0
40 dopen #5, "input.txt,s"
50 do while st = 0
60     input#5,ln$
70     ny = ny + 1
80     if nx = 0 then nx = len(ln$)
90     if ip then pi = pi + 1 : ip = 0
100    for i = 1 to nx
110        c$ = mid$(ln$,i,1) : a = asc(c$)
120        if c$ <> "." then if a < 48 or a >= 58 then a%(ny,i) = sy
130        if a >= 48 and a < 58 then begin
140            if not ip then begin
150                p%(pi,1) = ny : p%(pi,2) = i : p%(pi,3) = i : ip = -1
160            bend : else p%(pi,3) = i
170        p%(pi,4) = p%(pi,4)*10 + (a-48)
180        a%(ny,i) = pi
190        bend : else begin
200            if ip then pi = pi+1 : ip = 0
210        bend
220        if c$ = "*" then gi = gi + 1 : g%(gi,1) = ny : g%(gi,2) = i
230    next
240 loop
250 np = pi - 1 : s = 0
260 for pi = 1 to np
270     py = p%(pi,1) : x0 = p%(pi,2) : x1 = p%(pi,3) : fs = 0
280     y = py - 1
290     for x = x0-1 to x1
300         if a%(y,x) = sy then fs = -1 : x = x1
310     next
320     if fs goto 480
330     x = x1+1
340     for y = py-1 to py
350         if a%(y,x) = sy then fs = -1 : y = py
360     next
370     if fs goto 480
380     y = py + 1
390     for x = x1+1 to x0 step -1
400         if a%(y,x) = sy then fs = -1 : x = x0
410     next
420     if fs goto 480
430     x = x0-1
440     for y = py+1 to py step -1
450         if a%(y,x) = sy then fs = -1 : y = py
460     next
470     if not fs goto 490
480     s = s + p%(pi,4)
490 next
500 print s
510 s = 0 : ng = gi : dim xy(8,2)
520 for gi = 1 to ng
530     p1 = 0 : p2 = 0 : gy = g%(gi,1) : gx = g%(gi,2)
540     xy(1,1) = gy-1 : xy(1,2) = gx - 1
550     xy(2,1) = gy-1 : xy(2,2) = gx  
560     xy(3,1) = gy-1 : xy(3,2) = gx + 1 
570     xy(4,1) = gy : xy(4,2) = gx + 1 
580     xy(5,1) = gy+1 : xy(5,2) = gx + 1 
590     xy(6,1) = gy+1 : xy(6,2) = gx  
600     xy(7,1) = gy+1 : xy(7,2) = gx - 1 
610     xy(8,1) = gy : xy(8,2) = gx - 1 
620     for i = 1 to 8
630         y = xy(i,1) : x = xy(i,2)
640         a = a%(y,x)
650         if a < sy and a > 0 then begin
660             if p1 = 0 then p1 = a : else if p2 = 0 and a <> p1 then p2 = a
670         bend
680     next
690     if p1 > 0 and p2 > 0 then s = s + p%(p1,4)*p%(p2,4)
700 next
710 print s
720 t = ti : m = int(ti/3600) : s = int((t-m*3600)/60)
730 print "time elapsed"; m; " min"; s; " s"
740 slow
