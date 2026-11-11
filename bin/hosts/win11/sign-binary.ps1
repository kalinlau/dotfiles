<#
.SYNOPSIS
    Automated Authenticode Code Signing & Publisher Verification Script for Windows 11.

.DESCRIPTION
    sign-binary.ps1 manages code signing for wsl-ime-daemon.exe:
    1. Checks for an existing "LAU Kalin" code signing certificate in Cert:\CurrentUser\My.
    2. If missing, generates a 10-year SHA256 Code Signing certificate using New-SelfSignedCertificate.
    3. Imports the certificate into Cert:\CurrentUser\Root and Cert:\CurrentUser\TrustedPublisher so
       Windows Explorer and SmartScreen recognize it as a verified publisher.
    4. Embeds the Authenticode signature into the target binary via Set-AuthenticodeSignature.
    5. Clears Mark-of-the-Web (Zone.Identifier) network share flags via Unblock-File.

.PARAMETER FilePath
    Path to the executable to sign. Defaults to wsl-ime-daemon.exe in the script directory.

.EXAMPLE
    .\sign-binary.ps1
    .\sign-binary.ps1 -FilePath "C:\path\to\wsl-ime-daemon.exe"

.NOTES
    Author:  Jialin Liu (LAU Kalin) <laukalin24@gmail.com>
    License: MIT License (see LICENSE file)
#>

[CmdletBinding()]
param (
    [string]$FilePath = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -LiteralPath $ScriptDir

# Resolve target binary
if ([string]::IsNullOrWhiteSpace($FilePath)) {
    $FilePath = Join-Path $ScriptDir "wsl-ime-daemon.exe"
}

if (-not (Test-Path -LiteralPath $FilePath)) {
    Write-Host "[ERROR] Target file not found: $FilePath" -ForegroundColor Red
    exit 1
}

$FullPath = (Resolve-Path -LiteralPath $FilePath).Path
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "[WSL-IME] Authenticode Code Signing Tool" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "[INFO] Target: $FullPath" -ForegroundColor Gray

# Step 1: Look for existing Code Signing certificate
$CertSubject = "CN=LAU Kalin, E=laukalin24@gmail.com"
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue |
        Where-Object { $_.Subject -match "LAU Kalin" } |
        Select-Object -First 1

if (-not $cert) {
    Write-Host "[1/3] No existing code signing certificate found. Generating new certificate..." -ForegroundColor Yellow
    $cert = New-SelfSignedCertificate -Type CodeSigningCert `
        -Subject $CertSubject `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -NotAfter (Get-Date).AddYears(10) `
        -HashAlgorithm "SHA256" `
        -KeyLength 2048 `
        -FriendlyName "LAU Kalin WSL-IME Code Signing Certificate"
    
    Write-Host "[SUCCESS] Generated certificate: $($cert.Thumbprint)" -ForegroundColor Green
} else {
    Write-Host "[1/3] Using existing certificate: $($cert.Thumbprint) ($($cert.Subject))" -ForegroundColor Green
}

# Step 2: Ensure certificate is trusted in Root and TrustedPublisher stores
Write-Host "[2/3] Checking trust configuration in Windows certificate stores..." -ForegroundColor Gray

# 2.1 Trusted Root Certification Authorities (CurrentUser\Root)
$rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::Root, [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser)
$rootStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$inRoot = $rootStore.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
if (-not $inRoot) {
    Write-Host "[INFO] Adding certificate to CurrentUser\Root (A one-time Windows security prompt may appear)..." -ForegroundColor Yellow
    $rootStore.Add($cert)
    Write-Host "[SUCCESS] Added to CurrentUser\Root" -ForegroundColor Green
} else {
    Write-Host "[INFO] Already trusted in CurrentUser\Root" -ForegroundColor Gray
}
$rootStore.Close()

# 2.2 Trusted Publishers (CurrentUser\TrustedPublisher)
$pubStore = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::TrustedPublisher, [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser)
$pubStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$inPub = $pubStore.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
if (-not $inPub) {
    $pubStore.Add($cert)
    Write-Host "[SUCCESS] Added to CurrentUser\TrustedPublisher" -ForegroundColor Green
} else {
    Write-Host "[INFO] Already present in CurrentUser\TrustedPublisher" -ForegroundColor Gray
}
$pubStore.Close()

# Step 3: Embed Authenticode signature into the binary
Write-Host "[3/3] Embedding Authenticode digital signature into binary..." -ForegroundColor Gray
$sig = Set-AuthenticodeSignature -FilePath $FullPath -Certificate $cert -HashAlgorithm "SHA256"

# Step 4: Unblock network/UNC Zone.Identifier flags on executables and scripts in directory
Unblock-File -LiteralPath $FullPath -ErrorAction SilentlyContinue
Get-ChildItem -LiteralPath $ScriptDir -Filter "*.bat" | ForEach-Object { Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue }
Get-ChildItem -LiteralPath $ScriptDir -Filter "*.ps1" | ForEach-Object { Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue }

# Step 5: Verification & Status Output
Write-Host "`n=================== Signature Status ===================" -ForegroundColor Cyan
if ($sig.Status -eq "Valid") {
    Write-Host "Status:    VALID (此数字签名正常)" -ForegroundColor Green
    Write-Host "Signer:    $($sig.SignerCertificate.Subject)" -ForegroundColor Green
    Write-Host "Algorithm: $($sig.SignerCertificate.SignatureAlgorithm.FriendlyName)" -ForegroundColor Green
    Write-Host "Expires:   $($sig.SignerCertificate.NotAfter.ToString('yyyy-MM-dd'))" -ForegroundColor Green
    Write-Host "`n[SUCCESS] Binary successfully signed! Windows Explorer will now display '已验证的发布者: LAU Kalin'." -ForegroundColor Green
} else {
    Write-Host "Status:    $($sig.Status) ($($sig.StatusMessage))" -ForegroundColor Red
    Write-Host "[WARNING] Signature was applied but status is not Valid. Check certificate trust." -ForegroundColor Yellow
}
Write-Host "========================================================" -ForegroundColor Cyan
