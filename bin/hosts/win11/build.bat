@echo off
:: ==============================================================================
:: WSL-IME Daemon: Windows Build Script
::
:: File:        build.bat
:: Description: Compiles wsl-ime-daemon.cs into a standalone, windowless Windows
::              executable (wsl-ime-daemon.exe) using Microsoft .NET Framework's
::              built-in csc.exe compiler. Automatically copies the compiled binary
::              to %LOCALAPPDATA%\wsl-ime\ for persistent execution.
::
:: Usage:       Double-click build.bat in Windows Explorer, or execute from CMD:
::              > build.bat
::
:: Requirements: Windows 10/11 with .NET Framework 4.0+ (pre-installed by default).
:: License:     MIT License (see LICENSE file)
:: ==============================================================================

setlocal
pushd "%~dp0"

:: Resolve destination directory upfront outside if-blocks (avoids CMD block-expansion trap)
set LOCAL_DIR=%LOCALAPPDATA%\wsl-ime
if "%LOCAL_DIR%"=="" set LOCAL_DIR=%USERPROFILE%\AppData\Local\wsl-ime

echo ===================================================
echo [WSL-IME] Building wsl-ime-daemon.exe
echo [WSL-IME] Working Directory: %CD%
echo ===================================================

:: Step 1: Safely terminate any currently running daemon instance before recompiling
echo [1/3] Terminating any running instance...
taskkill /f /im wsl-ime-daemon.exe >nul 2>nul
ping 127.0.0.1 -n 2 >nul

:: Step 2: Locate csc.exe in standard 64-bit or 32-bit .NET Framework paths
echo [2/3] Checking C# compiler (csc.exe)...
set CSC_PATH=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe

if not exist "%CSC_PATH%" (
    set CSC_PATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe
)

if not exist "%CSC_PATH%" (
    echo [ERROR] csc.exe not found in Microsoft.NET Framework directories!
    pause
    popd
    exit /b 1
)

echo [INFO] Found compiler at: %CSC_PATH%

if not exist "wsl-ime-daemon.cs" (
    echo [ERROR] Cannot find wsl-ime-daemon.cs in %CD%!
    pause
    popd
    exit /b 1
)

:: Step 3: Compile into a windowless Win32 GUI executable (/target:winexe)
echo [3/3] Compiling wsl-ime-daemon.cs ...
"%CSC_PATH%" /nologo /target:winexe /optimize+ /out:wsl-ime-daemon.exe wsl-ime-daemon.cs

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] wsl-ime-daemon.exe compiled successfully!

    :: Step 4: Perform Authenticode Code Signing & Unblock Mark-of-the-Web
    echo [4/4] Performing Authenticode code signing...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sign-binary.ps1" -FilePath "wsl-ime-daemon.exe"
    
    :: Install signed binary to %LOCAL_DIR% for permanent host execution
    if not exist "%LOCAL_DIR%" mkdir "%LOCAL_DIR%"
    copy /y "wsl-ime-daemon.exe" "%LOCAL_DIR%\wsl-ime-daemon.exe" >nul
    powershell -NoProfile -Command "Unblock-File -LiteralPath '%LOCAL_DIR%\wsl-ime-daemon.exe' -ErrorAction SilentlyContinue"
    echo [INFO] Installed signed binary to: %LOCAL_DIR%\wsl-ime-daemon.exe
) else (
    echo.
    echo [ERROR] Compilation failed with error code %ERRORLEVEL%!
)

echo.
pause
popd
endlocal
