@echo off
:: ==============================================================================
:: WSL-IME Daemon: Windows Auto-Start Installer
::
:: File:        install-startup.bat
:: Description: Creates a Windows Startup shortcut pointing to
::              %LOCALAPPDATA%\wsl-ime\wsl-ime-daemon.exe so that the daemon
::              automatically and silently launches upon Windows login.
::
:: Usage:       Double-click install-startup.bat in Windows Explorer, or execute from CMD:
::              > install-startup.bat
::
:: License:     MIT License (see LICENSE file)
:: ==============================================================================

setlocal
pushd "%~dp0"

echo ===================================================
echo [WSL-IME] Installing Auto-Start on Windows Login
echo ===================================================

set LOCAL_DIR=%LOCALAPPDATA%\wsl-ime
if "%LOCAL_DIR%"=="" set LOCAL_DIR=%USERPROFILE%\AppData\Local\wsl-ime
set TARGET_EXE=%LOCAL_DIR%\wsl-ime-daemon.exe

:: Ensure the daemon binary is built and available locally
if not exist "%TARGET_EXE%" (
    echo [INFO] wsl-ime-daemon.exe not found in %LOCAL_DIR%. Compiling first...
    call build.bat
)

if not exist "%TARGET_EXE%" (
    echo [ERROR] Target binary %TARGET_EXE% not found! Installation aborted.
    pause
    popd
    exit /b 1
)

set STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
set SHORTCUT_PATH=%STARTUP_DIR%\wsl-ime-daemon.lnk

echo [INFO] Creating startup shortcut at:
echo        %SHORTCUT_PATH%

powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = '%TARGET_EXE%'; $s.WorkingDirectory = '%LOCAL_DIR%'; $s.Description = 'WSL IME Auto-Switch Background Daemon'; $s.Save()"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Auto-start shortcut installed successfully!
    echo [INFO] The daemon will now automatically launch upon Windows login.
    echo [INFO] Launching daemon now for the current session...
    start "" "%TARGET_EXE%"
) else (
    echo.
    echo [ERROR] Failed to create shortcut in Startup directory.
)

echo.
pause
popd
endlocal
