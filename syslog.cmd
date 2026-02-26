@echo off
title SPYRUS 6.4+2
color 0a

for /l %%i in (1,1,3) do (
    start "SECURITY ALERT %%i" cmd /c "color 4 && title SPYRUS v6.4+2 && echo. && echo [!] Unauthorized Access Detected... && echo. && echo Hacking Laptop... %%i%% && echo. && echo Accessing Camera... && echo Accessing Files... && echo Encrypting Data... && echo. && echo System Breached..! && echo. && pause > nul"
)

timeout /t 2 > nul
exit