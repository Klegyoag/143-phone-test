@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUILD_PHONE_APK.ps1"
if errorlevel 1 (
  echo.
  echo APK BUILD FAILED. Read the error above.
  pause
  exit /b 1
)
echo.
echo APK BUILD COMPLETED.
pause
