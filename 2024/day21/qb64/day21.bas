' Day21, Possibly the most annoying problem of the year
' First construct the shortest path between buttons using BFS (two cases)
' Then reconstruct all path variations
' Then apply dynamic programming to solve the shortest sequence recursively
' Start from the numpad, then work through the directional pads
' Implemented queue and hashmap, queue for BFS and hashmap for memoization

' Require explicit variable declarations
Option _Explicit

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

' variable and constant declarations
Const HASHMAP_CAPACITY = 16384
Const QUEUE_CAPACITY = 1024
Const MAX_PATHS = 10
Const A_BUTTON = 10
Const DIRPAD_RIGHT = 0
Const DIRPAD_UP = 1
Const DIRPAD_LEFT = 2
Const DIRPAD_DOWN = 3
Const DIRPAD_A = 4
Const MAX_LINES = 10000
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1, S2
Dim As Integer i, j, k
ReDim P(0) As String



start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

' G(i,j) is a non-empty string showing the directional relationship if one can
' move from key i to key j with one step
Dim G_KEYPAD(10, 10) As String
G_KEYPAD(7, 8) = ">"
G_KEYPAD(7, 4) = "v"
G_KEYPAD(8, 7) = "<"
G_KEYPAD(8, 5) = "v"
G_KEYPAD(8, 9) = ">"
G_KEYPAD(9, 8) = "<"
G_KEYPAD(9, 6) = "v"
G_KEYPAD(4, 7) = "^"
G_KEYPAD(4, 5) = ">"
G_KEYPAD(4, 1) = "v"
G_KEYPAD(5, 4) = "<"
G_KEYPAD(5, 8) = "^"
G_KEYPAD(5, 2) = "v"
G_KEYPAD(5, 6) = ">"
G_KEYPAD(6, 5) = "<"
G_KEYPAD(6, 9) = "^"
G_KEYPAD(6, 3) = "v"
G_KEYPAD(1, 4) = "^"
G_KEYPAD(1, 2) = ">"
G_KEYPAD(2, 1) = "<"
G_KEYPAD(2, 5) = "^"
G_KEYPAD(2, 3) = ">"
G_KEYPAD(2, 0) = "v"
G_KEYPAD(3, 2) = "<"
G_KEYPAD(3, 6) = "^"
G_KEYPAD(3, 10) = "v"
G_KEYPAD(0, 2) = "^"
G_KEYPAD(0, 10) = ">"
G_KEYPAD(10, 0) = "<"
G_KEYPAD(10, 3) = "^"

Dim Shared keypad_paths(10, 10, MAX_PATHS) As String
For i = 0 To 10
    For j = 0 To 10
        Call BFS_All_Paths(G_KEYPAD(), i, j, P())
        For k = LBound(P) To UBound(P)
            If P(k) = "" Then Exit For
            keypad_paths(i, j, k) = P(k)
        Next
    Next
Next

' Same as above but for the directional pad
Dim G_DIRPAD(4, 4) As String
G_DIRPAD(DIRPAD_UP, DIRPAD_A) = ">"
G_DIRPAD(DIRPAD_UP, DIRPAD_DOWN) = "v"
G_DIRPAD(DIRPAD_A, DIRPAD_UP) = "<"
G_DIRPAD(DIRPAD_A, DIRPAD_RIGHT) = "v"
G_DIRPAD(DIRPAD_LEFT, DIRPAD_DOWN) = ">"
G_DIRPAD(DIRPAD_DOWN, DIRPAD_LEFT) = "<"
G_DIRPAD(DIRPAD_DOWN, DIRPAD_UP) = "^"
G_DIRPAD(DIRPAD_DOWN, DIRPAD_RIGHT) = ">"
G_DIRPAD(DIRPAD_RIGHT, DIRPAD_DOWN) = "<"
G_DIRPAD(DIRPAD_RIGHT, DIRPAD_A) = "^"

Dim Shared dirpad_paths(4, 4, MAX_PATHS) As String
For i = 0 To 4
    For j = 0 To 4
        Call BFS_All_Paths(G_DIRPAD(), i, j, P())
        For k = LBound(P) To UBound(P)
            If P(k) = "" Then Exit For
            dirpad_paths(i, j, k) = P(k)
        Next
    Next
