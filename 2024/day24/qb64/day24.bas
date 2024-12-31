' Day24, Part 1 is simple dynamic programming
' Part 2 is basically manual labor

' Require explicit variable declarations
Option _Explicit

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

' variable and constant declarations
Const NULL_GATE = 0 ' NULL gates only provide constant output
Const OR_GATE = 1
Const XOR_GATE = 2
Const AND_GATE = 3
Const HASHMAP_CAPACITY = 1024
Const MAX_LINES = 10000
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1
Dim As String S2, ou, op, in1, in2
Dim As Integer i, j, max_x, max_y, max_z
start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

' Variable to index mapping
ReDim K(0) As String
ReDim V(0) As Integer
Call Hashmap_Init(K(), V())

max_x = 0
max_y = 0
max_z = 0

' Collect variables
For i = LBound(lines) To UBound(lines)
    If Len(lines(i)) = 0 Then _Continue
    If Asc(lines(i), 4) = 58 Then
        in1 = Left$(lines(i), 3)
        Call Hashmap_Insert(K(), V(), in1, Hashmap_Size(V()))
        Select Case Asc(in1, 1)
            Case 120:
                j = Val(Mid$(in1, 2))
                If j > max_x Then max_x = j
            Case 121:
                j = Val(Mid$(in1, 2))
                If j > max_y Then max_y = j
        End Select
    Else
        in1 = Left$(lines(i), 3)
        j = InStr(5, lines(i), " ")
        in2 = Mid$(lines(i), j + 1, 3)
        ou = Right$(lines(i), 3)
        If Not Hashmap_Has(K(), in1) Then
            Call Hashmap_Insert(K(), V(), in1, Hashmap_Size(V()))
        End If
        If Not Hashmap_Has(K(), in2) Then
            Call Hashmap_Insert(K(), V(), in2, Hashmap_Size(V()))
        End If
        If Not Hashmap_Has(K(), ou) Then
            Call Hashmap_Insert(K(), V(), ou, Hashmap_Size(V()))
        End If
        If Asc(ou, 1) = 122 Then
            j = Val(Mid$(ou, 2))
            If j > max_z Then max_z = j
        End If
    End If
Next

' index arrays for finding relevant gates
Dim Shared As Integer X(max_x), Y(max_y), Z(max_z)
' for transforming indices back to strings
Dim Shared As String N(Hashmap_Size(V()) - 1)

For i = LBound(K) To UBound(K)
    If K(i) <> "" Then
        N(V(i)) = K(i)
        If Asc(K(i), 1) >= 120 And Asc(K(i), 1) <= 122 Then
            j = Val(Mid$(K(i), 2))
            If Asc(K(i), 1) = 120 Then X(j) = V(i)
            If Asc(K(i), 1) = 121 Then Y(j) = V(i)
            If Asc(K(i), 1) = 122 Then Z(j) = V(i)
        End If
    End If
Next

' Gates
Dim Shared As Integer G(Hashmap_Size(V()) - 1, 3)

' Go through the data again and now construct the gates
For i = LBound(lines) To UBound(lines)
    If Len(lines(i)) = 0 Then _Continue
    If Asc(lines(i), 4) = 58 Then
        in1 = Left$(lines(i), 3)
        j = Hashmap_Get(K(), V(), in1)
        G(j, 0) = Val(Mid$(lines(i), 6))
        G(j, 1) = NULL_GATE
        G(j, 2) = -1
        G(j, 3) = -1
    Else
        in1 = Left$(lines(i), 3)
        j = InStr(5, lines(i), " ")
        op = Mid$(lines(i), 5, j - 5)
        in2 = Mid$(lines(i), j + 1, 3)
        ou = Right$(lines(i), 3)
        j = Hashmap_Get(K(), V(), ou)
        G(j, 0) = -1
        G(j, 2) = Hashmap_Get(K(), V(), in1)
        G(j, 3) = Hashmap_Get(K(), V(), in2)
        Select Case op
            Case "OR":
                G(j, 1) = OR_GATE
            Case "XOR":
                G(j, 1) = XOR_GATE
            Case "AND":
                G(j, 1) = AND_GATE
            Case Else:
                Print "Invalid operation!"
                System 1
        End Select
    End If
