@echo off
:: ==============================================================================
:: GPG-Sign: Windows Batch Wrapper
:: ==============================================================================
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gpg-sign.ps1" %*
endlocal
