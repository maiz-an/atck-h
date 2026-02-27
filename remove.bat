@echo off
title SPYRUS Cleanup Tool
echo =====================================
echo   SPYRUS Removal Script
echo =====================================
echo.

echo [1/4] Stopping related cmd processes...
taskkill /f /im "cmd.exe" /fi "WINDOWTITLE eq syslog.cmd" >nul 2>&1
taskkill /f /im "cmd.exe" /fi "WINDOWTITLE eq updater.cmd" >nul 2>&1

echo [2/4] Deleting scheduled task "SyslogUpdater"...
schtasks /query /tn "SyslogUpdater" >nul 2>&1
if %errorlevel%==0 (
    schtasks /delete /tn "SyslogUpdater" /f >nul 2>&1
    echo Task removed successfully.
) else (
    echo Task not found.
)

echo [3/4] Removing %%APPDATA%%\SysCache folder...
if exist "%APPDATA%\SysCache" (
    if exist "%APPDATA%\SysCache\debug.log" (
        echo.
        echo --- Debug Log Found ---
        type "%APPDATA%\SysCache\debug.log"
        echo -----------------------
        echo.
    )
    rmdir /s /q "%APPDATA%\SysCache"
    echo Folder removed.
) else (
    echo SysCache folder not found.
)

echo [4/4] SPYRUS Cleanup complete.
echo.
echo Done.
pause