<#
.SYNOPSIS
    General-Purpose Anti-Tamper Checksum & GPG Signing Tool for Windows (PowerShell).

.DESCRIPTION
    gpg-sign.ps1 computes SHA-256 hashes for specified files (supporting globs)
    and signs the manifest using GnuPG (gpg.exe) into a cleartext signed manifest
    (default: SHA256SUMS.asc).

.PARAMETER Patterns
    Array of file paths or glob patterns to include in the signature manifest.

.PARAMETER Output
    Destination path or directory for the signed manifest (default: .\SHA256SUMS.asc).

.PARAMETER Key
    GPG Key ID or email to sign with.

.EXAMPLE
    .\gpg-sign.ps1 -Patterns "hosts\win11\*.*" -Output "hosts\win11\"
    .\gpg-sign.ps1 -Patterns "*.bat","*.ps1","*.exe"

.NOTES
    Author:  Jialin Liu (LAU Kalin) <laukalin24@gmail.com>
    License: MIT License
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromRemainingArguments = $true)]
    [string[]]$Patterns,

    [Alias("o")]
    [string]$Output = ".\SHA256SUMS.asc",

    [Alias("u")]
    [string]$Key = ""
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command "gpg" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] 'gpg.exe' not found in PATH! Please install Gpg4win or Git GnuPG." -ForegroundColor Red
    exit 1
}

if (-not $Patterns -or $Patterns.Count -eq 0) {
    Write-Host "[ERROR] No input files or glob patterns specified." -ForegroundColor Red
    Write-Host "Usage: gpg-sign.ps1 [-Output <path>] [-Key <id>] <Patterns...>" -ForegroundColor Yellow
    exit 1
}

# Resolve output path
$targetFile = $Output
$targetDir = "."

if (Test-Path -LiteralPath $Output -PathType Container -ErrorAction SilentlyContinue) {
    $targetDir = (Resolve-Path -LiteralPath $Output).Path
    $targetFile = Join-Path $targetDir "SHA256SUMS.asc"
} else {
    $parent = Split-Path -Parent $Output
    if ($parent) {
        $targetDir = $parent
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
        }
    }
}

$targetFullPath = [System.IO.Path]::GetFullPath($targetFile)

# Expand input patterns
$resolvedFiles = @()
foreach ($pat in $Patterns) {
    try {
        $items = Get-ChildItem -Path $pat -File -Recurse:$false -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            if ($item.FullName -ne $targetFullPath -and -not $item.Name.EndsWith(".asc")) {
                $resolvedFiles += $item
            }
        }
    } catch { }
}

# Deduplicate by FullName
$uniqueFiles = $resolvedFiles | Sort-Object -Property FullName -Unique

if ($uniqueFiles.Count -eq 0) {
    Write-Host "[ERROR] No matching files found for specified pattern(s)." -ForegroundColor Red
    exit 1
}

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "[GPG-Sign] Anti-Tamper Checksum & Signature (Windows)" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "[INFO] Output: $targetFullPath" -ForegroundColor Gray
Write-Host "[INFO] Files to sign: $($uniqueFiles.Count) file(s)" -ForegroundColor Gray

# Compute SHA-256 hashes
Write-Host "`n[1/2] Computing SHA-256 hashes..." -ForegroundColor Yellow
$hashLines = @()

foreach ($file in $uniqueFiles) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower()
    
    # Use relative path if file is within targetDir
    $displayPath = $file.Name
    if ($targetDir -ne "." -and $file.FullName.StartsWith($targetDir)) {
        $displayPath = $file.FullName.Substring($targetDir.Length).TrimStart("\", "/")
    } else {
        $displayPath = $file.FullName
    }
    
    $line = "$hash  $displayPath"
    $hashLines += $line
    Write-Host "  [OK] $displayPath ($hash)" -ForegroundColor Green
}

# Write temp checksum file
$tempFile = [System.IO.Path]::GetTempFileName()
$hashLines | Out-File -LiteralPath $tempFile -Encoding ascii

try {
    Write-Host "`n[2/2] Generating OpenPGP Cleartext Signature with GPG..." -ForegroundColor Yellow
    $gpgArgs = @("--yes", "--armor", "--clear-sign")
    if ($Key) {
        $gpgArgs += @("--local-user", $Key)
    }
    $gpgArgs += @("--output", $targetFullPath, $tempFile)
    
    & gpg $gpgArgs
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[SUCCESS] Manifest signed successfully!" -ForegroundColor Green
        Write-Host "  Manifest: $targetFullPath" -ForegroundColor Green
        Write-Host "  Verify with: gpg-verify.ps1 -Manifest `"$targetFullPath`"" -ForegroundColor Gray
    } else {
        Write-Host "`n[ERROR] gpg returned exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} finally {
    Remove-Item -Force -LiteralPath $tempFile -ErrorAction SilentlyContinue
}
