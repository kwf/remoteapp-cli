
@echo off
setlocal

set "SCRIPT=%~dp0remoteapp.ps1"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%
