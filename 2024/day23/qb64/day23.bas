' Day23, Part 1 is brute force (just try all triples)
' For Part 2, we use Bron-Kerbosch, and this requires implementing a set data
' structure

' Require explicit variable declarations
Option _Explicit

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

' variable and constant declarations
Const SET_CAPACITY = 1024
Const HASHMAP_CAPACITY = 1024
Const MAX_LINES = 10000
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1
Dim As String S2
Dim As Integer i, j, u, v, n
Dim As String p, q
start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

ReDim S(0) As String
Call StrSet_Init(S())

For i = LBound(lines) To UBound(lines)
    p = Left$(lines(i), 2)
    q = Right$(lines(i), 2)
    Call StrSet_Add(S(), p)
    Call StrSet_Add(S(), q)
Next

' name to number
ReDim K(0) As String
ReDim V(0) As Integer
Call Hashmap_Init(K(), V())

n = StrSet_Size(S())
Dim Shared num_to_name(n - 1) As String
j = 0
For i = LBound(S) To UBound(S)
    If S(i) <> "" Then
        num_to_name(j) = S(i)
        Call Hashmap_Insert(K(), V(), S(i), j)
        j = j + 1
    End If
Next

Dim Shared G(n - 1, n - 1) As Integer
For i = LBound(lines) To UBound(lines)
    p = Left$(lines(i), 2)
    q = Right$(lines(i), 2)
    u = Hashmap_Get(K(), V(), p)
    v = Hashmap_Get(K(), V(), q)
    G(u, v) = 1
    G(v, u) = 1
Next

S1 = Solve1
S2 = Solve2

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

Sub Hashmap_Init (K() As String, V() As Integer)
    ReDim K(HASHMAP_CAPACITY - 1)
    ReDim V(HASHMAP_CAPACITY) ' last element contains size
End Sub

Sub Hashmap_Insert (K() As String, V() As Integer, ke As String, va As Integer)
    Dim As Integer h
    If V(HASHMAP_CAPACITY) = HASHMAP_CAPACITY Then
        Print "FATAL ERROR: Hashmap capacity exceeded!"
        System 1
    End If
    h = Jenkins(ke) Mod HASHMAP_CAPACITY
    Do While K(h) <> ""
        If K(h) = ke Then
            Print "FATAL ERROR: Tried to reinsert element in hash map!"
            System 1
        End If
        h = (h + 1) Mod SET_CAPACITY
    Loop
    K(h) = ke
    V(h) = va
    V(HASHMAP_CAPACITY) = V(HASHMAP_CAPACITY) + 1
End Sub

Function Hashmap_Get% (K() As String, V() As Integer, ke As String)
    Dim As Integer h
    h = Jenkins(ke) Mod HASHMAP_CAPACITY
    Do While K(h) <> ""
        If K(h) = ke Then
            Hashmap_Get = V(h)
            Exit Function
        End If
        h = (h + 1) Mod SET_CAPACITY
    Loop
    Print "FATAL ERROR: Tried to get a non-existent element from hash map!"
    System 1
End Function

' An IntSet is a simply an array of indicator variables
Sub IntSet_Init (S() As Integer)
    ReDim S(SET_CAPACITY)
    S(SET_CAPACITY) = 0
End Sub

Function IntSet_Has% (S() As Integer, e As Integer)
    IntSet_Has = S(e)
End Function

Sub IntSet_Add (S() As Integer, e As Integer)
    If Not S(e) Then
        S(e) = -1
        S(SET_CAPACITY) = S(SET_CAPACITY) + 1
    End If
End Sub

Sub IntSet_Remove (S() As Integer, e As Integer)
    If S(e) Then
        S(e) = 0
        S(SET_CAPACITY) = S(SET_CAPACITY) - 1
    End If
End Sub

Function IntSet_Is_Empty% (S() As Integer)
    IntSet_Is_Empty = S(UBound(S)) = 0
End Function

' Copies T to S
Sub IntSet_Copy (S() As Integer, T() As Integer)
    Dim As Integer i
    Call IntSet_Init(S())
    For i = LBound(S) To UBound(S)
        S(i) = T(i)
    Next
End Sub

' Computes S = T & U
Sub IntSet_Intersection (S() As Integer, T() As Integer, U() As Integer)
    Dim As Integer i, siz
    Call IntSet_Init(S())
    siz = 0
    For i = LBound(S) To UBound(S) - 1
        S(i) = T(i) And U(i)
        If S(i) Then siz = siz + 1
    Next
    S(UBound(S)) = siz
End Sub

Function IntSet_Size% (S() As Integer)
    IntSet_Size = S(SET_CAPACITY)
End Function

' an empty cell is denoted by an empty string
Sub StrSet_Init (S() As String)
    ReDim S(SET_CAPACITY - 1)
End Sub

Function StrSet_Has% (S() As String, k As String)
    Dim As Integer h
    h = Jenkins(k) Mod SET_CAPACITY
    Do While S(h) <> ""
        If S(h) = k Then
            StrSet_Has = -1
            Exit Function
        End If
        h = (h + 1) Mod SET_CAPACITY
    Loop
    StrSet_Has = 0
End Function

' Do nothing if k is already in S, otherwise add it
Sub StrSet_Add (S() As String, k As String)
    Dim As Integer i, h
    h = Jenkins(k) Mod SET_CAPACITY
    For i = 1 To SET_CAPACITY
        If S(h) = "" Then Exit For
        If S(h) = k Then Exit Sub
        h = (h + 1) Mod SET_CAPACITY
    Next
    If S(h) <> "" Then
        Print "FATAL ERROR: Set capacity exceeded!"
        System 1
    End If
    S(h) = k
