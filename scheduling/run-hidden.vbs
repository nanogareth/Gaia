' run-hidden.vbs — Launch a command with no visible window
' Usage: wscript.exe run-hidden.vbs "C:\path\to\bash.exe" -l "C:\path\to\script.sh" args...
'
' Task Scheduler's "hidden" setting only hides the taskeng window,
' not child console windows. This VBS wrapper ensures bash runs
' completely invisible (intWindowStyle = 0).

Dim args, cmd, i
Set shell = CreateObject("WScript.Shell")

cmd = ""
For i = 0 To WScript.Arguments.Count - 1
    If i = 0 Then
        cmd = """" & WScript.Arguments(i) & """"
    Else
        arg = WScript.Arguments(i)
        If InStr(arg, " ") > 0 Then
            cmd = cmd & " """ & arg & """"
        Else
            cmd = cmd & " " & arg
        End If
    End If
Next

' 0 = hidden, False = don't wait for completion (Task Scheduler handles timeout)
shell.Run cmd, 0, True
