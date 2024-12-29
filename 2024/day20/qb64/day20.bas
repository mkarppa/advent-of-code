' Day19, another application of BFS (although rather a trivial version)
' Then just precompute the length of paths and try all possible shortcuts

' Require explicit variable declarations
Option _Explicit

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

' variable and constant declarations
Const MAX_LINES = 10000
Const MAX_PATH = 10000
Const WALL = 35
Const EMPTY = 46
Const S = 83
Const E = 69
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1, S2
Dim As Integer i, j, k, l, cols, rows, i0, j0, i1, j1, i2, j2, di, dj
Dim As Integer path_len
Dim ds(3, 1) As Integer
Dim start_pos(1) As Integer
Dim end_pos(1) As Integer
ReDim P(MAX_PATH, 1) As Integer ' Cells along the path

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

rows = UBound(lines) + 1
cols = Len(lines(0))
Dim M(rows, cols) As Integer
Dim D(rows, cols) As Integer ' Distances to end from the cell
For i = LBound(lines) To UBound(lines)
    For j = 1 To Len(lines(i))
        Select Case Asc(lines(i), j)
            Case WALL:
                M(i, j - 1) = WALL
            Case EMPTY:
                M(i, j - 1) = EMPTY:
            Case S:
                M(i, j - 1) = EMPTY
                start_pos(0) = i
                start_pos(1) = j - 1
            Case E:
                M(i, j - 1) = EMPTY
                end_pos(0) = i
                end_pos(1) = j - 1
            Case Else:
                Print Mid$(lines(i), j, 1); Asc(lines(i), j)
        End Select
    Next
Next

' Path computation is simple: find the next cell that is not the previous cell
ds(0, 0) = 1: ds(0, 1) = 0
ds(1, 0) = -1: ds(1, 1) = 0
ds(2, 0) = 0: ds(2, 1) = 1
ds(3, 0) = 0: ds(3, 1) = -1
i0 = start_pos(0)
j0 = start_pos(1)
k = 0
P(k, 0) = i0
P(k, 1) = j0
i1 = i0
j1 = j0
Do Until i2 = end_pos(0) And j2 = end_pos(1)
    k = k + 1
    For l = 0 To 3
        di = ds(l, 0)
        dj = ds(l, 1)
        i2 = i1 + di
        j2 = j1 + dj
        If M(i2, j2) = EMPTY And (i2 <> i0 Or j2 <> j0) Then
            Exit For
        End If
    Next
    P(k, 0) = i2
    P(k, 1) = j2
    i0 = i1
    j0 = j1
    i1 = i2
    j1 = j2
Loop

path_len = k + 1
For k = 0 To path_len - 1
    i = P(k, 0)
    j = P(k, 1)
    D(i, j) = path_len - k - 1
Next

S1 = Solve(M(), P(), D(), path_len, 2, 100)
S2 = Solve(M(), P(), D(), path_len, 20, 100)

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

Sub Read_Lines (filename As String, lines() As String)
    Dim lin As String
    Dim n As Integer
    Open filename For Input As #1
    Do Until EOF(1)
        Line Input #1, lin
        lines(n) = lin
        n = n + 1
    Loop
    Close #1
    ReDim _Preserve lines(n - 1) As String
End Sub

Function Solve&& (M() As Integer, P() As Integer, D() As Integer, _
    path_len As Integer, max_d As Integer, t As Integer)
    Dim As Integer di, dj, k, i0, j0, i1, j1, d
    Dim As _Integer64 Su
    Su = 0
    For k = 0 To path_len - 1
        i0 = P(k, 0)
        j0 = P(k, 1)
        For di = -max_d To max_d
            i1 = i0 + di
            If i1 < 0 Or i1 > UBound(M, 1) Then _Continue
            For dj = -(max_d - Abs(di)) To max_d - Abs(di)
                j1 = j0 + dj
                If j1 < 0 Or j1 > UBound(M, 2) Then _Continue
                If M(i1, j1) <> EMPTY Then _Continue
                d = Abs(di) + Abs(dj)
                If D(i0, j0) - D(i1, j1) - d >= t Then
                    Su = Su + 1
                End If
            Next
        Next
    Next
    Solve = Su
End Function