Next

ReDim K1(0) As String
ReDim K2(0) As Integer
ReDim V(0) As _Integer64
Call Hashmap_Init(K1(), K2(), V())
S1 = 0
For i = LBound(lines) To UBound(lines)
    S1 = S1 + Solve_Keypad(lines(i), 2, K1(), K2(), V()) * _
        Val(lines(i))
Next

Call Hashmap_Init(K1(), K2(), V())
S2 = 0
Dim As _Integer64 S
For i = LBound(lines) To UBound(lines)
    S = Solve_Keypad(lines(i), 25, K1(), K2(), V())
    S2 = S2 + S * Val(lines(i))
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

' Writes all shortest paths from S to E in P
' P will be ReDimmed
Sub BFS_All_Paths (G() As String, S As Integer, E As Integer, P() As String)
    Dim dists(LBound(G, 1) To UBound(G, 1)) As Integer
    Dim As Integer u, v, d
    For v = LBound(dists) To UBound(dists)
        dists(v) = -1
    Next

    Dim Q(QUEUE_CAPACITY, 1) As Integer
    Call Queue_Init(Q())

    Call Queue_Push(Q(), S, 0)

    Do While Queue_Size(Q()) > 0
        Call Queue_Pop(Q(), u, d)

        If dists(u) = -1 Then
            dists(u) = d
            For v = LBound(dists) To UBound(dists)
                If G(u, v) <> "" Then
                    Call Queue_Push(Q(), v, d + 1)
                End If
            Next
        End If
    Loop

    ' (i,j) = -1 iff we arrived at i from j on some path
    Dim prevs(LBound(G, 1) To UBound(G, 1), LBound(G, 2) To UBound(G, 2)) As Integer
    ' denotes if we have already processed the nodes predecessors
    Dim visited(LBound(G, 1) To UBound(G, 1))
    Call Queue_Init(Q())
    Call Queue_Push(Q(), E, dists(E))
    Do While Queue_Size(Q()) > 0
        Call Queue_Pop(Q(), u, d)
        If Not visited(u) Then
            visited(u) = -1
            For v = LBound(G, 1) To UBound(G, 1)
                If G(u, v) <> "" And dists(v) = d - 1 Then
                    prevs(u, v) = -1
                    Call Queue_Push(Q(), v, d - 1)
                End If
            Next
        End If
    Loop

    ReDim P(MAX_PATHS) As String
    Dim path_num As Integer
    path_num = 0
    Call Recurse_Paths(P(), prevs(), G(), "", path_num, S, E)
End Sub

Sub Recurse_Paths (P() As String, prevs() As Integer, G() As String, _
    prefix As String, path_num As Integer, cur As Integer, target As Integer)
    Dim As Integer nex
    If cur = target Then
        P(path_num) = prefix + "A"
        path_num = path_num + 1
        Exit Sub
    End If
    For nex = LBound(prevs) To UBound(prevs)
        If prevs(nex, cur) And G(cur, nex) <> "" Then
            Call Recurse_Paths(P(), prevs(), G(), prefix + G(cur, nex), _
                path_num, nex, target)
        End If
    Next
End Sub

Sub Queue_Init (Q() As Integer)
    Q(0, 0) = 1 ' Queue start
    Q(0, 1) = 1 ' Queue end
End Sub

Sub Queue_Requeue (Q() As Integer)
    Dim As Integer i, j
    i = 1
    For j = Q(0, 0) To Q(0, 1) - 1
        Q(i, 0) = Q(j, 0)
        Q(i, 1) = Q(j, 1)
        i = i + 1
    Next
    Q(0, 0) = 1
    Q(0, 1) = i
End Sub

Sub Queue_Push (Q() As Integer, v As Integer, d As Integer)
    If Q(0, 1) > QUEUE_CAPACITY Then
        Call Queue_Requeue(Q())
    End If
    If Q(0, 1) > QUEUE_CAPACITY Then
        Print "FATAL ERROR: Queue at capacity!"
        System 1
    End If
    Q(Q(0, 1), 0) = v
    Q(Q(0, 1), 1) = d
    Q(0, 1) = Q(0, 1) + 1
