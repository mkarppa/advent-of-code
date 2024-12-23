' Day11, simple dynamic programming, but need to implement a hash map

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
Dim As _Integer64 S1, S2
Dim As _Integer64 stones(8)
Dim As Integer i, j, n_stones

start_time = Timer(0.001)

If _CommandCount <> 1 Then
    Print "Usage: "; Command$(0); " <input.txt>"
    System 1
End If

filename = Command$(1)

Open filename$ For Input As #1

Do Until EOF(1)
    Line Input #1, lin

    i = 1
    For j = 1 To Len(lin)
        If Asc(lin, j) = 32 Then
            stones(n_stones) = Val(Mid$(lin, i, j - i))
            n_stones = n_stones + 1
            i = j + 1
        End If
    Next
    stones(n_stones) = Val(Mid$(lin, i))
    n_stones = n_stones + 1
Loop

Close #1

Dim Shared As _Integer64 size, capacity
size = 0
capacity = 1048576
Dim Shared keys(capacity) As _Integer64
Dim Shared values(capacity) As _Integer64
Dim Shared occupied(capacity) As Integer

For i = 0 To n_stones - 1
    S1 = S1 + Solve&&(stones(i), 25)
Next

For i = 0 To n_stones - 1
    S2 = S2 + Solve&&(stones(i), 75)
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

' Returns the bucket of the key or -1 if not found
Function Hashmap_Get_Bucket&& (K As _Integer64)
    Dim As _Integer64 h
    h = K Mod capacity
    While occupied(h)
        If keys(h) = K Then
            Hashmap_Get_Bucket&& = h
            Exit Function
        End If
        h = (h + 1) Mod capacity
    Wend
    Hashmap_Get_Bucket&& = -1
End Function


' Return -1 iff the key is in the hash map
Function Hashmap_Has% (K As _Integer64)
    Hashmap_Has% = Hashmap_Get_Bucket&&(K) >= 0
End Function

' insert or replace
Sub Hashmap_Insert (K As _Integer64, V As _Integer64)
    Dim As _Integer64 h
    If size = capacity Then
        Print "ERROR: HASHMAP AT CAPACITY"
    End If
    h = K Mod capacity
    While occupied(h)
        If keys(h) = K Then
            Exit While
        End If
        h = (h + 1) Mod capacity
    Wend
    If Not occupied(h) Then
        occupied(h) = -1
        size = size + 1
    End If
    keys(h) = K
    values(h) = V
End Sub

Function Hashmap_Get&& (K As _Integer64)
    Dim As _Integer64 h
    h = Hashmap_Get_Bucket&&(K)
    ' no sanity checking in case h is negative
    Hashmap_Get&& = values(h)
End Function

' Memoization is the key
Function Solve&& (stone As _Integer64, blinks As Integer)
    Dim As _Integer64 K
    K = _ShL(stone, 8) Or blinks
    If Hashmap_Has%(K) Then
        Solve&& = Hashmap_Get&&(K)
        Exit Function
    End If
    Dim As _Integer64 ret
    If blinks = 0 Then
        ret = 1
    ElseIf stone = 0 Then
        ret = Solve&&(1, blinks - 1)
    Else
        Dim ss As String
        Dim l As Integer
        ss = Mid$(Str$(stone), 2)
        l = Len(ss)
        If l Mod 2 = 0 Then
            Dim As _Integer64 le, ri
            le = Val(Mid$(ss, 1, l \ 2))
            ri = Val(Mid$(ss, l \ 2 + 1))
            ret = Solve&&(le, blinks - 1) + Solve&&(ri, blinks - 1)
        Else
            ret = Solve&&(stone * 2024, blinks - 1)
        End If
    End If
    Call Hashmap_Insert(K, ret)
    Solve&& = ret
End Function
