@echo off
chcp 65001 >nul

:: ================= ARGUMENT ROUTING =================
if "%1"=="worker" goto worker
if "%1"=="final" goto final
if "%1"=="finalscreen" goto finalscreen

:: ================= MAIN =================
title SPYRUS
color 0c

for /l %%i in (1,1,4) do (
    start "SPYRUS NODE %%i" cmd /c "%~f0" worker %%i
)

:: Independent final trigger
start "" cmd /c "%~f0" final
exit


:: ================= WORKER =================
:worker
chcp 65001 >nul
color 0c
title SPYRUS NODE %2
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
echo ================= SPYRUS NODE %2 =================
echo.
echo Progress: !progress!%%
echo [!bar!]
echo.
timeout /t 1 >nul

if !progress! LSS 100 goto loop
exit


:: ================= FINAL =================
:final
timeout /t 22 >nul
start "" /max cmd /k "%~f0" finalscreen
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
echo.
echo %pad% SPYRUS ACTIVATED.
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
%pad% pause
%pad% exit