End Sub

Sub Queue_Pop (Q() As Integer, v As Integer, d As Integer)
    If Q(0, 0) = Q(0, 1) Then
        Print "FATAL ERROR: Tried to pop an empty queue!"
        System 1
    End If
    v = Q(Q(0, 0), 0)
    d = Q(Q(0, 0), 1)
    Q(0, 0) = Q(0, 0) + 1
End Sub

Function Queue_Size% (Q() As Integer)
    Queue_Size = Q(0, 1) - Q(0, 0)
End Function

Function Solve_Keypad&& (code As String, max_depth As Integer, _
    K1() As String, K2() As Integer, V() As _Integer64)
    Dim As Long i, j, k
    Dim As Integer num_code(Len(code) - 1, 1)
    ' the string starts implicitly with an A
    i = 10
    For k = 1 To Len(code)
        Select Case Asc(code, k)
            Case 65:
                j = 10
            Case Else:
                j = Asc(code, k) - 48
        End Select
        num_code(k - 1, 0) = i
        num_code(k - 1, 1) = j
        i = j
    Next

    ReDim paths(0) As String
    Call Generate_Paths(paths(), num_code(), keypad_paths())

    Dim As _Integer64 S_best, S
    S_best = 9223372036854775807
    For k = LBound(paths) To UBound(paths)
        S = Solve_Dirpad(paths(k), 1, max_depth, K1(), K2(), V())
        If S < S_best Then S_best = S
    Next
    Solve_Keypad = S_best
End Function

Function Solve_Dirpad&& (seq As String, depth As Integer, _
    max_depth As Integer, K1() As String, K2() As Integer, _
    V() As _Integer64)
    Dim As Long i, j, k
    Dim As String subseq, rest
    Dim As _Integer64 S, S_best

    If Hashmap_Has(K1(), K2(), seq, depth) Then
        Solve_Dirpad = Hashmap_Get(K1(), K2(), V(), seq, depth)
        Exit Function
    End If
    If depth > max_depth Then
        S = Len(seq)
        Call Hashmap_Insert(K1(), K2(), V(), seq, depth, S)
        Solve_Dirpad = S
        Exit Function
    End If
    If seq = "" Then
        Solve_Dirpad = 0
        Exit Function
    End If

    ' the sequence starts implicitly with a 'A' and always ends explicitly
    ' with an 'A'
    i = InStr(seq, "A")
    subseq = Left$(seq, i)
    rest = Mid$(seq, i + 1)

    Dim As Integer num_seq(Len(subseq) - 1, 1)
    i = DIRPAD_A
    For k = 1 To Len(subseq)
        Select Case Asc(subseq, k)
            Case 60: ' 60 = <
                j = DIRPAD_LEFT
            Case 62: '62 = >
                j = DIRPAD_RIGHT
            Case 65: ' 65 = A
                j = DIRPAD_A
            Case 94: ' 94 = ^
                j = DIRPAD_UP
            Case 118: ' 118 = v
                j = DIRPAD_DOWN
            Case Else:
                Print Mid$(subseq, k, 1); Asc(subseq, k)
        End Select
        num_seq(k - 1, 0) = i
        num_seq(k - 1, 1) = j
        i = j
    Next

    ReDim paths(0) As String
    Call Generate_Paths(paths(), num_seq(), dirpad_paths())

    S_best = 9223372036854775807

    For k = LBound(paths) To UBound(paths)
        S = Solve_Dirpad(paths(k), depth + 1, max_depth, K1(), K2(), V()) + _
            Solve_Dirpad(rest, depth, max_depth, K1(), K2(), V())

        If S < S_best Then S_best = S
    Next
    Call Hashmap_Insert(K1(), K2(), V(), seq, depth, S_best)
    Solve_Dirpad = S_best
End Function

