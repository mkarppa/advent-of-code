' Day18, nothing but a simple BFS to recover the path as a minor
' optimization, in part 2, the BFS is called only if the new block hits
' the pre-existing shortest path

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
Const MAX_PATH = 1000
Const QUEUE_CAPACITY = 2048
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1
Dim As String S2
Dim As Integer size, steps, i, j, k

start_time = Timer(0.001)

If _CommandCount <> 3 Then
    Print "Usage: "; Command$(0); " <input.txt> <size> <steps>"
    System 1
End If

Call Read_Lines(Command$(1), lines())
size = Val(Command$(2))
steps = Val(Command$(3))

Dim M(-1 To size + 1, -1 To size + 1) As Integer
For i = 0 To size
    M(-1, i) = 1
    M(size + 1, i) = 1
    M(i, -1) = 1
    M(i, size + 1) = 1
Next

For k = 0 To steps - 1
    i = Val(lines(k))
    j = Val(Mid$(lines(k), InStr(lines(k), ",") + 1))
    M(i, j) = 1
Next

Dim As Integer start_pos(1), end_pos(1)
start_pos(0) = 0
start_pos(1) = 0
end_pos(0) = size
end_pos(1) = size

Dim P(size, size) As Integer
S1 = BFS(M(), start_pos(), end_pos(), P())

k = steps
Dim As _Integer64 d
d = S1
Do While d >= 0
    i = Val(lines(k))
    j = Val(Mid$(lines(k), InStr(lines(k), ",") + 1))
    M(i, j) = 1
    If P(i, j) Then
        d = BFS(M(), start_pos(), end_pos(), P())
    End If
    k = k + 1
Loop
S2 = Mid$(Str$(i), 2) + "," + Mid$(Str$(j), 2)


Print "Part 1:"; S1
Print "Part 2: "; S2

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

' P() will store 1 if the cell is on the shortest path
Function BFS&& (M() As Integer, start_pos() As Integer, _
    end_pos() As Integer, P() As Integer)
    ' V(i,j,0) = 1/0 to indicate visitation
    ' V(i,j,1) = i of previous
    ' V(i,j,2) = j of previous
    Dim V(LBound(M, 1) To UBound(M, 1), LBound(M, 2) To UBound(M, 2), 2) As Integer
    ' column 0: i
    ' column 1: j
    ' column 2: previous i
    ' column 3: previous j
    ' row 0: stores (start,end)
    ReDim Q(0, 0) As Integer
    Call Queue_Init(Q())
    Dim As Integer i, j, prev_i, prev_j
    i = start_pos(0)
    j = start_pos(1)
    prev_i = i
    prev_j = j
    Call Queue_Push(Q(), i, j, prev_i, prev_j)
    Do While Queue_Size(Q()) > 0
        Call Queue_Pop(Q(), i, j, prev_i, prev_j)
        If V(i, j, 0) = 0 Then
            V(i, j, 0) = 1
            V(i, j, 1) = prev_i
            V(i, j, 2) = prev_j
            If i = end_pos(0) And j = end_pos(1) Then
                Exit Do
            End If
            If M(i, j + 1) = 0 Then
                Call Queue_Push(Q(), i, j + 1, i, j)
            End If
            If M(i, j - 1) = 0 Then
                Call Queue_Push(Q(), i, j - 1, i, j)
            End If
            If M(i + 1, j) = 0 Then
                Call Queue_Push(Q(), i + 1, j, i, j)
            End If
            If M(i - 1, j) = 0 Then
                Call Queue_Push(Q(), i - 1, j, i, j)
            End If
        End If
    Loop
    Call Zero(P())
    i = end_pos(0)
    j = end_pos(1)
    Dim As Integer i1, j1
    Dim d As Integer
    If V(i, j, 0) = 1 Then
        P(i, j) = -1
        Do
            d = d + 1
            i1 = V(i, j, 1)
            j1 = V(i, j, 2)
            i = i1
            j = j1
            P(i, j) = -1
        Loop Until i = start_pos(0) And j = start_pos(1)
        BFS = d
    Else
        BFS = -1
    End If
End Function

Sub Queue_Init (Q() As Integer)
    ReDim Q(QUEUE_CAPACITY, 3) As Integer
    Q(0, 0) = 1
    Q(0, 1) = 1
    Q(0, 2) = 0
    Q(0, 3) = 0
End Sub

Function Queue_Size% (Q() As Integer)
    Queue_Size = Q(0, 1) - Q(0, 0)
End Function

Sub Queue_Push (Q() As Integer, i As Integer, j As Integer, _
    prev_i As Integer, prev_j)
    If Q(0, 1) > QUEUE_CAPACITY Then
        Call Queue_Requeue(Q())
    End If
    If Q(0, 1) > QUEUE_CAPACITY Then
        Print "FATAL ERROR: Queue at max capacity"
        System 1
    End If
    Q(Q(0, 1), 0) = i
    Q(Q(0, 1), 1) = j
    Q(Q(0, 1), 2) = prev_i
    Q(Q(0, 1), 3) = prev_j
    Q(0, 1) = Q(0, 1) + 1
End Sub

Sub Queue_Requeue (Q() As Integer)
    Dim As Integer k, size
    size = Queue_Size(Q())
    For k = 0 To size - 1
        Q(k + 1, 0) = Q(k + Q(0, 0), 0)
        Q(k + 1, 1) = Q(k + Q(0, 0), 1)
        Q(k + 1, 2) = Q(k + Q(0, 0), 2)
        Q(k + 1, 3) = Q(k + Q(0, 0), 3)
    Next
    Q(0, 0) = 1
    Q(0, 1) = size + 1
End Sub

Sub Queue_Pop (Q() As Integer, i As Integer, j As Integer, _
    prev_i As Integer, prev_j as integer)
    If Queue_Size(Q()) = 0 Then
        Print "FATAL ERROR: Tried to pop an empty queue"
        System 1
    End If
    i = Q(Q(0, 0), 0)
    j = Q(Q(0, 0), 1)
    prev_i = Q(Q(0, 0), 2)
    prev_j = Q(Q(0, 0), 3)
    Q(0, 0) = Q(0, 0) + 1
End Sub

Sub Zero (P() As Integer)
    Dim As Integer i, j
    For i = LBound(P, 1) To UBound(P, 1)
        For j = LBound(P, 2) To UBound(P, 2)
            P(i, j) = 0
        Next
    Next
End Sub
