#!/usr/bin/env bash
# ==============================================================================
# WSL-IME Daemon: Linux/WSL Compilation Script
#
# File:        build.sh
# Description: Invokes the Windows host's native csc.exe from inside WSL to compile
#              wsl-ime-daemon.cs into wsl-ime-daemon.exe.
#
# Usage:       ./build.sh
#
# License:     MIT License (see LICENSE file)
# ==============================================================================

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "==================================================="
echo "[WSL-IME] Compiling Windows Daemon from WSL"
echo "==================================================="

# Locate the Windows .NET Framework C# compiler
CSC_WIN="/mnt/c/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe"
if [ ! -f "$CSC_WIN" ]; then
    CSC_WIN="/mnt/c/Windows/Microsoft.NET/Framework/v4.0.30319/csc.exe"
fi

if [ ! -f "$CSC_WIN" ]; then
    echo "[ERROR] csc.exe not found at $CSC_WIN"
    exit 1
fi

echo "[INFO] Using Windows compiler: $CSC_WIN"

# Translate WSL Linux filesystem paths into Windows-compatible paths
WIN_CS="$(wslpath -w "$DIR/wsl-ime-daemon.cs")"
WIN_OUT="$(wslpath -w "$DIR/wsl-ime-daemon.exe")"

echo "[INFO] Source file: $WIN_CS"
echo "[INFO] Output binary: $WIN_OUT"
echo "[WSL-IME] Compiling..."

"$CSC_WIN" /nologo /target:winexe /optimize+ "/out:$WIN_OUT" "$WIN_CS"

if [ -f "$DIR/wsl-ime-daemon.exe" ]; then
    chmod +x "$DIR/wsl-ime-daemon.exe"
    echo "[SUCCESS] wsl-ime-daemon.exe compiled successfully!"
else
    echo "[ERROR] Compilation failed. Binary not created."
    exit 1
fi
