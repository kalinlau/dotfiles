@echo off
:: ==============================================================================
:: GPG-Verify: Windows Batch Wrapper
:: ==============================================================================
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gpg-verify.ps1" %*
endlocal
