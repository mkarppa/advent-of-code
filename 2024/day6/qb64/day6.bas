' Day6, basically brute force except only checking the path found in part a

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

Dim M%(131, 131) ' map: 0 empty, 1 obstacle, -1 outside
Dim V%(131, 131) ' visited: direction or -1 for unvisited
' Directions: 1 north, 2 east, 4 south, 8 west
n_rows% = 0
n_cols% = 0
initial_i% = -1
initial_j% = -1
initial_dir% = 1

Open filename$ For Input As #1

Do Until EOF(1)
    Line Input #1, line$
    n_cols% = Len(line$)
    n_rows% = n_rows% + 1
    For j% = 1 To n_cols%
        Select Case Asc(line$, j%)
            Case 46: M%(n_rows%, j%) = 0
            Case 35: M%(n_rows%, j%) = 1
            Case 94:
                M%(n_rows%, j%) = 0
                initial_i% = n_rows%
                initial_j% = j%
        End Select
    Next
Loop

Close #1

For i% = 0 To n_rows% + 1
    M%(i%, 0) = -1
    M%(i%, n_cols% + 1) = -1
Next
For j% = 0 To n_cols% + 1
    M%(0, j%) = -1
    M%(n_rows% + 1, j%) = -1
Next

i% = Guard_Loop%(M%(), V%(), initial_i%, initial_j%, initial_dir%)

Dim ii%(4600)
Dim jj%(4600)

S1% = Extract_Positives%(V%(), n_rows%, n_cols%, ii%(), jj%())
S2% = 0

For k% = 0 To S1% - 1
    Call Clear_V(V%(), n_rows%, n_cols%)
    i% = ii%(k%)
    j% = jj%(k%)
    M%(i%, j%) = 1
    l% = Guard_Loop%(M%(), V%(), initial_i%, initial_j%, initial_dir%)
    M%(i%, j%) = 0

    If l% Then
        S2% = S2% + 1
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

' Sets all elements to 0
Sub Clear_V (V%(), n_rows%, n_cols%)
    For i% = 1 To n_rows%
        For j% = 1 To n_cols%
            V%(i%, j%) = 0
        Next
    Next
End Sub

' Returns -1 if the guard loops, otherwise 0 and sets the elements of V% to
' match the direction the guard was pointing when entering the cell
Function Guard_Loop% (M%(), V%(), initial_i%, initial_j%, initial_dir%)
    cur_i% = initial_i%
    cur_j% = initial_j%
    cur_dir% = initial_dir%
    While M%(cur_i%, cur_j%) >= 0
        If (V%(cur_i%, cur_j%) And cur_dir%) = cur_dir% Then
            Guard_Loop% = -1
            Exit Function
        End If
        V%(cur_i%, cur_j%) = (V%(cur_i%, cur_j%) Or cur_dir%)
        Call Next_IJ(next_i%, next_j%, cur_i%, cur_j%, cur_dir%)
        While M%(next_i%, next_j%) = 1
            If cur_dir% < 8 Then
                cur_dir% = cur_dir% * 2
            Else
                cur_dir% = 1
            End If
            Call Next_IJ(next_i%, next_j%, cur_i%, cur_j%, cur_dir%)
        Wend
        cur_i% = next_i%
        cur_j% = next_j%
    Wend
    Guard_Loop% = 0
End Function

Sub Next_IJ (next_i%, next_j%, cur_i%, cur_j%, cur_dir%)
    Select Case cur_dir%
        Case 1:
            next_i% = cur_i% - 1
            next_j% = cur_j%
        Case 2:
            next_i% = cur_i%
            next_j% = cur_j% + 1
        Case 4:
            next_i% = cur_i% + 1
            next_j% = cur_j%
        Case 8:
            next_i% = cur_i%
            next_j% = cur_j% - 1
    End Select
End Sub

' Returns the count and stores the indices in ii% and jj%
Function Extract_Positives% (V%(), n_rows%, n_cols%, ii%(), jj%())
    S% = 0
    For i% = 1 To n_rows%
        For j% = 1 To n_cols%
            If V%(i%, j%) > 0 Then
                ii%(S%) = i%
                jj%(S%) = j%
                S% = S% + 1
            End If
        Next
    Next
    Extract_Positives% = S%
End Function

