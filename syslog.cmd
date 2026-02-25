@echo off
title SYSTEM BREACH DETECTED
color 0a

for /l %%i in (1,1,50) do (
    start "SECURITY ALERT %%i" cmd /k "color 4 && title CRITICAL ERROR %%i && echo. && echo [!] Unauthorized Access Detected... && echo. && echo Hacking Laptop... %%i%% && echo. && echo Accessing Camera... && echo Accessing Files... && echo Encrypting Data... && echo. && echo DO NOT TURN OFF YOUR COMPUTER! && echo. && echo Press any key to attempt recovery... && pause > nul"
)

timeout /t 2 > nul
pause
exit
