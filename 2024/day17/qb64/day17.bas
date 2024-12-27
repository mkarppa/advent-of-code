' Day16, in part 1, simply simulate the operation of the computer
' In part 2, use backtracking search to recursively construct the quine
' program *starting from the end*

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
Const MAX_OUTPUT = 100
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As String S1
Dim As _Integer64 S2
Dim O(MAX_OUTPUT) As Integer
Dim As Integer i, j, k
Dim As _Integer64 A, B, C

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

A = Val(Mid$(lines(0), 13))
B = Val(Mid$(lines(1), 13))
C = Val(Mid$(lines(2), 13))
k = 0
i = 9
Do While i > 0
    i = InStr(i + 1, lines(4), ",")
    k = k + 1
Loop
Dim P(k - 1) As Integer
i = 9
For j = LBound(P) To UBound(P)
    P(j) = Val(Mid$(lines(4), i + 1))
    i = InStr(i + 1, lines(4), ",")
Next

Call Simulate(P(), A, B, C, O())

S1 = Mid$(Str$(O(0)), 2)
For i = 1 To UBound(O)
    If O(i) < 0 Then Exit For
    S1 = S1 + "," + Mid$(Str$(O(i)), 2)
Next

S2 = Solve2(P(), 0, B, C, O(), 0)

Print "Part 1: "; S1
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

' Simulate the execution of the computer until halt
' P is the program, A, B, C the initial register values, O stores the output
' Since output can only be 3-bit non-negative integers, end of output is
' signalled by -1
Sub Simulate (P() As Integer, Ai As _Integer64, Bi As _Integer64, _
    Ci As _Integer64, O() As Integer)
    Dim As _Integer64 A, B, C
    Dim As Integer ip, op, opcode, operand
    ip = 0
    op = 0
    A = Ai
    B = Bi
    C = Ci
    Do
        If ip > UBound(P) Then Exit Do ' halt
        opcode = P(ip)
        operand = P(ip + 1)
        ip = ip + 2
        Select Case opcode
            Case 0: ' adv
                A = _ShR(A, Combo(operand, A, B, C))
            Case 1: ' bxl
                B = B Xor (operand And &H7)
            Case 2: ' bst
                B = Combo(operand, A, B, C) And &H7
            Case 3: ' jnz
                If (A <> 0) Then ip = operand
            Case 4: ' bxc
                B = B Xor C
            Case 5: ' out
                O(op) = Combo(operand, A, B, C) And &H7
                op = op + 1
            Case 6: ' bdv
                B = _ShR(A, Combo(operand, A, B, C))
            Case 7: ' cdv
                C = _ShR(A, Combo(operand, A, B, C))
            Case Else:
                Print "Invalid opcode "; opcode
                System 1
        End Select
    Loop

    O(op) = -1
End Sub

' Select either an immediate value or one of the registers
Function Combo&& (operand As Integer, A As _Integer64, B As _Integer64, C As _Integer64)
    Select Case operand
        Case Is < 4:
            Combo = operand
        Case 4:
            Combo = A
        Case 5:
            Combo = B
        Case 6:
            Combo = C
        Case Else:
            Print "Invalid combo operand"; operand
            System 1
    End Select
End Function

Function Solve2&& (P() As Integer, Ai As _Integer64, B As _Integer64, _
    C As _Integer64, O() As Integer, i As Integer)
    If i > UBound(P) Then
        Solve2 = Ai
        Exit Function
    End If
    Dim As _Integer64 A1, A2, A
    Dim As Integer j, all_ok
    For A1 = 0 To 7
        A = _ShL(Ai, 3) Or A1
        Call Simulate(P(), A, B, C, O())
        all_ok = -1
        For j = 0 To i
            If P(UBound(P) - i + j) <> O(j) Then
                all_ok = 0
                Exit For
            End If
        Next
        If all_ok Then
            A2 = Solve2(P(), A, B, C, O(), i + 1)
            If A2 >= 0 Then
                Solve2 = A2
                Exit Function
            End If
        End If
    Next
    Solve2 = -1
End Function
