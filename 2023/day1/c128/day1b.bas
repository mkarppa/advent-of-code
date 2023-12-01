10 dopen #5,"input.txt,s"
20 s = 0
30 fast
40 dim dn$(9)
50 dn$(1) = chr$(111) + chr$(110) + chr$(101)
60 dn$(2) = chr$(116) + chr$(119) + chr$(111)
70 dn$(3) = chr$(116) + chr$(104) + chr$(114) + chr$(101) + chr$(101)
80 dn$(4) = chr$(102) + chr$(111) + chr$(117) + chr$(114)
90 dn$(5) = chr$(102) + chr$(105) + chr$(118) + chr$(101)
100 dn$(6) = chr$(115) + chr$(105) + chr$(120)
110 dn$(7) = chr$(115) + chr$(101) + chr$(118) + chr$(101) + chr$(110)
120 dn$(8) = chr$(101) + chr$(105) + chr$(103) + chr$(104) + chr$(116)
130 dn$(9) = chr$(110) + chr$(105) + chr$(110) + chr$(101)
140 do while st = 0
150     input#5,ln$
160     n = len(ln$) : fi = -1 : la = -1
170     for i = 1 to n
180         c$ = mid$(ln$,i,1) : a = asc(c$) : d = -1
190         if (48 <= a) and (a < 58) then d = a - 48 : else begin
200             if a = 111 then if mid$(ln$,i,3)=dn$(1) then d=1 : goto 370
210             if a = 116 then begin
220                 if mid$(ln$,i,3) = dn$(2) then d = 2 : goto 370
230                 if mid$(ln$,i,5) = dn$(3) then d = 3 : goto 370
240             bend
250             if a = 102 then begin
260                 ss$ = mid$(ln$,i,4)
270                 if ss$ = dn$(4) then d = 4 : goto 370
280                 if ss$ = dn$(5) then d = 5 : goto 370
290             bend
300             if a = 115 then begin
310                 if mid$(ln$,i,3) = dn$(6) then d = 6 : goto 370
320                 if mid$(ln$,i,5) = dn$(7) then d = 7 : goto 370
330             bend
340             if a = 101 then if mid$(ln$,i,5) = dn$(8) then d = 8 : goto 370
350             if a = 110 then if mid$(ln$,i,4) = dn$(9) then d = 9 : goto 370
360         bend
370         if fi = -1 then fi = d
380         if d >= 0 then la = d
390     next
400     s = s + fi*10 + la
410 loop
420 slow
430 print s
440 t = ti : m = int(t/60/60) : se = int((t-3600*m)/60)
450 print "elapsed time"; m; "min"; se; "s"
