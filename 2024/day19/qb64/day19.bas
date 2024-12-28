' Day19, variation on the classical "how many ways you can make change"
' problem, simple dynamic programming with memoization

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
Const HASHMAP_CAPACITY = 16384
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1
Dim As _Integer64 S2
Dim As Integer n_towels, n_designs, i, j, k

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

n_towels = 0
i = 1
Do While i > 0
    i = InStr(i + 1, lines(0), ", ")
    n_towels = n_towels + 1
Loop

Dim towels(n_towels - 1) As String
j = 1
k = InStr(lines(0), ", ")
For i = 0 To n_towels - 2
    towels(i) = Mid$(lines(0), j, k - j)
    j = k + 2
    k = InStr(j, lines(0), ", ")
Next
towels(n_towels - 1) = Mid$(lines(0), j)

n_designs = UBound(lines) - 1
Dim designs(n_designs - 1) As String
For i = LBound(designs) To UBound(designs)
    designs(i) = lines(i + 2)
Next


ReDim K(0) As String
ReDim V(0) As _Integer64
ReDim O(0) As Integer
Call Hashmap_Init(K(), V(), O())

Dim S As _Integer64
Dim design As String
S1 = 0
S2 = 0
For i = LBound(designs) To UBound(designs)
    design = designs(i)
    S = Solve(towels(), design, K(), V(), O())
    If S > 0 Then S1 = S1 + 1
    S2 = S2 + S
Next


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

' Implements Jenkins' one-at-a-time hash
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

' V(HASHMAP_CAPACITY) stores the size of the hashmap
Sub Hashmap_Init (K() As String, V() As _Integer64, O() As Integer)
    ReDim K(HASHMAP_CAPACITY)
    ReDim V(HASHMAP_CAPACITY)
    ReDim O(HASHMAP_CAPACITY)
    V(HASHMAP_CAPACITY) = 0
End Sub

Function Hashmap_Size&& (V() As _Integer64)
    Hashmap_Size = V(HASHMAP_CAPACITY)
End Function

Sub Hashmap_Insert (K() As String, V() As _Integer64, O() As Integer, ke As String, va As _Integer64)
    If Hashmap_Size(V()) = HASHMAP_CAPACITY Then
        Print "FATAL ERROR: Hashmap capacity exceeded!"
        System 1
    End If
    Dim As _Integer64 h
    h = Jenkins(ke) Mod HASHMAP_CAPACITY
    Do While O(h)
        If K(h) = ke Then
            Print "FATAL ERROR: Key already in hashmap!"
            System 1
        End If
        h = (h + 1) Mod HASHMAP_CAPACITY
    Loop
    K(h) = ke
    V(h) = va
    O(h) = -1
    V(HASHMAP_CAPACITY) = V(HASHMAP_CAPACITY) + 1
End Sub

Function Hashmap_Has% (K() As String, O() As Integer, ke As String)
    Dim As _Integer64 h
    h = Jenkins(ke) Mod HASHMAP_CAPACITY
    Do While O(h)
        If K(h) = ke Then
            Hashmap_Has = -1
            Exit Function
        End If
        h = (h + 1) Mod HASHMAP_CAPACITY
    Loop
    Hashmap_Has = 0
End Function

Function Hashmap_Get&& (K() As String, V() As _Integer64, O() As Integer, ke As String)
    Dim As _Integer64 h
    h = Jenkins(ke) Mod HASHMAP_CAPACITY
    Do While O(h)
        If K(h) = ke Then
            Hashmap_Get = V(h)
            Exit Function
        End If
        h = (h + 1) Mod HASHMAP_CAPACITY
    Loop
    Print "FATAL ERROR: Tried to get a key not in hashmap"
    System 1
End Function

Function Solve&& (towels() As String, design As String, K() As String, _
    V() As _Integer64, O() As Integer)
    If Len(design) = 0 Then
        Solve = 1
        Exit Function
    End If
    If Hashmap_Has(K(), O(), design) Then
        Solve = Hashmap_Get(K(), V(), O(), design)
        Exit Function
    End If
    Dim As _Integer64 S
    Dim As Integer i, l
    Dim As String towel
    S = 0
    For i = LBound(towels) To UBound(towels)
        towel = towels(i)
        l = Len(towel)
        If Left$(design, l) = towel Then
            S = S + Solve(towels(), Mid$(design, l + 1), K(), V(), O())
        End If
    Next
    Call Hashmap_Insert(K(), V(), O(), design, S)
    Solve = S
End Function


