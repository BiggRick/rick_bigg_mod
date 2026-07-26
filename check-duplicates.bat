@echo off
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0powershell\check-duplicates.ps1"
pause
