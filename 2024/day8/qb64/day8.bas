' Day8, Antinodes: Simply go through all pairs and place nodes at even
' intervals along the line; works coincidentally by properties of the input

' Require explicit variable declarations
Option _Explicit

' Set output to terminal instead of screen window
$Console:Only
_ScreenHide
_Console On
_Dest _Console

On Error GoTo fail

' variable declarations
Dim As Double start_time, end_time
Dim As String filename, lin
Dim As Integer n_antennae, n_rows, n_cols, i, j, c, f
Dim As Integer S1, S2
Dim As Integer A(230, 2), M1(50, 50), M2(50, 50), x(2), y(2), xy(2), z(2)


start_time = Timer(0.001)


If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename = Command$(1)

Open filename$ For Input As #1


n_antennae = 0
n_rows = 0
n_cols = 0

Do Until EOF(1)
    Line Input #1, lin
    n_cols = Len(lin)
    For i = 1 To n_cols
        c = Asc(lin, i)
        If c <> 46 Then
            A(n_antennae, 0) = n_rows
            A(n_antennae, 1) = i - 1
            A(n_antennae, 2) = c
            n_antennae = n_antennae + 1
        End If
    Next
    n_rows = n_rows + 1
Loop

Close #1

For i = 0 To n_antennae - 2
    x(0) = A(i, 0)
    x(1) = A(i, 1)
    f = A(i, 2)
    For j = i + 1 To n_antennae - 1
        If A(j, 2) = f Then
            y(0) = A(j, 0)
            y(1) = A(j, 1)
            xy(0) = y(0) - x(0)
            xy(1) = y(1) - x(1)

            ' z = y + xy
            z(0) = y(0) + xy(0)
            z(1) = y(1) + xy(1)
            If Is_Within%(z(), n_rows, n_cols) Then
                M1(z(0), z(1)) = 1
            End If

            ' z = x - xy
            z(0) = x(0) - xy(0)
            z(1) = x(1) - xy(1)
            If Is_Within%(z(), n_rows, n_cols) Then
                M1(z(0), z(1)) = 1
            End If

            ' z = y + t*xy
            z(0) = y(0)
            z(1) = y(1)
            While Is_Within%(z(), n_rows, n_cols)
                M2(z(0), z(1)) = 1
                z(0) = z(0) + xy(0)
                z(1) = z(1) + xy(1)
            Wend
            ' z = x - t*xy
            z(0) = x(0)
            z(1) = x(1)
            While Is_Within%(z(), n_rows, n_cols)
                M2(z(0), z(1)) = 1
                z(0) = z(0) - xy(0)
                z(1) = z(1) - xy(1)
            Wend
        End If
    Next
Next

S1 = 0
S2 = 0

For i = 0 To n_rows - 1
    For j = 0 To n_cols - 1
        S1 = S1 + M1(i, j)
        S2 = S2 + M2(i, j)
    Next
Next

Print "Part 1:"; S1
Print "Part 2:"; S2

end_time = Timer(0.001)

Print Using "Took ##.### s"; (end_time - start_time)

' Normal exit
System 0

' Abnormal exit
fail:
Print "Unhandled error code"; Err; "on line"; _ErrorLine; ": "; _ErrorMessage$
System 1


Function Is_Within% (z() As Integer, n_rows As Integer, n_cols As Integer)
    Is_Within% = z%(0) >= 0 And z%(0) < n_rows% And _
                  z%(1) >= 0 And z%(1) < n_cols
End Function

