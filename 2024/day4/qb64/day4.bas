' Day4, brutal if statements

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

Dim start_time, end_time As Double

start_time = Timer(0.001)


If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename$ = Command$(1)

Dim X%(146, 146)

Open filename$ For Input As #1

num_cols% = 0
num_rows% = 0

' X = 88
' M = 77
' A = 65
' S = 83

Do Until EOF(1)
    Line Input #1, line$
    num_rows% = num_rows% + 1
    num_cols% = Len(line$)
    For i% = 1 To num_cols%
        Select Case Asc(line$, i%)
            Case 88:
                X%(num_rows% + 3, i% + 3) = 1
            Case 77:
                X%(num_rows% + 3, i% + 3) = 2
            Case 65:
                X%(num_rows% + 3, i% + 3) = 3
            Case 83:
                X%(num_rows% + 3, i% + 3) = 4
        End Select
    Next
Loop

Close #1

S1& = 0
S2& = 0
For i% = 4 To num_rows% + 3
    For j% = 4 To num_cols% + 3
        If X%(i%, j%) = 1 Then
            If X%(i%, j% + 1) = 2 And X%(i%, j% + 2) = 3 And X%(i%, j% + 3) = 4 Then
                S1& = S1& + 1
            End If
            If X%(i%, j% - 1) = 2 And X%(i%, j% - 2) = 3 And X%(i%, j% - 3) = 4 Then
                S1& = S1& + 1
            End If
            If X%(i% + 1, j%) = 2 And X%(i% + 2, j%) = 3 And X%(i% + 3, j%) = 4 Then
                S1& = S1& + 1
            End If
            If X%(i% - 1, j%) = 2 And X%(i% - 2, j%) = 3 And X%(i% - 3, j%) = 4 Then
                S1& = S1& + 1
            End If
            If X%(i% + 1, j% + 1) = 2 And X%(i% + 2, j% + 2) = 3 And X%(i% + 3, j% + 3) = 4 Then
                S1& = S1& + 1
            End If
            If X%(i% + 1, j% - 1) = 2 And X%(i% + 2, j% - 2) = 3 And X%(i% + 3, j% - 3) = 4 Then
                S1& = S1& + 1
            End If
            If X%(i% - 1, j% + 1) = 2 And X%(i% - 2, j% + 2) = 3 And X%(i% - 3, j% + 3) = 4 Then
                S1& = S1& + 1
            End If
            If X%(i% - 1, j% - 1) = 2 And X%(i% - 2, j% - 2) = 3 And X%(i% - 3, j% - 3) = 4 Then
                S1& = S1& + 1
            End If
        End If
        If X%(i%, j%) = 3 Then
            If X%(i% - 1, j% - 1) = 2 And X%(i% + 1, j% + 1) = 4 And _
                X%(i% - 1, j% + 1) = 2 And X%(i% + 1, j% - 1) = 4 Then
                S2& = S2& + 1
            End If
            If X%(i% - 1, j% - 1) = 2 And X%(i% + 1, j% + 1) = 4 And _
                X%(i% - 1, j% + 1) = 4 And X%(i% + 1, j% - 1) = 2 Then
                S2& = S2& + 1
            End If
            If X%(i% - 1, j% - 1) = 4 And X%(i% + 1, j% + 1) = 2 And _
                X%(i% - 1, j% + 1) = 2 And X%(i% + 1, j% - 1) = 4 Then
                S2& = S2& + 1
            End If
            If X%(i% - 1, j% - 1) = 4 And X%(i% + 1, j% + 1) = 2 And _
                X%(i% - 1, j% + 1) = 4 And X%(i% + 1, j% - 1) = 2 Then
                S2& = S2& + 1
            End If
        End If
    Next
Next

Print "Part 1:"; S1&
Print "Part 2:"; S2&

end_time = Timer(0.001)

Print Using "Took ##.### s"; (end_time - start_time)

' Normal exit
System 0

' Abnormal exit
fail:
Print "Unhandled error code"; Err; "on line"; _ErrorLine; ": "; _ErrorMessage$
System 1


