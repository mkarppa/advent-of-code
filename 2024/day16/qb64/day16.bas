' Day16, we need only Dijkstra's algorithm, but for an efficient
' implementation, this requires a binary heap as a subroutine

' Require explicit variable declarations
Option _Explicit

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

' variable and constant declarations
Const HEAP_CAPACITY = 1048576
Const MAX_LINES = 2000
Const EAST = 0
Const NORTH = 1
Const WEST = 2
Const SOUTH = 3
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1, S2
Dim As Long i, j, i0, j0, i1, j1, k, d, cols, rows
Dim As Long u, v
Dim start_pos(2) As Integer
Dim end_pos(2) As Integer

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

cols = Len(lines(0))
rows = UBound(lines) + 1

Dim Walls(rows, cols) As Integer
Dim E(rows * cols * 4, 3) As Long ' each vertex has at most 3 neighbors
Dim W(rows * cols * 4, 3) As Long ' Corresponding weights
Dim E2(rows * cols * 4, 3) As Long ' This is for the other direction (Part 2)
Dim W2(rows * cols * 4, 3) As Long

' Vertices are 3-tuples (row,col,direction)
' We pack them into 24 bits
For i = 0 To rows - 1
    For j = 0 To cols - 1
        Select Case Asc(lines(i), j + 1)
            Case 35: ' 35 = #
                Walls(i, j) = 1
            Case 46: ' 46 = .
                Walls(i, j) = 0
            Case 69: ' 69 = E
                end_pos(0) = i
                end_pos(1) = j
                Walls(i, j) = 0
            Case 83: '83 = S
                start_pos(0) = i
                start_pos(1) = j
                Walls(i, j) = 0
            Case Else:
                Print Mid$(lines(i), j + 1, 1); Asc(lines(i), j + 1)
        End Select
    Next
Next

For i = LBound(E, 1) To UBound(E, 1)
    For j = LBound(E, 2) To UBound(E, 2)
        E(i, j) = -1
        E2(i, j) = -1
    Next
Next

For i0 = 0 To rows - 1
    For j0 = 0 To cols - 1
        For d = 0 To 3
            u = Encode_Vertex(i0, j0, d, cols)
            Select Case d
                Case EAST:
                    i1 = i0: j1 = j0 + 1
                Case NORTH:
                    i1 = i0 - 1: j1 = j0
                Case WEST:
                    i1 = i0: j1 = j0 - 1
                Case SOUTH:
                    i1 = i0 + 1: j1 = j0
            End Select
            v = Encode_Vertex(i0, j0, (d + 1) Mod 4, cols)
            E(u, 0) = v
            W(u, 0) = 1000
            E2(v, 0) = u
            W2(v, 0) = 1000
            v = Encode_Vertex(i0, j0, (d + 3) Mod 4, cols)
            E(u, 1) = v
            W(u, 1) = 1000
            E2(v, 1) = u
            W2(v, 1) = 1000
            If i1 >= 0 And i1 < rows And j1 >= 0 And j1 < cols Then
                If Walls(i1, j1) = 0 Then
                    v = Encode_Vertex(i1, j1, d, cols)
                    E(u, 2) = v
                    W(u, 2) = 1
                    E2(v, 2) = u
                    W2(v, 2) = 1
                End If
            End If
        Next
    Next
Next

Dim As Long start_vertex
Dim As Long D(4 * cols * rows)
start_vertex = Encode_Vertex(start_pos(0), start_pos(1), EAST, cols)

Call Dijkstra(E(), W(), start_vertex, D())

Dim As Long end_vertex
end_vertex = Encode_Vertex(end_pos(0), end_pos(1), 0, cols)
S1 = D(end_vertex)
For d = 1 To 3
    u = Encode_Vertex(end_pos(0), end_pos(1), d, cols)
    If D(u) < S1 Then
        end_vertex = u
        S1 = D(u)
    End If
Next

