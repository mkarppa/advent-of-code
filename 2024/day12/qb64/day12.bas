' Day12, somewhat annoying; first extract plot with BFS, then compute
' perimeter (simply check the number of cells whose neighbors have different
' plants); for the number of sides, determine the number of corners by
' checking all 8 cases one by one

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
Dim As Long S1, S2
Dim As Integer n_rows, n_cols, i, j, plot_size, next_plot
Dim Shared M(141, 141) As Integer
Dim Shared V(141, 141) As Integer
Dim plot(1000, 2) As Integer

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename = Command$(1)

Open filename$ For Input As #1

Do Until EOF(1)
    Line Input #1, lin
    n_rows = n_rows + 1
    If n_cols = 0 Then n_cols = Len(lin)
    For i = 1 To n_cols
        M(n_rows, i) = Asc(lin, i)
    Next
Loop

Close #1

next_plot = 0
For i = 1 To n_rows
    For j = 1 To n_cols
        If V(i, j) = 0 Then
            ' we've not processed this plot
            next_plot = next_plot + 1
            Call Extract_Plot(i, j, next_plot, plot(), plot_size)
            S1 = S1 + Perimeter%(plot(), plot_size) * plot_size
            S2 = S2 + Count_Sides%(plot(), plot_size) * plot_size
        End If
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

' extracts a plot starting at some coordinates using BFS
' the size of the extracted plot is stored in plot_size
Sub Extract_Plot (i0 As Integer, j0 As Integer, plot_id As Integer, _
    plot() As Integer, plot_size As Integer)

    Dim As Integer q_start, q_size, q_capacity
    q_capacity = 100
    q_start = 0
    q_size = 0
    Dim Q(q_capacity, 1) As Integer
    Dim As Integer i, j, plant
    plant = M(i0, j0)

    Call Push_Q(i0, j0, Q(), q_start, q_size, q_capacity)
    plot_size = 0
    While q_size > 0
        Call Pop_Q(i, j, Q(), q_start, q_size)
        If V(i, j) = 0 Then
            plot(plot_size, 0) = i
            plot(plot_size, 1) = j
            plot_size = plot_size + 1
            V(i, j) = plot_id
            If V(i - 1, j) = 0 And M(i - 1, j) = plant Then
                Call Push_Q(i - 1, j, Q(), q_start, q_size, q_capacity)
            End If
            If V(i + 1, j) = 0 And M(i + 1, j) = plant Then
                Call Push_Q(i + 1, j, Q(), q_start, q_size, q_capacity)
            End If
            If V(i, j - 1) = 0 And M(i, j - 1) = plant Then
                Call Push_Q(i, j - 1, Q(), q_start, q_size, q_capacity)
            End If
            If V(i, j + 1) = 0 And M(i, j + 1) = plant Then
                Call Push_Q(i, j + 1, Q(), q_start, q_size, q_capacity)
            End If
        End If
    Wend
End Sub

Sub Push_Q (i As Integer, j As Integer, Q() As Integer, q_start As Integer, _
    q_size As Integer, q_capacity As Integer)
    Dim k As Integer
    If q_start + q_size = q_capacity Then
        For k = 0 To q_size - 1
            Q(k, 0) = Q(q_start + k, 0)
            Q(k, 1) = Q(q_start + k, 1)
        Next
        q_start = 0
    End If
    If q_start = 0 And q_size = q_capacity Then
        Print "FATAL ERROR: QUEUE AT CAPACITY"
    End If
    Q(q_start + q_size, 0) = i
    Q(q_start + q_size, 1) = j
    q_size = q_size + 1
End Sub

Sub Pop_Q (i As Integer, j As Integer, Q() As Integer, q_start As Integer, _
    q_size As Integer)
    If q_size = 0 Then
        Print "FATAL ERROR: POPPED EMPTY QUEUE"
    End If
    i = Q(q_start, 0)
    j = Q(q_start, 1)
    q_start = q_start + 1
    q_size = q_size - 1
End Sub

' Perimeter is the count of cells that neighbor a different plant
Function Perimeter% (plot() As Integer, plot_size As Integer)
    Dim As Integer i, j, k, plant, P
    i = plot(0, 0)
    j = plot(0, 1)
    plant = M(i, j)
    For k = 0 To plot_size - 1
        i = plot(k, 0)
        j = plot(k, 1)
        If M(i - 1, j) <> plant Then P = P + 1
        If M(i + 1, j) <> plant Then P = P + 1
        If M(i, j - 1) <> plant Then P = P + 1
        If M(i, j + 1) <> plant Then P = P + 1
    Next
    Perimeter% = P
End Function

' Determine all corners, this matches the number of sides
Function Count_Sides% (plot() As Integer, plot_size As Integer)
    Dim As Integer i, j, k, plant, S, dx, dy
    i = plot(0, 0)
    j = plot(0, 1)
    plant = M(i, j)
    S = 0
    For k = 0 To plot_size - 1
        i = plot(k, 0)
        j = plot(k, 1)
        For dx = -1 To 1 Step 2
            For dy = -1 To 1 Step 2
                If M(i + dy, j) <> plant And M(i, j + dx) <> plant Or _
                    M(i + dy, j) = plant And M(i, j + dx) = plant And M(i + dy, j + dx) <> plant Then
                    S = S + 1
                End If
            Next
        Next
    Next
    Count_Sides% = S
End Function
