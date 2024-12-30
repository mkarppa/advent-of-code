' Day22, Fairly simple: implement pseudorandom number generator according to
' specs, then find the best subsequence with one pass over the data

' Require explicit variable declarations
Option _Explicit

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

' variable and constant declarations
Const HASHMAP_CAPACITY_BIG = 65536
Const HASHMAP_CAPACITY_SMALL = 4096
Const HASHMAP_OCCUPIED = -1
Const HASHMAP_UNOCCUPIED = 0
Const MAX_LINES = 10000
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1, S2
Dim As Long i, j, k, h
start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

Dim As Long prices(LBound(lines) To UBound(lines), 2000)
Dim As Long K(HASHMAP_CAPACITY_BIG) ' this hashmap stores accumulated best prices
Dim As Integer V(HASHMAP_CAPACITY_BIG)
Dim As Integer O(HASHMAP_CAPACITY_BIG)
Call Hashmap_Init(K(), O())
Dim seq(3) As Integer
S1 = 0
' this hashmap only stores whether the monkey's seen the particular sequence
Dim Seen_K(HASHMAP_CAPACITY_SMALL) As Long
Dim Seen_V(HASHMAP_CAPACITY_SMALL) As Integer
Dim Seen_O(HASHMAP_CAPACITY_SMALL) As Integer
For i = LBound(lines) To UBound(lines)
    Call Hashmap_Init(Seen_K(), Seen_O())

    prices(i, 0) = Val(lines(i))
    For j = 1 To 2000
        prices(i, j) = Next_Num(prices(i, j - 1))
    Next
    S1 = S1 + prices(i, 2000)
    prices(i, 0) = prices(i, 0) Mod 10
    For j = 1 To 3
        prices(i, j) = prices(i, j) Mod 10
        seq(j) = prices(i, j) - prices(i, j - 1)
    Next
    For j = 4 To 2000
        For k = 0 To 2
            seq(k) = seq(k + 1)
        Next
        prices(i, j) = prices(i, j) Mod 10
        seq(3) = prices(i, j) - prices(i, j - 1)
        If Not Hashmap_Has(Seen_K(), Seen_O(), seq()) Then
            Call Hashmap_Insert(Seen_K(), Seen_V(), Seen_O(), seq())
            If Not Hashmap_Has(K(), O(), seq()) Then
                Call Hashmap_Insert(K(), V(), O(), seq())
            End If
            h = Hashmap_Get_Index(K(), O(), seq())
            V(h) = V(h) + prices(i, j)
        End If
    Next
Next

Dim As Integer best_i, best_bananas
best_bananas = -1
For i = LBound(V) To UBound(V)
    If O(i) <> HASHMAP_UNOCCUPIED And V(i) > best_bananas Then
        best_i = i
        best_bananas = V(i)
    End If
Next
S2 = best_bananas

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

Function Next_Num& (seed As Long)
    Dim As _Integer64 h
    h = (seed Xor _ShL(seed, 6)) And &HFFFFFF
    h = (h Xor _ShR(h, 5)) And &HFFFFFF
    h = (h Xor _ShL(h, 11)) And &HFFFFFF
    Next_Num = h
End Function

' Sequences are four 5-bit integers
' (values are in -9,-8,...,8,9)
' so we compress them into *positive* 32-bit keys
Function Compress_Sequence& (seq() As Integer)
    Compress_Sequence = _ShL(seq(0) + 10, 15) Or _ShL(seq(1) + 10, 10) Or _
        _ShL(seq(2) + 10, 5) Or (seq(3)+10)
End Function

Sub Decompress_Sequence (seq() As Integer, ke As Long)
    Dim i As Integer
    For i = 0 To 3
        seq(i) = (_ShR(ke, 5 * i) And &H1F) - 10
    Next
End Sub

' Simple multiplication hash
Function Hash&& (ke As Long)
    Dim h As _Unsigned _Integer64
    h = 4248265258435570399 * ke
    Hash = _ShR(h, 32)
End Function

' an empty cell is denoted by a negative value
Sub Hashmap_Init (K() As Long, O() As Integer)
    ' Last element of K will contain the size
    Dim i As Long
    For i = LBound(K) To UBound(K)
        O(i) = HASHMAP_UNOCCUPIED
    Next
    K(UBound(K)) = 0
End Sub

' Returns the value index of the key if it exists in the hashmap
' Otherwise returns -1
Function Hashmap_Get_Index& (K() As Long, O() As Integer, seq() As Integer)
    Dim As Long h, ke, i, capacity
    capacity = UBound(K)
    ke = Compress_Sequence(seq())
    h = Hash(ke) Mod capacity
    For i = 1 To capacity
        If O(h) = HASHMAP_UNOCCUPIED Then
            Exit For
        ElseIf K(h) = ke Then
            Hashmap_Get_Index = h
            Exit Function
        Else
            h = (h + 1) Mod capacity
        End If
    Next
    Hashmap_Get_Index = -1
End Function

Function Hashmap_Has% (K() As Long, O() As Integer, seq() As Integer)
    Hashmap_Has = Hashmap_Get_Index(K(), O(), seq()) <> -1
End Function

' Insert a *new* key into the hashmap with value 0
Sub Hashmap_Insert (K() As Long, V() As Integer, O() As Integer, seq() As Integer)
    Dim As Long h, ke, capacity
    capacity = UBound(K)
    If K(capacity) = capacity Then
        Print "FATAL ERROR: Hashmap full!"
        System 1
    End If
    ke = Compress_Sequence(seq())
    h = Hash(ke) Mod capacity
    Do While O(h) = HASHMAP_OCCUPIED
        If K(h) = ke Then
            Print "FATAL ERROR: Key already in hashmap!"
            System 1
        End If
        h = (h + 1) Mod capacity
    Loop
    K(h) = ke
    V(h) = 0
    O(h) = HASHMAP_OCCUPIED
    K(capacity) = K(capacity) + 1
End Sub

Function Hashmap_Get&& (K() As Long, V() As _Integer64, O() As Integer, seq() As Integer)
    Dim As _Integer64 h
    h = Hashmap_Get_Index(K(), O(), seq())
    If h = -1 Then
        Print "FATAL ERROR: Tried to get a non-existent value!"
        System 1
    End If
    Hashmap_Get = V(h)
End Function


