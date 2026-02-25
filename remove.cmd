@echo off
echo Stopping any running prank processes...
taskkill /f /im "cmd.exe" /fi "WINDOWTITLE eq syslog.cmd" >nul 2>&1
taskkill /f /im "cmd.exe" /fi "WINDOWTITLE eq updater.cmd" >nul 2>&1

echo Deleting scheduled task "SyslogUpdater"...
schtasks /delete /tn "SyslogUpdater" /f >nul 2>&1

echo Removing files from %%APPDATA%%\SysCache...
rmdir /s /q "%APPDATA%\SysCache" >nul 2>&1

echo Done. The SysCache folder and scheduled task have been removed.
pause