@echo off
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0check-duplicates.ps1"
pause
