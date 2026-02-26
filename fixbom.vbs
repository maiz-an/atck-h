' fixbom.vbs – Removes UTF‑8 BOM from syslog.cmd
Set fso = CreateObject("Scripting.FileSystemObject")
Set file = fso.OpenTextFile("syslog.cmd", 1)   ' 1 = ForReading
content = file.ReadAll
file.Close
Set out = fso.CreateTextFile("syslog.cmd.new", True, False)   ' False = no BOM
out.Write content
out.Close
MsgBox "Done! Rename syslog.cmd.new to syslog.cmd"