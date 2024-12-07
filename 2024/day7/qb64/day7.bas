' Day7, first non-trivial solution? Recursively look at options and
' cut infeasible branches

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

Dim start_time, end_time As Double

start_time = Timer(0.001)

Dim T&&(850) ' Target value
Dim L%(850) ' Number of values
Dim V%(850, 12) ' Values
Dim V_temp%(12)
Dim P1_T%(850) ' Part 1 condition satisfied

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename$ = Command$(1)

Open filename$ For Input As #1

n% = 0
Do Until EOF(1)
    Line Input #1, line$
    T&&(n%) = Val(line$)
    Call Split(Mid$(line$, InStr(line$, ":") + 2), " ", L%(n%), V_temp%())
    For j% = 0 To L%(n%) - 1
        V%(n%, j%) = V_temp%(j%)
    Next
    n% = n% + 1
Loop

Close #1

S1&& = 0
For i% = 0 To n% - 1
    If Solve%(T&&(i%), V%(i%, 0), V%(), i%, 1, L%(i%), 2) Then
        P1_T%(i%) = -1
        S1&& = S1&& + T&&(i%)
    End If
Next

S2&& = 0
For i% = 0 To n% - 1
    If P1_T%(i%) Then
        S2&& = S2&& + T&&(i%)
    ElseIf Solve%(T&&(i%), V%(i%, 0), V%(), i%, 1, L%(i%), 3) Then
        S2&& = S2&& + T&&(i%)
    End If
Next

Print "Part 1:"; S1&&
Print "Part 2:"; S2&&

end_time = Timer(0.001)

Print Using "Took ##.### s"; (end_time - start_time)

' Normal exit
System 0

' Abnormal exit
fail:
Print "Unhandled error code"; Err; "on line"; _ErrorLine; ": "; _ErrorMessage$
System 1

' Split string by delimiter and store integers in an array v%()
' Number of values is stored in n%
Sub Split (s$, delim$, n%, V%())
    i% = 1
    j% = InStr(s$, delim$)
    n% = 0

    While j% > 0
        V%(n%) = Val(Mid$(s$, i%, j% - i%))
        i% = j% + 1
        j% = InStr(i%, s$, delim$)
        n% = n% + 1
    Wend
    V%(n%) = Val(Mid$(s$, i%))
    n% = n% + 1
End Sub

' Returns -1 if the instance is solvable
' i% points to a row in the value array and j% to an element
' n% is the number of elements (number of columns)
' k% = 2 for first part, k% = 3 for second part
' Call like this: Solve%(t, V%(i%,0), 1, L%(i%), 2)
Function Solve% (t&&, S&&, V%(), i%, j%, n%, k%)
    If S&& > t&& Then
        Solve% = 0
        Exit Function
    End If
    If j% = n% Then
        Solve% = (S&& = t&&)
        Exit Function
    End If
    For l% = 1 To k%
        Select Case l%
            Case 1:
                If Solve%(t&&, S&& + V%(i%, j%), V%(), i%, j% + 1, n%, k%) Then
                    Solve% = -1
                    Exit Function
                End If
            Case 2:
                If Solve%(t&&, S&& * V%(i%, j%), V%(), i%, j% + 1, n%, k%) Then
                    Solve% = -1
                    Exit Function
                End If
            Case 3:
                Select Case V%(i%, j%)
                    Case Is >= 100:
                        Q&& = 1000 * S&&
                    Case Is >= 10:
                        Q&& = 100 * S&&
                    Case Else:
                        Q&& = 10 * S&&
                End Select
                Solve% = Solve%(t&&, Q&& + V%(i%, j%), V%(), i%, j% + 1, n%, k%)
        End Select
    Next
End Function


