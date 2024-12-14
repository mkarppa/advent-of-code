' Day9, Defrag: Not a very advanced solution, just iterate through all free
' blocks and see which one is the first sufficiently large

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
Dim As Long num_files, num_free_blocks, fs_size, i, j, c, sz, fsz
Dim As _Integer64 S1, S2
Dim file_blocks(10000, 2) As Long
Dim file_blocks_defrag(10000, 2) As Long
Dim free_blocks(10000, 2) As Long
Dim D1(100000) As Long
Dim D2(100000) As Long

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename = Command$(1)

Open filename$ For Input As #1

Do Until EOF(1)
    Line Input #1, lin
Loop

Close #1

num_files = 0
num_free_blocks = 0
fs_size = 0
For i = 1 To Len(lin)
    c = Asc(lin, i) - 48
    If i Mod 2 = 1 Then
        file_blocks(num_files, 0) = fs_size
        fs_size = fs_size + c
        file_blocks(num_files, 1) = fs_size
        num_files = num_files + 1
    Else
        free_blocks(num_free_blocks, 0) = fs_size
        fs_size = fs_size + c
        free_blocks(num_free_blocks, 1) = fs_size
        num_free_blocks = num_free_blocks + 1
    End If
Next

For i = 0 To fs_size - 1
    D1(i) = -1
Next
For i = 0 To num_files - 1
    For j = file_blocks(i, 0) To file_blocks(i, 1) - 1
        D1(j) = i
    Next
Next

i = 0
j = fs_size - 1
While i < j
    If D1(i) >= 0 Then
        i = i + 1
    ElseIf D1(j) < 0 Then
        j = j - 1
    Else
        Swap D1(i), D1(j)
        i = i + 1
        j = j - 1
    End If
Wend

S1 = 0
For i = 0 To fs_size - 1
    If D1(i) >= 0 Then
        S1 = S1 + D1(i) * i
    End If
Next

For i = num_files - 1 To 0 Step -1
    sz = file_blocks(i, 1) - file_blocks(i, 0)
    file_blocks_defrag(i, 0) = file_blocks(i, 0)
    file_blocks_defrag(i, 1) = file_blocks(i, 1)
    For j = 0 To num_free_blocks - 1
        If free_blocks(j, 0) >= file_blocks(i, 0) Then
            Exit For
        End If
        fsz = free_blocks(j, 1) - free_blocks(j, 0)
        If fsz >= sz Then
            file_blocks_defrag(i, 0) = free_blocks(j, 0)
            file_blocks_defrag(i, 1) = free_blocks(j, 0) + sz
            free_blocks(j, 0) = free_blocks(j, 0) + sz
            Exit For
        End If
    Next
Next

For i = 0 To fs_size - 1
    D2(i) = -1
Next
For i = 0 To num_files - 1
    For j = file_blocks_defrag(i, 0) To file_blocks_defrag(i, 1) - 1
        D2(j) = i
    Next
Next

S2 = 0
For i = 0 To fs_size - 1
    If D2(i) >= 0 Then
        S2 = S2 + D2(i) * i
    End If
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


Sub Print_FS (D() As Long, fs_size As Long)
    Dim As Long i
    For i = 0 To fs_size - 1
        If D(i) >= 0 Then
            Print Using "#"; D(i);
        Else
            Print ".";
        End If
    Next
    Print
End Sub
