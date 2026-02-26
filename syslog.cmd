@echo off
chcp 65001 >nul

:: ================= ARGUMENT ROUTING =================
if "%1"=="worker" goto worker
if "%1"=="finalscreen" goto finalscreen

:: ================= MAIN =================
title SPYRUS
color 0c

set "tempdir=%temp%\spyrus"
if not exist "%tempdir%" mkdir "%tempdir%"
del "%tempdir%\done*.tmp" >nul 2>&1

:: Launch 4 workers – each sets UTF-8 before running
for /l %%i in (1,1,4) do (
    start "SPYRUS %%i" cmd /k "chcp 65001 >nul & call %~f0 worker %%i"   <<< FIXED
)

:: Wait until all 4 finish (silent loop)
:waitloop
timeout /t 1 >nul
set count=0
for %%f in ("%tempdir%\done*.tmp") do set /a count+=1
if %count% LSS 4 goto waitloop

:: Launch final screen – also with UTF-8 preset
start "" /max cmd /k "chcp 65001 >nul & call %~f0 finalscreen"           <<< FIXED
exit


:: ================= WORKER =================
:worker
chcp 65001 >nul
color 0c
title SPYRUS
mode con: cols=110 lines=35
cls

setlocal enabledelayedexpansion
set progress=0

:loop
set /a progress+=5
set bar=
set /a blocks=progress/5

for /l %%a in (1,1,!blocks!) do set bar=!bar!#

cls
echo.
echo   ██████  ██▓███ ▓██   ██▓ ██▀███   █    ██   ██████
echo ▒██    ▒ ▓██░  ██▒▒██  ██▒▓██ ▒ ██▒ ██  ▓██▒▒██    ▒
echo ░ ▓██▄   ▓██░ ██▓▒ ▒██ ██░▓██ ░▄█ ▒▓██  ▒██░░ ▓██▄
echo   ▒   ██▒▒██▄█▓▒ ▒ ░ ▐██▓░▒██▀▀█▄  ▓▓█  ░██░  ▒   ██▒
echo ▒██████▒▒▒██▒ ░  ░ ░ ██▒▓░░██▓ ▒██▒▒▒█████▓ ▒██████▒▒
echo ▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░  ██▒▒▒ ░ ▒▓ ░▒▓░░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░
echo ░ ░▒  ░ ░░▒ ░     ▓██ ░▒░   ░▒ ░ ▒░░░▒░ ░ ░ ░ ░▒  ░ ░
echo ░  ░  ░  ░░       ▒ ▒ ░░    ░░   ░  ░░░ ░ ░ ░  ░  ░
echo       ░           ░ ░        ░        ░           ░
echo                   ░ ░
echo.
echo ================= SPYRUS CORE %2 =================
echo.
echo Progress: !progress!%%
echo [!bar!]
echo.
timeout /t 1 >nul

if !progress! LSS 100 goto loop

:: Mark this worker as completed
echo done > "%temp%\spyrus\done%2.tmp"

exit


:: ================= FINAL SCREEN =================
:finalscreen
chcp 65001 >nul
color 0c
title SPYRUS CORE
mode con: cols=120 lines=40
cls

set "pad=                                                  "

echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo %pad%  ██████  ██▓███ ▓██   ██▓ ██▀███   █    ██   ██████
echo %pad% ▒██    ▒ ▓██░  ██▒▒██  ██▒▓██ ▒ ██▒ ██  ▓██▒▒██    ▒
echo %pad% ░ ▓██▄   ▓██░ ██▓▒ ▒██ ██░▓██ ░▄█ ▒▓██  ▒██░░ ▓██▄
echo %pad%   ▒   ██▒▒██▄█▓▒ ▒ ░ ▐██▓░▒██▀▀█▄  ▓▓█  ░██░  ▒   ██▒
echo %pad% ▒██████▒▒▒██▒ ░  ░ ░ ██▒▓░░██▓ ▒██▒▒▒█████▓ ▒██████▒▒
echo %pad% ▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░  ██▒▒▒ ░ ▒▓ ░▒▓░░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░
echo %pad% ░ ░▒  ░ ░░▒ ░     ▓██ ░▒░   ░▒ ░ ▒░░░▒░ ░ ░ ░ ░▒  ░ ░
echo %pad% ░  ░  ░  ░░       ▒ ▒ ░░    ░░   ░  ░░░ ░ ░ ░  ░  ░
echo %pad%       ░           ░ ░        ░        ░           ░
echo %pad%                   ░ ░
echo.
echo.
echo %pad% ################  SPYRUS CORE ONLINE  ################
echo.
echo %pad% ALL NODES COMPLETED SUCCESSFULLY
echo %pad% SYSTEM SYNCHRONIZATION: 100%%
echo %pad% STATUS: OPERATION COMPLETE
echo %pad% ENJOY BEING WAYCHED!
echo.
echo %pad% SPYRUS ACTIVATED 5.25+2.
echo.
echo.
echo.
%pad% pause
%pad% exit