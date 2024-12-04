' Day3, no regex, just brutality

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

Open filename$ For Input As #1


mem$ = ""
Do Until EOF(1)
    Line Input #1, line$
    mem$ = mem$ + line$
Loop

Close #1

start% = 1
S1& = 0
Do
    start% = InStr(start%, mem$, "mul(")
    If start% = 0 Then
        Exit Do
    End If
    If Parse_Mul%(Mid$(mem$, start%), a%, b%) Then
        S1& = S1& + a% * b%
    End If
    start% = start% + 1
Loop

start% = 1
S2& = 0
should_mul% = -1
Do
    start% = Next_Entry%(mem$, start%)
    If start% = 0 Then
        Exit Do
    End If
    line$ = Mid$(mem$, start%)
    If Left$(line$, 4) = "do()" Then
        should_mul% = -1
    ElseIf Left$(line$, 7) = "don't()" Then
        should_mul% = 0
    ElseIf should_mul% And Parse_Mul%(line$, a%, b%) Then
        S2& = S2& + a% * b%
    End If
    start% = start% + 1
Loop

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

Function Next_Entry% (mem$, start%)
    a% = InStr(start%, mem$, "mul(")
    b% = InStr(start%, mem$, "do()")
    c% = InStr(start%, mem$, "don't()")
    If b% < a% Then
        d% = a%
        a% = b%
        b% = d%
    End If
    If c% < a% Then
        d% = a%
        a% = c%
        c% = d%
    End If
    If c% < b% Then
        d% = b%
        b% = c%
        c% = d%
    End If
    If a% = 0 And b% = 0 Then
        Next_Entry% = c%
    ElseIf a% = 0 Then
        Next_Entry% = b%
    Else
        Next_Entry% = a%
    End If
End Function

' Parses a string that looks like mul(123,456)
' returns -1 on success and sets a% and b%
' returns 0 on failure
Function Parse_Mul% (line$, a%, b%)
    If Left$(line$, 4) <> "mul(" Then
        Parse_Mul% = 0: Exit Function
    End If
    comma% = InStr(line$, ",")
    If comma% = 0 Or comma% > 8 Then
        Parse_Mul% = 0: Exit Function
    End If
    end_par% = InStr(comma%, line$, ")")
    If end_par% = 0 Or end_par% > comma% + 4 Then
        Parse_Mul% = 0: Exit Function
    End If
    a$ = Mid$(line$, 5, comma% - 5)
    b$ = Mid$(line$, comma% + 1, end_par% - comma% - 1)
    If All_Digits%(a$) And All_Digits%(b$) Then
        Parse_Mul% = -1
        a% = Val(a$)
        b% = Val(b$)
    Else
        Parse_Mul% = 0
    End If
End Function

' Returns -1 if all characters of the string are digits and 0 otherwise
Function All_Digits% (line$)
    For i% = 1 To Len(line$)
        a% = Asc(line$, i%)
        If a% < 48 Or a% > 57 Then
            All_Digits% = 0
            Exit Function
        End If
    Next
    All_Digits% = -1
End Function
