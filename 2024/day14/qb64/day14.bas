' Day14, first part is simply move the robot by a number of cells in
' appropriate direction modulo side length; second part is not very
' satisfactory: simply assume that in the correct image no two robots overlap
' which coincidentally works

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
Dim As _Integer64 S1, S2, Q1, Q2, Q3, Q4
Dim lines(2000) As String
Dim As Integer n_lines, i, j, k, maxval, t
Dim As Integer cols, rows

start_time = Timer(0.001)

If _CommandCount <> 3 Then
    Print "Usage: "; Command$(0); " <input.txt> <width> <height>"
    System 1
End If

filename = Command$(1)
cols = Val(Command$(2))
rows = Val(Command$(3))

Dim M(rows - 1, cols - 1) As Integer

Open filename$ For Input As #1

n_lines = 0

Do Until EOF(1)
    Line Input #1, lin
    lines(n_lines) = lin
    n_lines = n_lines + 1
Loop

Close #1

Dim p(n_lines - 1, 1) As Integer
Dim v(n_lines - 1, 1) As Integer

Print n_lines

For i = 0 To n_lines - 1
    j = InStr(lines(i), ",")
    p(i, 1) = Val(Mid$(lines(i), 3, j - 3))
    k = InStr(lines(i), "v=")
    p(i, 0) = Val(Mid$(lines(i), j + 1, k - j - 1))
    j = InStr(k, lines(i), ",")
    v(i, 1) = Val(Mid$(lines(i), k + 2, j - k - 2))
    v(i, 0) = Val(Mid$(lines(i), j + 1))
Next

Call Pos_After_Secs(M(), p(), v(), 100)

For i = 0 To (rows - 1) \ 2 - 1
    For j = 0 To (cols - 1) \ 2 - 1
        Q1 = Q1 + M(i, j)
    Next
    For j = (cols + 1) \ 2 To cols - 1
        Q2 = Q2 + M(i, j)
    Next
Next

For i = (rows + 1) \ 2 To rows - 1
    For j = 0 To (cols - 1) \ 2 - 1
        Q3 = Q3 + M(i, j)
    Next
    For j = (cols + 1) \ 2 To cols - 1
        Q4 = Q4 + M(i, j)
    Next
Next i

S1 = Q1 * Q2 * Q3 * Q4

t = 0
maxval = 0
Do While maxval <> 1
    t = t + 1
    Call Pos_After_Secs(M(), p(), v(), t)
    maxval = Max(M())
    S2 = t
Loop
Call Print_Map(M())


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

Function Max% (M() As Integer)
    Dim As Integer i, j, m
    m = M(LBound(M, 1), LBound(M, 2))
    For i = LBound(M, 1) To UBound(M, 1)
        For j = LBound(M, 2) To UBound(M, 2)
            If M(i, j) > m Then m = M(i, j)
        Next
    Next
    Max = m
End Function

Sub Print_Map (M() As Integer)
    Dim As Integer i, j
    For i = LBound(M, 1) To UBound(M, 1)
        For j = LBound(M, 2) To UBound(M, 2)
            Select Case M(i, j)
                Case 0: Print ".";
                Case Else: Print Using "#"; M(i, j);
            End Select
        Next
        Print
    Next
End Sub

Sub Pos_After_Secs (M() As Integer, p() As Integer, v() As Integer, t As Integer)
    Dim As Integer i, j, k, rows, cols
    Call Zero(M())
    rows = UBound(M, 1) + 1
    cols = UBound(M, 2) + 1
    For k = LBound(p, 1) To UBound(p, 1)
        i = (((p(k, 0) + t * v(k, 0)) Mod rows) + rows) Mod rows
        j = (((p(k, 1) + t * v(k, 1)) Mod cols) + cols) Mod cols
        M(i, j) = M(i, j) + 1
    Next
End Sub

Sub Zero (M() As Integer)
    Dim As Integer i, j
    For i = LBound(M, 1) To UBound(M, 1)
        For j = LBound(M, 2) To UBound(M, 2)
            M(i, j) = 0
        Next
    Next
End Sub