Next

S1 = Solve1(max_z)

If max_x = max_y And max_x + 1 = max_z Then
    S2 = Solve2(max_z)
Else
    Print "Part 2 cannot be solved for this input."
End If

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
        h = (h + 1) Mod HASHMAP_CAPACITY
    Loop
    K(h) = ke
    V(h) = va
    V(HASHMAP_CAPACITY) = V(HASHMAP_CAPACITY) + 1
End Sub

Function Hashmap_Has% (K() As String, ke As String)
    Dim As Integer h
    h = Jenkins(ke) Mod HASHMAP_CAPACITY
    Do While K(h) <> ""
        If K(h) = ke Then
            Hashmap_Has = -1
            Exit Function
        End If
        h = (h + 1) Mod HASHMAP_CAPACITY
    Loop
    Hashmap_Has = 0
End Function

Function Hashmap_Get% (K() As String, V() As Integer, ke As String)
    Dim As Integer h
    h = Jenkins(ke) Mod HASHMAP_CAPACITY
    Do While K(h) <> ""
        If K(h) = ke Then
            Hashmap_Get = V(h)
            Exit Function
        End If
        h = (h + 1) Mod HASHMAP_CAPACITY
    Loop
    Print "FATAL ERROR: Tried to get a non-existent element from hash map!"
    System 1
End Function

Function Hashmap_Size% (V() As Integer)
    Hashmap_Size = V(HASHMAP_CAPACITY)
End Function

' formats variables like x09 with a leading zero
Function Format_Var$ (prefix As String, i As Integer)
    If i < 10 Then
        Format_Var = prefix + "0" + Right$(Str$(i), 1)
    Else
        Format_Var = prefix + Right$(Str$(i), 2)
    End If
End Function

Function Rec% (var As Integer)
    If G(var, 0) = -1 Then
        Select Case G(var, 1)
            Case OR_GATE:
                G(var, 0) = Rec(G(var, 2)) Or Rec(G(var, 3))
            Case XOR_GATE:
                G(var, 0) = Rec(G(var, 2)) Xor Rec(G(var, 3))
            Case AND_GATE:
                G(var, 0) = Rec(G(var, 2)) And Rec(G(var, 3))
            Case Else:
                Print "Invalid operation!"
                System 1
        End Select
    End If
    Rec = G(var, 0)
End Function

Function Solve1&& (max_z As Integer)
    Dim i As Integer
    Dim S As _Integer64
    S = 0
    For i = 0 To max_z
        S = S Or _ShL(Rec(Z(i)), i)
    Next
    Solve1 = S
End Function

' Finds the gate index or -1 if no such gate exists
' in1/in2 are unordered
Function Find_Gate% (op As Integer, in1 As Integer, in2 As Integer)
    Dim As Integer i
    For i = LBound(G, 1) To UBound(G, 1)
        If G(i, 1) = op Then
            If G(i, 2) = in1 And G(i, 3) = in2 Or _
                G(i, 3) = in1 And G(i, 2) = in2 Then
                Find_Gate = i
                Exit Function
            End If
        End If
    Next
    Find_Gate = -1
End Function

