' Day25, Simply try all possible combinations and be happy

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
Dim As Double start_time, end_time
ReDim lines(MAX_LINES) As String
Dim As _Integer64 S1
Dim As Integer M(6, 4), N(4)
Dim As Integer i, j, k, n_keys, n_locks, s, max
Dim As Integer keys(1000, 4)
Dim As Integer locks(1000, 4)
start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

Call Read_Lines(Command$(1), lines())

For k = LBound(lines) To UBound(lines) Step 8
    For i = 0 To 6
        For j = 0 To 4
            Select Case Asc(lines(k + i), j + 1)
                Case 35: ' #
                    M(i, j) = -1
                Case 46: ' .
                    M(i, j) = 0
                Case Else:
                    Print "Invalid input!"
                    System 1
            End Select
        Next
    Next
    For j = 0 To 4
        s = 0
        For i = 0 To 6
            If M(i, j) Then s = s + 1
        Next
        N(j) = s
    Next
    If Is_Lock(M()) Then
        For j = 0 To 4
            locks(n_locks, j) = N(j)
        Next
        n_locks = n_locks + 1
    Else
        For j = 0 To 4
            keys(n_keys, j) = N(j)
        Next
        n_keys = n_keys + 1
    End If
Next

S1 = 0
For i = 0 To n_locks - 1
    For j = 0 To n_keys - 1
        max = 0
        For k = 0 To 4
            s = locks(i, k) + keys(j, k)
            If s > max Then max = s
        Next
        If max <= 7 Then S1 = S1 + 1
    Next
Next


Print "Part 1:"; S1

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

Function Is_Lock% (M() As Integer)
    Dim As Integer i, l
    l = -1
    For i = 0 To 4
        l = l And M(0, i)
    Next
    Is_Lock = l
End Function
