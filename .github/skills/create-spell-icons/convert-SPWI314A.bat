@echo off
setlocal

cd /d "%~dp0"
java -cp "NearInfinity.jar" org.infinity.cli.ImageSequenceToBam "input.json"
if errorlevel 1 (
  echo Conversion failed.
  exit /b 1
)

echo Created BAM from input.json
endlocal
