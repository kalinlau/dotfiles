<#
.SYNOPSIS
    Launches or restarts the WSL-IME background daemon in Windows.

.DESCRIPTION
    start-daemon.ps1 ensures that wsl-ime-daemon.exe is compiled, installs it
    into %LOCALAPPDATA%\wsl-ime\, stops any stale instance, launches the daemon
    in the background, and verifies process health.

.EXAMPLE
    .\start-daemon.ps1

.NOTES
    File:    start-daemon.ps1
    Author:  Jialin Liu (LAU Kalin) <laukalin24@gmail.com>
    License: MIT License (see LICENSE file)
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -LiteralPath $ScriptDir

$LocalDir = "$env:LOCALAPPDATA\wsl-ime"
$TargetExe = "$LocalDir\wsl-ime-daemon.exe"
$LogFile = "$LocalDir\daemon.log"

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "[WSL-IME] PowerShell Daemon Starter" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. Stop any currently running instance to prevent port collisions
Write-Host "[1/3] Stopping any running wsl-ime-daemon instance..." -ForegroundColor Gray
Get-Process -Name "wsl-ime-daemon" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# 2. Check if compilation is required
if (-not (Test-Path -LiteralPath $TargetExe)) {
    Write-Host "[INFO] wsl-ime-daemon.exe not found in $LocalDir. Building now..." -ForegroundColor Yellow
    $csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    if (-not (Test-Path $csc)) {
        $csc = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    }
    if (-not (Test-Path $csc)) {
        Write-Error "csc.exe compiler not found in Microsoft.NET Framework directories!"
        return
    }
    
    $csFile = Join-Path $ScriptDir "wsl-ime-daemon.cs"
    New-Item -ItemType Directory -Force -Path $LocalDir | Out-Null
    
    & $csc /nologo /target:winexe /optimize+ "/out:$TargetExe" "$csFile"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Compilation failed with exit code $LASTEXITCODE"
        return
    }
    Write-Host "[SUCCESS] Compiled binary to $TargetExe" -ForegroundColor Green
}

# 3. Launch daemon process
Write-Host "[2/3] Starting $TargetExe in background..." -ForegroundColor Gray
Start-Process -FilePath $TargetExe

Start-Sleep -Milliseconds 800

# 4. Confirm process status
$proc = Get-Process -Name "wsl-ime-daemon" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "`n[SUCCESS] wsl-ime-daemon is RUNNING! (PID: $($proc.Id))" -ForegroundColor Green
    Write-Host "[INFO] Listening on TCP port 8765" -ForegroundColor Gray
    Write-Host "[INFO] Diagnostic log: $LogFile" -ForegroundColor Gray
} else {
    Write-Host "`n[ERROR] Daemon process exited immediately!" -ForegroundColor Red
    if (Test-Path -LiteralPath $LogFile) {
        Write-Host "=== Recent daemon.log output ===" -ForegroundColor Yellow
        Get-Content -Path $LogFile -Tail 20
        Write-Host "===============================" -ForegroundColor Yellow
    }
}
