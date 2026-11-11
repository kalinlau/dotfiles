@echo off
:: ==============================================================================
:: WSL-IME Daemon: Windows Stop Script
::
:: File:        stop-daemon.bat
:: Description: Gracefully signals the running wsl-ime-daemon to exit via its
::              TCP command interface, falling back to taskkill if necessary.
::
:: Usage:       Double-click stop-daemon.bat in Windows Explorer, or execute from CMD:
::              > stop-daemon.bat
::
:: License:     MIT License (see LICENSE file)
:: ==============================================================================

setlocal
pushd "%~dp0"

echo ===================================================
echo [WSL-IME] Stopping wsl-ime-daemon.exe
echo ===================================================

set LOCAL_DIR=%LOCALAPPDATA%\wsl-ime
set TARGET_EXE=%LOCAL_DIR%\wsl-ime-daemon.exe

if exist "%TARGET_EXE%" (
    echo [INFO] Sending graceful stop command via CLI...
    "%TARGET_EXE%" --stop
) else if exist "wsl-ime-daemon.exe" (
    wsl-ime-daemon.exe --stop
)

:: Terminate process tree directly in case of an unresponsive state
taskkill /f /im wsl-ime-daemon.exe >nul 2>nul
echo [SUCCESS] Daemon stopped.

popd
endlocal
