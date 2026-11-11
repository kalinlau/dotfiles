@echo off
:: ==============================================================================
:: WSL-IME Daemon: Windows Firewall Rule Helper
::
:: File:        add-firewall-rule.bat
:: Description: Requests Administrator elevation (via UAC) and configures an inbound
::              Windows Defender Firewall rule to allow TCP port 8765. Essential
::              for WSL2 Mirrored Networking (networkingMode=Mirrored).
::
:: Usage:       Right-click and "Run as administrator", or double-click to elevate:
::              > add-firewall-rule.bat
::
:: License:     MIT License (see LICENSE file)
:: ==============================================================================

setlocal

echo ===================================================
echo [WSL-IME] Windows Firewall Configuration (Port 8765)
echo ===================================================

:: Check if current execution context has Administrator privileges
net session >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [INFO] Running with Administrator privileges. Adding firewall rule...
    netsh advfirewall firewall add rule name="WSL-IME-8765" dir=in action=allow protocol=TCP localport=8765 profile=any
    echo.
    echo [SUCCESS] Windows Firewall rule 'WSL-IME-8765' added successfully!
) else (
    echo [INFO] Administrative rights required. Requesting UAC elevation...
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c netsh advfirewall firewall add rule name=\"\"WSL-IME-8765\"\" dir=in action=allow protocol=TCP localport=8765 profile=any & echo. & echo [SUCCESS] Firewall rule added! & echo. & pause' -Verb RunAs"
)

echo.
pause
endlocal