Dim As Long D2(4 * cols * rows)
Call Dijkstra(E2(), W2(), end_vertex, D2())

S2 = 0
For i = 0 To rows - 1
    For j = 0 To cols - 1
        If Walls(i, j) = 0 Then
            For d = 0 To 3
                u = Encode_Vertex(i, j, d, cols)
                If D(u) + D2(u) = S1 Then
                    S2 = S2 + 1
                    Exit For
                End If
            Next
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

' Binary heap routines
' The heap H of capacity C is an array of shape (C+1,2)
' H(0,0) records the size of the heap
' For i>0, H(i,0) is the priority of the ith element
'          H(i,1) is the value of the ith element
Sub Heap_Insert (H() As Long, priority As Long, value As Long)
    Dim As Integer current, parent
    If H(0, 0) = HEAP_CAPACITY Then
        Print "FATAL ERROR: Heap overfull"
        System 1
    End If
    H(0, 0) = H(0, 0) + 1
    current = H(0, 0)
    H(current, 0) = priority
    H(current, 1) = value
    parent = current \ 2
    Do While parent >= 1
        If H(current, 0) < H(parent, 0) Then
            Swap H(current, 0), H(parent, 0)
            Swap H(current, 1), H(parent, 1)
            current = parent
            parent = current \ 2
        Else
            Exit Do
        End If
    Loop
End Sub

' Return the smallest element and restore the heap condition
Sub Heap_Pop (H() As Long, d As Long, u As Long)
    If H(0, 0) = 0 Then
        Print "FATAL ERROR: Tried to extract an element from an empty heap!"
        System 1
    End If
    d = H(1, 0)
    u = H(1, 1)
    H(1, 0) = H(H(0, 0), 0)
    H(1, 1) = H(H(0, 0), 1)
    H(0, 0) = H(0, 0) - 1

    Call Min_Heapify(H(), 1)
End Sub

' Restore the heap condition from index i
Sub Min_Heapify (H() As Long, i As Long)
    Dim As Long left, right, smallest, n
    n = H(0, 0)
    left = 2 * i
    right = 2 * i + 1
    smallest = i
    If left <= n And H(left, 0) < H(smallest, 0) Then
        smallest = left
    End If
    If right <= n And H(right, 0) < H(smallest, 0) Then
        smallest = right
    End If
    If smallest <> i Then
        Swap H(i, 0), H(smallest, 0)
        Swap H(i, 1), H(smallest, 1)
        Call Min_Heapify(H(), smallest)
    End If
End Sub

' Encodes an (i,j,d) tuple into a 24-bit vertex
Function Encode_Vertex& (i As Integer, j As Integer, d As Integer, _
    cols As Integer)
    Encode_Vertex& = i * cols * 4 + j * 4 + d
End Function

' Decodes a vertex into an (i,j,d) tuple
Sub Decode_Vertex (V As Long, cols as integer, i As Integer, j As Integer, _
    d As Integer)
    d = V Mod 4
    j = (V \ 4) Mod cols
    i = V \ (4 * cols)
End Sub

' Constructs the shortest path distances from start to end
Sub Dijkstra (E() As Long, W() As Long, start, D() As Long)
    Dim As Long d, u, i, alt, v
    For i = LBound(D) To UBound(D)
        D(i) = -1
    Next
    D(start) = 0
    Dim Q(HEAP_CAPACITY, 2) As Long
    Call Heap_Insert(Q(), 0, start)
    Do While Q(0, 0) > 0
        Call Heap_Pop(Q(), d, u)
        If d = D(u) Then
            For i = LBound(E, 2) To UBound(E, 2)
                If E(u, i) = -1 Then Exit For
                v = E(u, i)
                alt = D(u) + W(u, i)
                If D(v) = -1 Or alt < D(v) Then
                    D(v) = alt
                    Call Heap_Insert(Q(), alt, v)
                End If
            Next
        End If
    Loop
End Sub