Function Solve2$ (max_z As Integer)
    ' Construct the *correct* ripple carry adder and find mistakes in the
    ' circuit
    ' The errors have been identified manually which means this is not a
    ' general-purpose solution
    Dim As String swapped(7) ' we have promise of exactly 4 swapped pairs
    Dim As Integer n_swapped, xi, yi, zi, carry, xixoryi, i, xiandyi
    Dim As Integer xixoryixorc, xixoryiandc, next_carry
    Dim As String S

    ' We start with a half-adder
    xi = X(0)
    yi = Y(0)

    ' z00 = x00 XOR y00
    xixoryi = Find_Gate(XOR_GATE, xi, yi)
    ' carry from half adder is C = x00 AND y00
    carry = Find_Gate(AND_GATE, xi, yi)
    If xixoryi <> Z(0) Then
        Print "HALF-ADDER FAILED UNEXPECTEDLY"
        System 1
    End If

    For i = 1 To max_z - 1
        xi = X(i)
        yi = Y(i)
        zi = Z(i)

        ' xi XOR yi
        xixoryi = Find_Gate(XOR_GATE, xi, yi)
        ' xi AND yi
        xiandyi = Find_Gate(AND_GATE, xi, yi)

        ' zi = (xi XOR yi) XOR C if the circuit is correct
        xixoryixorc = Find_Gate(XOR_GATE, xixoryi, carry)

        ' If we cannot find the output, then xi XOR yi is probably switched
        ' with xi AND yi
        If xixoryixorc = -1 Then
            If G(zi, 1) = XOR_GATE Then
                If G(zi, 2) = xiandyi And G(zi, 3) = carry Or _
                    G(zi, 3) = xiandyi And G(zi, 2) = carry Then
                    ' Fix the circuit and note the swapped gates
                    swapped(n_swapped) = N(xixoryi)
                    swapped(n_swapped + 1) = N(xiandyi)
                    n_swapped = n_swapped + 2
                    Call Swap_Gates(xixoryi, xiandyi)
                    xixoryi = Find_Gate(XOR_GATE, xi, yi)
                    xiandyi = Find_Gate(AND_GATE, xi, yi)
                    xixoryixorc = Find_Gate(XOR_GATE, xixoryi, carry)
                End If
            End If
        End If

        ' (xi XOR yi) AND C
        xixoryiandc = Find_Gate(AND_GATE, xixoryi, carry)
        ' next carry is
        ' C' = ((xi XOR yi) AND C) OR (xi AND yi)
        next_carry = Find_Gate(OR_GATE, xixoryiandc, xiandyi)


        If xixoryixorc <> zi Then
            If next_carry = zi Then
                ' carry and output have been switched
                swapped(n_swapped) = N(next_carry)
                swapped(n_swapped + 1) = N(xixoryixorc)
                n_swapped = n_swapped + 2
                Call Swap_Gates(xixoryixorc, next_carry)
                xixoryixorc = Find_Gate(XOR_GATE, xixoryi, carry)
                next_carry = Find_Gate(OR_GATE, xixoryiandc, xiandyi)
            ElseIf zi = xiandyi Then
                ' xi AND yi has been swapped with output
                swapped(n_swapped) = N(xiandyi)
                swapped(n_swapped + 1) = N(xixoryixorc)
                n_swapped = n_swapped + 2
                Call Swap_Gates(xixoryixorc, xiandyi)
                xixoryixorc = Find_Gate(XOR_GATE, xixoryi, carry)
                xiandyi = Find_Gate(AND_GATE, xi, yi)
                ' carry is also affected
                next_carry = Find_Gate(OR_GATE, xixoryiandc, xiandyi)
            ElseIf zi = xixoryiandc Then
                ' (xi XOR yi) XOR C has been swapped with (xi XOR yi) AND C
                swapped(n_swapped) = N(xixoryiandc)
                swapped(n_swapped + 1) = N(xixoryixorc)
                n_swapped = n_swapped + 2
                Call Swap_Gates(xixoryixorc, xixoryiandc)
                xixoryixorc = Find_Gate(XOR_GATE, xixoryi, carry)
                xixoryiandc = Find_Gate(AND_GATE, xixoryi, carry)
                ' carry is also affected
                next_carry = Find_Gate(OR_GATE, xixoryiandc, xiandyi)
            Else
                Print "FULL ADDER FAILED UNEXPECTEDLY"
                System 1
            End If
        End If
        carry = next_carry
    Next
    ' z45 should be the last carry
    If Z(UBound(Z)) <> carry Then
        Print "LAST OUTPUT FAILED UNEXPECTEDLY"
        System 1
    End If
    Call Sort_String(swapped())
    S = swapped(0)
    For i = 1 To UBound(swapped)
        S = S + "," + swapped(i)
    Next
    Solve2 = S
End Function

Sub Swap_Gates (le As Integer, ri As Integer)
    Dim As Integer j
    For j = 0 To 3
        Swap G(le, j), G(ri, j)
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

