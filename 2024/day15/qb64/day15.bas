' Day15, part 1 is straightforward (just track at the other end of a stack of
' boxes to see if there is room); for part 2, we need to construct the stack
' of boxes and see if all boxes can move individually (or if any box is
' obstructed by a wall)

' Require explicit variable declarations
Option _Explicit

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

' variable and constant declarations
Const MAX_LINES = 2000
Const EMPTY = 0
Const WALL = 1
Const BOX = 2
Const SET_SIZE = 16
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1, S2
Dim As Integer i, j, k, cols, rows, n_movs, n_boxes

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

cols = Len(lines(0))
rows = UBound(lines)
n_movs = 0

For i = LBound(lines) To UBound(lines)
    If Len(lines(i)) = 0 Then
        rows = i
    End If
    If i > rows Then
        n_movs = n_movs + Len(lines(i))
    End If
Next

Dim M(rows - 1, cols - 1) As Integer ' map for part 1
Dim start_pos1(1) As Integer ' initial (i,j) coordinates of the robot
Dim movs(n_movs - 1, 2) As Integer ' (di,dj) pairs

' we construct first the map for part 1 and record the number of boxes
' then we construct the map for part 2 by expanding the map and creating an
' index data structure for boxes
n_boxes = 0
For i = 0 To rows - 1
    For j = 0 To cols - 1
        Select Case Asc(lines(i), j + 1)
            Case 35: M(i, j) = WALL ' 35 = #
            Case 46: M(i, j) = EMPTY ' 46= .
            Case 64: M(i, j) = EMPTY: start_pos1(0) = i: start_pos1(1) = j
            Case 79: M(i, j) = BOX: n_boxes = n_boxes + 1 ' 79 = O
            Case Else: Print Asc(lines(i), j + 1); Mid$(lines(i), j + 1, 1)
        End Select
    Next
Next

k = 0
For i = rows + 1 To UBound(lines)
    For j = 1 To Len(lines(i))
        Select Case Asc(lines(i), j)
            Case 62: movs(k, 0) = 0: movs(k, 1) = 1 ' >
            Case 94: movs(k, 0) = -1: movs(k, 1) = 0 ' ^
            Case 60: movs(k, 0) = 0: movs(k, 1) = -1 ' <
            Case 118: movs(k, 0) = 1: movs(k, 1) = 0 ' v
            Case Else: Print "ERROR: INVALID MOVEMENT COMMAND": System 1
        End Select
        k = k + 1
    Next
Next

' expand for the second part
Dim W(rows - 1, 2 * cols - 1) As Integer ' wall map for part 2
Dim B(rows - 1, 2 * cols - 1) As Integer ' map of box indices for part 2
Dim Boxes(n_boxes - 1, 2) As Integer ' (i,j0,j1)
Dim start_pos2(1) As Integer ' initial (i,j) coordinates of the robot
start_pos2(0) = start_pos1(0)
start_pos2(1) = 2 * start_pos1(1)

k = 0
For i = LBound(M, 1) To UBound(M, 1)
    For j = LBound(M, 2) To UBound(M, 2)
        Select Case M(i, j)
            Case WALL:
                W(i, 2 * j) = 1
                W(i, 2 * j + 1) = 1
                B(i, 2 * j) = -1
                B(i, 2 * j + 1) = -1
            Case BOX:
                W(i, 2 * j) = 0
                W(i, 2 * j + 1) = 0
                B(i, 2 * j) = k
                B(i, 2 * j + 1) = k
                Boxes(k, 0) = i
                Boxes(k, 1) = 2 * j
                Boxes(k, 2) = 2 * j + 1
                k = k + 1
            Case EMPTY:
                W(i, 2 * j) = 0
                W(i, 2 * j + 1) = 0
                B(i, 2 * j) = -1
                B(i, 2 * j + 1) = -1
        End Select
    Next
Next

S1 = Simulate1(M(), movs(), start_pos1())

S2 = Simulate2(W(), B(), Boxes(), movs(), start_pos2())

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

' Print for part 1 (small boxes)
Sub Print_Map1 (M() As Integer, start_pos() As Integer)
    Dim As Integer i, j
    Dim s As String
    For i = LBound(M, 1) To UBound(M, 2)
        s = ""
        For j = LBound(M, 2) To UBound(M, 2)
            If i = start_pos(0) And j = start_pos(1) Then
                s = s + "@"
            Else
                Select Case M(i, j)
                    Case EMPTY: s = s + "."
                    Case WALL: s = s + "#"
                    Case BOX: s = s + "O"
                    Case Else: s = s + "?"
                End Select
            End If
        Next
        Print s
    Next
