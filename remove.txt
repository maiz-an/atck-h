schtasks | findstr Syslog
schtasks | findstr Task
schtasks | findstr Updater
schtasks | findstr Launcher
schtasks /query /tn SyslogUpdater /v /fo list

schtasks /delete /tn "SyslogUpdater" /f
rmdir /s /q "%APPDATA%\SysCache"
type "%APPDATA%\SysCache\debug.log"