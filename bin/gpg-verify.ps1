<#
.SYNOPSIS
    General-Purpose Anti-Tamper Verification & Integrity Checker for Windows (PowerShell).

.DESCRIPTION
    gpg-verify.ps1 verifies the OpenPGP signature of a manifest (e.g. SHA256SUMS.asc)
    and verifies the SHA-256 hash of each listed file.

.PARAMETER Manifest
    Path or glob to manifest file(s). Defaults to .\SHA256SUMS.asc.

.EXAMPLE
    .\gpg-verify.ps1
    .\gpg-verify.ps1 -Manifest "hosts\win11\SHA256SUMS.asc"

.NOTES
    Author:  Jialin Liu (LAU Kalin) <laukalin24@gmail.com>
    License: MIT License
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$Manifest = ".\SHA256SUMS.asc"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command "gpg" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] 'gpg.exe' not found in PATH! Please install Gpg4win or Git GnuPG." -ForegroundColor Red
    exit 1
}

$matchedManifests = @(Get-ChildItem -Path $Manifest -File -ErrorAction SilentlyContinue)

if ($matchedManifests.Count -eq 0) {
    Write-Host "[ERROR] Manifest file not found matching: $Manifest" -ForegroundColor Red
    exit 1
}

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "[GPG-Verify] Anti-Tamper Verification Suite (Windows)" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

$totalPassed = 0
$totalFailed = 0

foreach ($mf in $matchedManifests) {
    Write-Host "[MANIFEST] $($mf.FullName)" -ForegroundColor Blue
    $mfDir = $mf.DirectoryName

    # Step 1: Verify GPG digital signature
    Write-Host "  [1/2] Verifying GPG Signature..." -ForegroundColor Yellow
    $gpgOut = & gpg --verify $mf.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [FAILED] GPG signature verification failed!" -ForegroundColor Red
        $gpgOut | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        $totalFailed++
        continue
    }

    $signer = ($gpgOut | Select-String "Good signature from" | Select-Object -First 1)
    if ($signer) {
        Write-Host "  [OK] Valid GPG Signature: $signer" -ForegroundColor Green
    } else {
        Write-Host "  [OK] GPG Signature is VALID" -ForegroundColor Green
    }

    # Step 2: Parse cleartext content and verify SHA256 hashes
    Write-Host "  [2/2] Verifying SHA-256 Checksums..." -ForegroundColor Yellow
    $lines = Get-Content -LiteralPath $mf.FullName
    $inSignedBody = $false
    $manifestHashes = @()

    foreach ($l in $lines) {
        if ($l -match "^-----BEGIN PGP SIGNED MESSAGE-----") {
            $inSignedBody = $true
            continue
        }
        if ($l -match "^-----BEGIN PGP SIGNATURE-----") {
            $inSignedBody = $false
            break
        }
        if ($inSignedBody) {
            # Skip PGP Hash header or empty lines
            if ($l.StartsWith("Hash:") -or [string]::IsNullOrWhiteSpace($l)) {
                continue
            }
            # Expected format: <hash>  <filename>
            if ($l -match "^([a-fA-F0-9]{64})\s+(.+)$") {
                $manifestHashes += @{
                    Hash = $matches[1].ToLower()
                    File = $matches[2].Trim()
                }
            }
        }
    }

    $allFilesOk = $true
    foreach ($entry in $manifestHashes) {
        $targetFile = Join-Path $mfDir $entry.File
        if (-not (Test-Path -LiteralPath $targetFile)) {
            Write-Host "    [MISSING] $($entry.File)" -ForegroundColor Red
            $allFilesOk = $false
            continue
        }

        $actualHash = (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash.ToLower()
        if ($actualHash -eq $entry.Hash) {
            Write-Host "    [OK] $($entry.File)" -ForegroundColor Green
        } else {
            Write-Host "    [TAMPERED] $($entry.File) - Hash mismatch!" -ForegroundColor Red
            Write-Host "      Expected: $($entry.Hash)" -ForegroundColor Red
            Write-Host "      Actual:   $actualHash" -ForegroundColor Red
            $allFilesOk = $false
        }
    }

    if ($allFilesOk -and $manifestHashes.Count -gt 0) {
        Write-Host "  [RESULT] All $($manifestHashes.Count) files MATCH! (Zero unauthorized changes)`n" -ForegroundColor Green
        $totalPassed++
    } else {
        Write-Host "  [RESULT] Integrity check FAILED for one or more files!`n" -ForegroundColor Red
        $totalFailed++
    }
}

Write-Host "=================== Summary =======================" -ForegroundColor Cyan
Write-Host "  Total Manifests: $($matchedManifests.Count)"
Write-Host "  Passed:          $totalPassed" -ForegroundColor Green
if ($totalFailed -gt 0) {
    Write-Host "  Failed:          $totalFailed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "[ALL CLEAR] Verified authentic and unaltered!" -ForegroundColor Green
    exit 0
}