End Sub

' Print for part 2 (big boxes)
Sub Print_Map2 (W() As Integer, B() As Integer, i0 As Integer, j0 As Integer)
    Dim As Integer i, j
    Dim s As String
    For i = LBound(W, 1) To UBound(W, 1)
        s = ""
        For j = LBound(W, 2) To UBound(W, 2)
            If i = i0 And j = j0 Then
                s = s + "@"
            ElseIf W(i, j) = 1 Then
                s = s + "#"
            ElseIf B(i, j) >= 0 Then
                If B(i, j + 1) = B(i, j) Then
                    s = s + "["
                ElseIf B(i, j - 1) = B(i, j) Then
                    s = s + "]"
                Else
                    s = s + "?"
                End If
            Else
                s = s + "."
            End If
        Next
        Print s
    Next
End Sub

Function Simulate1&& (M() As Integer, movs() As Integer, start_pos() As Integer)
    Dim As _Integer64 S
    Dim As Integer i0, j0, i1, j1, i2, j2, k, i, j
    i0 = start_pos(0)
    j0 = start_pos(1)
    For k = LBound(movs, 1) To UBound(movs, 1)
        i1 = i0 + movs(k, 0)
        j1 = j0 + movs(k, 1)
        If M(i1, j1) = EMPTY Then
            i0 = i1
            j0 = j1
        ElseIf M(i1, j1) = BOX Then
            i2 = i1 + movs(k, 0)
            j2 = j1 + movs(k, 1)
            Do While M(i2, j2) = BOX
                i2 = i2 + movs(k, 0)
                j2 = j2 + movs(k, 1)
            Loop
            If M(i2, j2) = EMPTY Then
                M(i2, j2) = BOX
                M(i1, j1) = EMPTY
                i0 = i1
                j0 = j1
            End If
        ElseIf M(i1, j1) = WALL Then
            ' do nothing
        Else
            Print "THIS SHOULDN'T HAPPEN"
            System 1
        End If
    Next
    S = 0
    For i = LBound(M, 1) To UBound(M, 1)
        For j = LBound(M, 2) To UBound(M, 2)
            If M(i, j) = BOX Then S = S + 100 * i + j
        Next
    Next
    Simulate1 = S
End Function

Function Simulate2&& (W() As Integer, B() As Integer, Boxes() As Integer, _
    movs() As Integer, start_pos() As Integer)
    Dim As Integer i0, j0, i1, j1, k, di, dj
    Dim As _Integer64 S
    Dim stack(SET_SIZE) As Integer ' stack of boxes as a set
    i0 = start_pos(0)
    j0 = start_pos(1)
    For k = LBound(movs, 1) To UBound(movs, 1)
        di = movs(k, 0)
        dj = movs(k, 1)
        i1 = i0 + di
        j1 = j0 + dj
        If W(i1, j1) = 1 Then
            ' do nothing
        ElseIf B(i1, j1) = -1 Then
            ' just move the robot
            i0 = i1
            j0 = j1
        Else
            ' We know we've hit a box
            Call Set_Clear(stack()) ' clear the stack by setting all to -1
            Call Get_Stack(stack(), B(), Boxes(), B(i1, j1), di, dj)
            If Can_All_Move%(stack(), W(), Boxes(), di, dj) Then
                Call Move_Stack(stack(), B(), Boxes(), di, dj)
                i0 = i1
                j0 = j1
            End If
        End If
    Next
    S = 0
    For k = LBound(Boxes, 1) To UBound(Boxes, 1)
        S = S + Boxes(k, 0) * 100 + Boxes(k, 1)
    Next
    Simulate2 = S
End Function

Sub Print_Set (S() As Integer)
    Dim As Integer i
    Dim As String s
    s = "{"
    For i = LBound(S, 1) To UBound(S, 1)
        If S(i) = -1 Then Exit For
        If i > LBound(S, 1) Then s = s + ","
        s = s + Mid$(Str$(S(i)), 2)
    Next
    s = s + "}"
    Print s
End Sub

' Converts the set into an empty set (sets all elements in the array to -1)
Sub Set_Clear (S() As Integer)
    Dim i As Integer
    For i = LBound(S, 1) To UBound(S, 1)
        S(i) = -1
    Next
