' Day2, simple brute force solution

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

Dim start_time, end_time As Double

start_time = Timer(0.001)

Dim report(10) As Integer
Dim report2(10) As Integer

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename$ = Command$(1)

Open filename$ For Input As #1

sum_part_1% = 0
sum_part_2% = 0

Do Until EOF(1)
    Line Input #1, line$
    Print line$
    Call Extract_Integers(line$, " ", report(), n%)
    If is_safe%(n%, report()) Then
        sum_part_1% = sum_part_1% + 1
        sum_part_2% = sum_part_2% + 1
    Else
        For i% = 0 To n% - 1
            k% = 0
            For j% = 0 To n% - 1
                If j% <> i% Then
                    report2(k%) = report(j%)
                    k% = k% + 1
                End If
            Next
            If is_safe%(n% - 1, report2()) Then
                sum_part_2% = sum_part_2% + 1
                Exit For
            End If
        Next
    End If
Loop

Close #1

Print "Part 1:"; sum_part_1%
Print "Part 2:"; sum_part_2%

end_time = Timer(0.001)

Print Using "Took ##.### s"; (end_time - start_time)

' Normal exit
System 0

' Abnormal exit
fail:
Print "Unhandled error code"; Err; "on line"; _ErrorLine; ": "; _ErrorMessage$
System 1

Sub Extract_Integers (line$, delimiter$, integers%(), n%)
    n% = 0
    i% = 1
    j% = InStr(i%, line$, delimiter$)
    While j% > 0
        integers%(n%) = Val(Mid$(line$, i%, j% - i%))
        n% = n% + 1
        i% = j% + 1
        j% = InStr(i%, line$, delimiter$)
    Wend
    integers%(n%) = Val(Mid$(line$, i%))
    n% = n% + 1
End Sub

Function is_safe% (n%, report%())
    sign% = Sgn(report%(0) - report%(1))
    For i% = 0 To n% - 2
        diff% = report%(i%) - report%(i% + 1)
        If Sgn(diff%) <> sign% Or Abs(diff%) > 3 Then
            is_safe% = 0
            Exit Function
        End If
    Next
    is_safe% = -1
End Function
