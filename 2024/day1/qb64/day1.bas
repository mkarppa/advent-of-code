' Day1, simple solution using counting sort

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

Dim start_time, end_time As Double
Dim a_list(999), b_list(999) As Long
Dim a_sorted(999), b_sorted(999) As Long
Dim a_counts(99999), b_counts(99999) As Integer

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename$ = Command$(1)

Open filename$ For Input As #1

n% = 0 ' number of lines
Do Until EOF(1)
    Input #1, a&, b&
    a_list(n%) = a&
    b_list(n%) = b&
    n% = n% + 1
Loop
Close #1

For i% = 0 To n% - 1
    a_counts(a_list(i%)) = a_counts(a_list(i%)) + 1
    b_counts(b_list(i%)) = b_counts(b_list(i%)) + 1
Next

ai% = 0
bi% = 0
For i& = 0 To UBound(a_counts)
    If a_counts(i&) > 0 Then
        For j% = 1 To a_counts(i&)
            a_sorted(ai%) = i&
            ai% = ai% + 1
        Next
    End If

    If b_counts(i&) > 0 Then
        For j% = 1 To b_counts(i&)
            b_sorted(bi%) = i&
            bi% = bi% + 1
        Next
    End If
Next

sum_part_1& = 0
For i% = 0 To n% - 1
    sum_part_1& = sum_part_1& + Abs(a_sorted(i%) - b_sorted(i%))
Next

sum_part_2& = 0
For i% = 0 To n% - 1
    sum_part_2& = sum_part_2& + a_sorted(i%) * b_counts(a_sorted(i%))
Next


Print "Part 1:"; sum_part_1&
Print "Part 2:"; sum_part_2&

end_time = Timer(0.001)

Print Using "Took ##.### s"; (end_time - start_time)

' Normal exit
System 0

' Abnormal exit
fail:
Print "Unhandled error code"; Err; "on line"; _ErrorLine; ": "; _ErrorMessage$
System 1
