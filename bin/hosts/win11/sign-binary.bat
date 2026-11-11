@echo off
:: ==============================================================================
:: WSL-IME Daemon: Authenticode Code Signing Batch Wrapper
::
:: File:        sign-binary.bat
:: Description: Invokes sign-binary.ps1 to generate a self-signed code signing
::              certificate for "LAU Kalin", configure trust, embed digital
::              signature into wsl-ime-daemon.exe, and unblock network flags.
::
:: Usage:       Double-click sign-binary.bat, or run from CMD:
::              > sign-binary.bat [optional-file-path]
::
:: License:     MIT License (see LICENSE file)
:: ==============================================================================

setlocal
pushd "%~dp0"

echo [WSL-IME] Running Authenticode Code Signing...

set TARGET_FILE=%~1
if "%TARGET_FILE%"=="" (
    set TARGET_FILE=wsl-ime-daemon.exe
)

if not exist "%TARGET_FILE%" (
    echo [ERROR] Target file '%TARGET_FILE%' not found!
    echo [INFO] Running build.bat first...
    call build.bat
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sign-binary.ps1" -FilePath "%TARGET_FILE%"

echo.
pause
popd
endlocal
