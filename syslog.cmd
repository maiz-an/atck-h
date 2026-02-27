@echo off
title SPYRUS 6.7+2
color 0a

for /l %%i in (1,1,6) do (
    start "SECURITY ALERT %%i" cmd /c "color 4 && title SPYRUS v6.7+2 && echo. && echo [!] SPYRUS Started && echo. && echo Breaching Device... && echo. && echo Accessing Camera... && echo Accessing Files... && echo Sending Payloads... && echo Accessing from C:\Program Files\Adobe... && echo. && echo System Breached..! && echo. && pause > nul"
)

timeout /t 2 > nul
exit