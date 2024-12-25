' Day13, simple linear algebra

' Require explicit variable declarations
Option _Explicit

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

' variable declarations
Dim As Double start_time, end_time
Dim As String filename, lin
Dim As _Integer64 S1, S2, a, b, c, d, y0, y1
Dim dat(2000) As String
Dim As Integer n_lines, n, i, j

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename = Command$(1)

Open filename$ For Input As #1

n_lines = 0

Do Until EOF(1)
    Line Input #1, lin
    dat(n_lines) = lin
    n_lines = n_lines + 1
Loop

Close #1

n = (n_lines + 1) \ 4

For i = 0 To n - 1
    j = 4 * i
    a = Val(Mid$(dat(j), 13, 2))
    c = Val(Mid$(dat(j), 19, 2))
    b = Val(Mid$(dat(j + 1), 13, 2))
    d = Val(Mid$(dat(j + 1), 19, 2))
    y0 = Val(Mid$(dat(j + 2), InStr(dat(j + 2), "X=") + 2))
    y1 = Val(Mid$(dat(j + 2), InStr(dat(j + 2), "Y=") + 2))

    S1 = S1 + Solve(a, b, c, d, y0, y1)
    y0 = y0 + 10000000000000
    y1 = y1 + 10000000000000
    S2 = S2 + Solve(a, b, c, d, y0, y1)
Next

Print "Part 1:"; S1
Print "Part 2:"; S2

end_time = Timer(0.001)

Print Using "Took ##.### s"; (end_time - start_time)

' Normal exit
System 0

' Abnormal exit
fail:
Print "Unhandled error code"; Err; "on line"; _ErrorLine; ": "; _ErrorMessage$
System 1

Function Solve&& (a As _Integer64, b As _Integer64, c As _Integer64, _
    d As _Integer64, y0 As _Integer64, y1 As _Integer64)
    Dim As _Integer64 det, x0, x1
    det = a * d - b * c
    x0 = (d * y0 - b * y1) \ det
    x1 = (a * y1 - c * y0) \ det
    If x0 * a + x1 * b = y0 And x0 * c + x1 * d = y1 Then
        Solve = 3 * x0 + x1
    Else
        Solve = 0
    End If
End Function
