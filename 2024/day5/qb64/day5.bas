' Day5, insertion sort style

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

Dim C%(99, 99)
Dim U%(200, 30) ' index 0 contains length
Dim ok%(200)
n% = 0 ' number of updates

Open filename$ For Input As #1

Do Until EOF(1)
    Line Input #1, line$
    i% = InStr(line$, "|")
    If i% > 0 Then
        a% = Val(line$)
        b% = Val(Mid$(line$, i% + 1))
        C%(a%, b%) = -1
        C%(b%, a%) = 1
    End If
    i% = InStr(line$, ",")
    If i% > 0 Then
        j% = 1
        U%(n%, j%) = Val(line$)
        While i% > 0
            line$ = Mid$(line$, i% + 1)
            j% = j% + 1
            U%(n%, j%) = Val(line$)
            i% = InStr(line$, ",")
        Wend
        U%(n%, 0) = j%
        n% = n% + 1
    End If
Loop

Close #1

S1% = 0
S2% = 0

For i% = 0 To n% - 1
    ok%(i%) = -1
    For j% = 1 To U%(i%, 0) - 1
        x% = U%(i%, j%)
        For k% = j% To U%(i%, 0)
            y% = U%(i%, k%)
            If C%(x%, y%) > 0 Then
                ok%(i%) = 0
                Exit For
            End If
        Next
        If Not ok%(i%) Then
            Exit For
        End If
    Next
    If ok%(i%) Then
        S1% = S1% + U%(i%, U%(i%, 0) \ 2 + 1)
    End If
Next

For i% = 0 To n% - 1
    If Not ok%(i%) Then
        For j% = 2 To U%(i%, 0)
            k% = j%
            While k% > 1 And C%(U%(i%, k% - 1), U%(i%, k%)) > 0
                x% = U%(i%, k%)
                U%(i%, k%) = U%(i%, k% - 1)
                U%(i%, k% - 1) = x%
                k% = k% - 1
            Wend
        Next
        S2% = S2% + U%(i%, U%(i%, 0) \ 2 + 1)
    End If
Next

Print "Part 1:"; S1%
Print "Part 2:"; S2%

end_time = Timer(0.001)

Print Using "Took ##.### s"; (end_time - start_time)

' Normal exit
System 0

' Abnormal exit
fail:
Print "Unhandled error code"; Err; "on line"; _ErrorLine; ": "; _ErrorMessage$
System 1


