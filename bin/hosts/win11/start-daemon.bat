@echo off
:: ==============================================================================
:: WSL-IME Daemon: Windows Startup Launcher
::
:: File:        start-daemon.bat
:: Description: Launches wsl-ime-daemon.exe from %LOCALAPPDATA%\wsl-ime\ in the
::              background. Automatically triggers build.bat if the binary is missing,
::              verifies process state via tasklist, and outputs diagnostic logs
::              if startup fails.
::
:: Usage:       Double-click start-daemon.bat in Windows Explorer, or execute from CMD:
::              > start-daemon.bat
::
:: License:     MIT License (see LICENSE file)
:: ==============================================================================

setlocal
pushd "%~dp0"

echo ===================================================
echo [WSL-IME] Starting wsl-ime-daemon.exe
echo ===================================================

set LOCAL_DIR=%LOCALAPPDATA%\wsl-ime
if "%LOCAL_DIR%"=="" set LOCAL_DIR=%USERPROFILE%\AppData\Local\wsl-ime
set TARGET_EXE=%LOCAL_DIR%\wsl-ime-daemon.exe

:: Ensure the daemon binary exists; compile if missing
if not exist "%TARGET_EXE%" (
    echo [INFO] wsl-ime-daemon.exe not found in %LOCAL_DIR%. Running build.bat first...
    call build.bat
)

if not exist "%TARGET_EXE%" (
    echo [ERROR] Target binary %TARGET_EXE% still not found!
    pause
    popd
    exit /b 1
)

:: Step 1: Terminate any existing instance to avoid port binding conflicts
echo [1/3] Stopping any running instance...
taskkill /f /im wsl-ime-daemon.exe >nul 2>nul
ping 127.0.0.1 -n 2 >nul

:: Step 2: Launch the daemon silently from local disk
echo [2/3] Launching %TARGET_EXE% ...
powershell -NoProfile -Command "Unblock-File -LiteralPath '%TARGET_EXE%' -ErrorAction SilentlyContinue"
start "" "%TARGET_EXE%"
ping 127.0.0.1 -n 2 >nul

:: Step 3: Verify the process is actively running in background
echo [3/3] Checking process status...
tasklist /fi "imagename eq wsl-ime-daemon.exe" | findstr /i "wsl-ime-daemon.exe" >nul
if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] wsl-ime-daemon.exe is RUNNING in background (Port 8765)!
    echo [INFO] Diagnostic log: %LOCAL_DIR%\daemon.log
) else (
    echo.
    echo [ERROR] wsl-ime-daemon.exe failed to start or exited immediately!
    echo ==================== daemon.log ====================
    if exist "%LOCAL_DIR%\daemon.log" (
        type "%LOCAL_DIR%\daemon.log"
    ) else (
        echo (daemon.log was not created. Process might have failed before Main)
    )
    echo ====================================================
)

echo.
pause
popd
endlocal
