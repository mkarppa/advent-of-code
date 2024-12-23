' Day10, very simple DFS solution

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
Dim As Integer S1, S2, i, j, n_cols, n_rows
Dim M(55, 55) As Integer
Dim V(55, 55) As Integer

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename = Command$(1)

Open filename$ For Input As #1

Do Until EOF(1)
    Line Input #1, lin
    If n_cols = 0 Then n_cols = Len(lin)
    n_rows = n_rows + 1
    For i = 1 To n_cols
        M(n_rows, i) = Asc(lin, i) - 48
    Next
Loop

Close #1

For j = 0 To n_cols + 1
    M(0, j) = 10
    M(n_rows + 1, j) = 10
Next
For i = 0 To n_rows + 1
    M(i, 0) = 10
    M(i, n_cols + 1) = 10
Next

For i = 1 To n_rows
    For j = 1 To n_cols
        If M(i, j) = 0 Then
            Call Zero(V(), n_rows, n_cols)
            S1 = S1 + Solve%(M(), V(), 0, i, j, 0)
            S2 = S2 + Solve%(M(), V(), -1, i, j, 0)
        End If
    Next
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

Function Solve% (M() As Integer, V() As Integer, count As Integer, _
    i As Integer, j As Integer, k As Integer)
    Dim S As Integer
    If k = 9 Then
        If Not count And V(i, j) = 0 Then
            V(i, j) = 1
            S = 1
        ElseIf count Then
            S = 1
        Else
            S = 0
        End If
    Else
        If M(i - 1, j) = k + 1 Then
            S = S + Solve%(M(), V(), count, i - 1, j, k + 1)
        End If
        If M(i + 1, j) = k + 1 Then
            S = S + Solve%(M(), V(), count, i + 1, j, k + 1)
        End If
        If M(i, j - 1) = k + 1 Then
            S = S + Solve%(M(), V(), count, i, j - 1, k + 1)
        End If
        If M(i, j + 1) = k + 1 Then
            S = S + Solve%(M(), V(), count, i, j + 1, k + 1)
        End If
    End If
    Solve% = S
End Function

Sub Zero (V() As Integer, n_rows As Integer, n_cols As Integer)
    Dim As Integer i, j
    For i = 1 To n_rows
        For j = 1 To n_cols
            V(i, j) = 0
        Next
    Next
End Sub
