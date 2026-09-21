@echo off
setlocal

cd /d "%~dp0"
java -jar "C:\Games\Mods\IE\near-infinity-source\NearInfinity\NearInfinity.jar" --run-tool ImageSequenceToBam "input.json"
if errorlevel 1 (
  echo Conversion failed.
  exit /b 1
)

echo Created BAM from ImageSequenceToBam.json
endlocal
