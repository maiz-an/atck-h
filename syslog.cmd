@echo off
title SYSTEM BREACHED 4.17+1
color 0a

for /l %%i in (1,1,3) do (
    start "SECURITY ALERT %%i" cmd /c "color 4 && title SYSTEM BREACHv3.16 && echo. && echo [!] Unauthorized Access Detected... && echo. && echo Hacking Laptop... %%i%% && echo. && echo Accessing Camera... && echo Accessing Files... && echo Encrypting Data... && echo. && echo System Breached..! && echo. && pause > nul"
)

timeout /t 2 > nul
exit