@echo off
cd /d "%~dp0"

powershell C:\Users\Utente\GHCPCLI-Local\copilot-local.ps1 -Backend ollama   -Model qwen3.6

pause