Sub Generate_Paths (paths() As String, num_code() As Integer, P() As String)
    Dim code_length As Long
    code_length = UBound(num_code) - LBound(num_code) + 1
    Dim num_paths(code_length) As Long
    Dim As Long i, j, k, l, total_paths, t
    For k = LBound(num_code) To UBound(num_code)
        i = num_code(k, 0)
        j = num_code(k, 1)
        l = 0
        Do While P(i, j, l) <> ""
            l = l + 1
        Loop
        num_paths(k) = l
    Next
    Dim strides(code_length) As Long
    strides(code_length - 1) = 1
    total_paths = 1
    For k = 0 To code_length - 1
        total_paths = total_paths * num_paths(k)
    Next
    For k = code_length - 2 To 0 Step -1
        strides(k) = num_paths(k + 1) * strides(k + 1)
    Next
    ReDim paths(total_paths - 1) As String
    For t = 0 To total_paths - 1
        For k = code_length - 1 To 0 Step -1
            i = num_code(k, 0)
            j = num_code(k, 1)
            l = (t \ strides(k)) Mod num_paths(k)
            paths(t) = P(i, j, l) + paths(t)
        Next
    Next
End Sub

Sub Hashmap_Init (K1() As String, K2() As Integer, V() As _Integer64)
    ' K2(HASHMAP_CAPACITY) will contain the size
    ReDim K1(HASHMAP_CAPACITY) As String
    ReDim K2(HASHMAP_CAPACITY) As Integer
    ReDim V(HASHMAP_CAPACITY) As _Integer64
    Dim i As Integer
    For i = LBound(K2) To UBound(K2)
        K2(i) = -1
    Next
    K2(HASHMAP_CAPACITY) = 0
End Sub

Function Hashmap_Has% (K1() As String, K2() As Integer, _
    key1 As String, key2 As Integer)
    Dim As _Integer64 h
    h = Hash(key1, key2) Mod HASHMAP_CAPACITY
    Do While K2(h) >= 0
        If K1(h) = key1 And K2(h) = key2 Then
            Hashmap_Has = -1
            Exit Function
        End If
        h = (h + 1) Mod HASHMAP_CAPACITY
    Loop
    Hashmap_Has = 0
End Function

Sub Hashmap_Insert (K1() As String, K2() As Integer, V() As _Integer64, _
    key1 As String, key2 As Integer, value as _integer64)
    Dim As _Integer64 h
    If K2(HASHMAP_CAPACITY) = HASHMAP_CAPACITY Then
        Print "FATAL ERROR: Hashmap full!"
        System 1
    End If
    If key2 < 0 Then
        Print "FATAL ERROR: Tried to insert negative number!"
        System 1
    End If
    h = Hash(key1, key2) Mod HASHMAP_CAPACITY
    Do While K2(h) >= 0
        If K1(h) = key1 And K2(h) = key2 Then
            Print "FATAL ERROR: Key already in hashmap!"
            Print "K1: "; key1
            Print "K2: "; key2
            System 1
        End If
        h = (h + 1) Mod HASHMAP_CAPACITY
    Loop
    K1(h) = key1
    K2(h) = key2
    V(h) = value
    K2(HASHMAP_CAPACITY) = K2(HASHMAP_CAPACITY) + 1
End Sub

Function Hashmap_Get&& (K1() As String, K2() As Integer, V() As _Integer64, _
    key1 As String, key2 As Integer)
    Dim As _Integer64 h
    h = Hash(key1, key2) Mod HASHMAP_CAPACITY
    Do While K2(h) >= 0
        If K1(h) = key1 And K2(h) = key2 Then
            Hashmap_Get = V(h)
            Exit Function
        End If
        h = (h + 1) Mod HASHMAP_CAPACITY
    Loop
    Print "FATAL ERROR: Tried to get a non-existent value!"
    System 1
End Function


Function Jenkins&& (s As String)
    Dim As _Unsigned Long h, q
    Dim i As Integer
    h = 0
    For i = 1 To Len(s)
        q = Asc(s, i)
        h = h + q
        h = h + _ShL(h, 10)
        h = h Xor _ShR(h, 6)
    Next
    h = h + _ShL(h, 3)
    h = h Xor _ShR(h, 11)
    h = h + _ShL(h, 15)
    Jenkins = h
End Function

' hashes a string-integer pair
Function Hash (k1 As String, k2 As Integer)
    Dim As _Integer64 h
    h = 1830919229469034342 * k2
    h = _ShL(h, 32) Xor Jenkins(k1)
    Hash = h
End Function