End Sub

Function StrSet_Size% (S() As String)
    Dim As Integer siz, i
    siz = 0
    For i = LBound(S) To UBound(S)
        If S(i) <> "" Then siz = siz + 1
    Next
    StrSet_Size = siz
End Function

Function Solve1&& ()
    Dim As Integer u, v, w, ut, vt, wt
    Dim As _Integer64 S
    S = 0
    For u = LBound(G) To UBound(G) - 2
        ut = Asc(num_to_name(u), 1) = 116
        For v = u + 1 To UBound(G) - 1
            If G(u, v) = 1 Then
                vt = Asc(num_to_name(v), 1) = 116
                For w = v + 1 To UBound(G)
                    If G(u, w) And G(v, w) Then
                        wt = Asc(num_to_name(w), 1) = 116
                        If ut Or vt Or wt Then
                            S = S + 1
                        End If
                    End If
                Next
            End If
        Next
    Next
    Solve1 = S
End Function

Function Solve2$ ()
    ReDim As Integer all_nodes(0), empty_set(0), max_clique(0)
    Dim As Integer i, u
    Call IntSet_Init(all_nodes())
    Call IntSet_Init(empty_set())

    For u = LBound(G) To UBound(G)
        Call IntSet_Add(all_nodes(), u)
    Next

    Call Bron_Kerbosch(empty_set(), all_nodes(), empty_set(), max_clique())
    Dim S(IntSet_Size(max_clique()) - 1) As String
    i = 0
    For u = LBound(max_clique) To UBound(max_clique) - 1
        If max_clique(u) Then
            S(i) = num_to_name(u)
            i = i + 1
        End If
    Next
    Call Sort_String(S())
    Dim T As String
    T = S(0)
    For i = 1 To UBound(S)
        T = T + "," + S(i)
    Next
    Solve2 = T
End Function

Sub Get_Neighborhood (v As Integer, N() As _Unsigned Integer)
    Dim As Integer u
    Call IntSet_Init(N())
    For u = LBound(G) To UBound(G)
        If G(v, u) = 1 Then Call IntSet_Add(N(), u)
    Next
End Sub

Sub IntSet_Print (S() As Integer)
    Dim As Integer i, f
    f = -1
    Print "{";
    For i = LBound(S) To UBound(S) - 1
        If S(i) <> 0 Then
            If Not f Then
                Print ",";
            Else
                f = 0
            End If
            Print i;
        End If
    Next
    Print "}"
End Sub

' R() = pre-existing max clique
' P() = frontier (potential elements to add)
' X() = exclusion (known bad elements)
' max_clique() = out set (will be reassigned)
Sub Bron_Kerbosch (R() As Integer, P() As Integer, X() As Integer, _
    max_clique() As Integer)
    Dim As Integer v, max_size, clique_size
    If IntSet_Is_Empty(P()) And IntSet_Is_Empty(X()) Then
        Call IntSet_Copy(max_clique(), R())
        Exit Sub
    End If
    ReDim As Integer clique(0)
    Call IntSet_Init(clique())
    ReDim As Integer R2(0)
    ReDim As Integer P2(0)
    ReDim As Integer X2(0)
    Call IntSet_Copy(P2(), P())
    Call IntSet_Copy(X2(), X())

    ReDim As Integer P3(0)
    ReDim As Integer X3(0)
    ReDim As Integer N(0) ' neighborhood
    max_size = 0
    For v = LBound(G) To UBound(G)
        If P2(v) Then
            Call IntSet_Copy(R2(), R())
            Call IntSet_Add(R2(), v)
            ' R2 = R | {v}
            Call Get_Neighborhood(v, N())
            Call IntSet_Intersection(P3(), P2(), N())
            ' P3 = P & N(v)
            Call IntSet_Intersection(X3(), X2(), N())
            ' X3 = X & N(v)
            Call Bron_Kerbosch(R2(), P3(), X3(), clique())
            clique_size = IntSet_Size(clique())
            If clique_size > max_size Then
                Call IntSet_Copy(max_clique(), clique())
                max_size = clique_size
            End If
            Call IntSet_Remove(P2(), v)
            Call IntSet_Add(X2(), v)
        End If
    Next
End Sub

' Returns -1 if le is lexically before ri
'          0 if le is equal to ri
'          1 if le is lexically after ri
Function String_Compare% (le As String, ri As String)
    Dim As Integer i, n, l, r
    If Len(le) < Len(ri) Then
        n = Len(le)
    Else
        n = Len(ri)
    End If
    For i = 1 To n
        l = Asc(le, i)
        r = Asc(ri, i)
        If l < r Then String_Compare = -1: Exit Function
        If l > r Then String_Compare = 1: Exit Function
    Next
    If Len(le) < n Then String_Compare = -1: Exit Function
    If Len(ri) < n Then String_Compare = 1: Exit Function
    String_Compare = 0
End Function

Sub Sort_String (S() As String)
    Dim As Integer i, j
    For i = 1 To UBound(S)
        j = i
        Do
            If j = 0 Then Exit Do
            If String_Compare(S(j - 1), S(j)) <= 0 Then Exit Do
            Swap S(j), S(j - 1)
            j = j - 1
        Loop
    Next
End Sub
