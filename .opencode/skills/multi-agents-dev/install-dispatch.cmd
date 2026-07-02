@echo off
setlocal
set "ROOT=%~dp0..\..\..\"
copy /Y "%~dp0dispatch.cmd" "%ROOT%" >nul
echo dispatch.cmd synced to project root
exit /b 0