End Sub

' Adds an element to the set. If the elment is already there, does nothing.
' e must be non-negative
Sub Set_Add (S() As Integer, e As Integer)
    Dim i As Integer
    For i = LBound(S, 1) To UBound(S, 1)
        If S(i) = e Then Exit Sub
        If S(i) = -1 Then S(i) = e: Exit Sub
    Next
    Print "FATAL ERROR: Set overflow!"
    System 1
End Sub

' returns -1 iff e is included in S
Function Set_Has% (S() As Integer, e As Integer)
    Dim As Integer r, i
    r = 0
    For i = LBound(S, 1) To UBound(S, 1)
        If S(i) = e Then r = -1: Exit For
        If S(i) = -1 Then Exit For
    Next
    Set_Has = r
End Function

' Returns the stack of boxes by adding them into the set stack
Sub Get_Stack (stack() As Integer, B() As Integer, Boxes() As Integer, _
    bx as integer, di As Integer, dj As Integer)
    Dim As Integer i, j1, j2
    ' check if we've already processed the box
    If Set_Has(stack(), bx) Then Exit Sub
    i = Boxes(bx, 0)
    j1 = Boxes(bx, 1)
    j2 = Boxes(bx, 2)
    Call Set_Add(stack(), bx)
    If dj = 1 And B(i, j2 + 1) >= 0 Then
        Call Get_Stack(stack(), B(), Boxes(), B(i, j2 + 1), di, dj)
    ElseIf dj = -1 And B(i, j1 - 1) >= 0 Then
        Call Get_Stack(stack(), B(), Boxes(), B(i, j1 - 1), di, dj)
    ElseIf dj = 0 Then
        If B(i + di, j1) >= 0 Then
            Call Get_Stack(stack(), B(), Boxes(), B(i + di, j1), di, dj)
        End If
        If B(i + di, j2) >= 0 Then
            Call Get_Stack(stack(), B(), Boxes(), B(i + di, j2), di, dj)
        End If
    End If
End Sub

' Returns -1 iff all boxes can move to the given direction
Function Can_All_Move% (stack() As Integer, W() As Integer, Boxes() As Integer, di As Integer, dj As Integer)
    Dim As Integer k, i, j1, j2, bx, r
    r = -1
    For k = LBound(stack, 1) To UBound(stack, 1)
        bx = stack(k)
        If bx = -1 Then Exit For
        i = Boxes(bx, 0)
        j1 = Boxes(bx, 1)
        j2 = Boxes(bx, 2)
        If dj = 1 And W(i, j2 + 1) = 1 Then r = 0: Exit For
        If dj = -1 And W(i, j1 - 1) = 1 Then r = 0: Exit For
        If dj = 0 Then
            If W(i + di, j1) = 1 Then r = 0: Exit For
            If W(i + di, j2) = 1 Then r = 0: Exit For
        End If
    Next
    Can_All_Move% = r
End Function

' moves all boxes in the stack into the given direction
Sub Move_Stack (stack() As Integer, B() As Integer, Boxes() As Integer, _
    di As Integer, dj As Integer)
    Dim As Integer bx, k, i, j1, j2
    ' First remove all from B
    For k = LBound(stack, 1) To UBound(stack, 1)
        bx = stack(k)
        If bx = -1 Then Exit For
        i = Boxes(bx, 0)
        j1 = Boxes(bx, 1)
        j2 = Boxes(bx, 2)
        B(i, j1) = -1
        B(i, j2) = -1
    Next

    ' Then update Boxes
    For k = LBound(stack, 1) To UBound(stack, 1)
        bx = stack(k)
        If bx = -1 Then Exit For
        If di = 0 Then
            Boxes(bx, 1) = Boxes(bx, 1) + dj
            Boxes(bx, 2) = Boxes(bx, 2) + dj
        End If
        If dj = 0 Then
            Boxes(bx, 0) = Boxes(bx, 0) + di
        End If
    Next

    ' Then replace them
    For k = LBound(stack, 1) To UBound(stack, 1)
        bx = stack(k)
        If bx = -1 Then Exit For
        i = Boxes(bx, 0)
        j1 = Boxes(bx, 1)
        j2 = Boxes(bx, 2)
        B(i, j1) = bx
        B(i, j2) = bx
    Next
End Sub
