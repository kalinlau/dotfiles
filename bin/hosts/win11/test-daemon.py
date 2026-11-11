#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
WSL-IME Daemon: Diagnostic & Verification Test Client.

File:        test-daemon.py
Description: Sends test commands (ping, get, set:en, set:zh, toggle) to the
             wsl-ime-daemon running on the Windows host and measures end-to-end
             round-trip network latency in milliseconds.
Author:      Jialin Liu (LAU Kalin) <laukalin24@gmail.com>
License:     MIT License (see LICENSE file)

Usage:
    python3 test-daemon.py ping      # Expected: pong (<1ms)
    python3 test-daemon.py get       # Expected: zh or en
    python3 test-daemon.py set:en    # Force English mode: ok
    python3 test-daemon.py set:zh    # Force Chinese mode: ok
    python3 test-daemon.py toggle    # Toggle between modes
"""

import socket
import sys
import time
from typing import List, Tuple

# Default listening port configured in wsl-ime-daemon
PORT: int = 8765


def get_candidate_hosts() -> List[str]:
    """
    Retrieve candidate host IPs for connecting to the Windows host.

    Supports both:
    1. Mirrored networking (127.0.0.1 loopback routing).
    2. NAT / virtual switch networking (resolv.conf nameserver gateway IP).

    Returns:
        List of candidate host IP addresses.
    """
    hosts: List[str] = ["127.0.0.1"]
    try:
        with open("/etc/resolv.conf", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("nameserver"):
                    parts = line.split()
                    if len(parts) >= 2:
                        ns = parts[1].strip()
                        if ns and ns not in hosts:
                            hosts.append(ns)
    except Exception:
        pass
    return hosts


def send_cmd(cmd: str) -> Tuple[str, str, float]:
    """
    Sends a single line command to wsl-ime-daemon and retrieves its response.

    Args:
        cmd: Command string (e.g. 'ping', 'get', 'set:en', 'set:zh', 'toggle').

    Returns:
        Tuple containing (response string, host connected to, round-trip ms).

    Raises:
        RuntimeError: If all candidate host connections fail or time out.
    """
    hosts = get_candidate_hosts()
    last_err: str = "No hosts available"

    for host in hosts:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1.5)
        start = time.perf_counter()
        try:
            s.connect((host, PORT))
            # Transmit CRLF terminated command
            s.sendall((cmd.strip() + "\r\n").encode("ascii"))
            resp = s.recv(1024).decode("ascii").strip()
            elapsed_ms = (time.perf_counter() - start) * 1000.0
            return resp, host, elapsed_ms
        except Exception as e:
            last_err = f"{type(e).__name__}: {e} (attempted on {host}:{PORT})"
        finally:
            try:
                s.close()
            except Exception:
                pass

    raise RuntimeError(last_err)


def main() -> None:
    """CLI entry point for test client."""
    cmd = sys.argv[1] if len(sys.argv) > 1 else "get"
    try:
        resp, host, elapsed_ms = send_cmd(cmd)
        print(f"[{cmd}] -> {resp} (via {host}:{PORT} in {elapsed_ms:.2f}ms)")
    except Exception as e:
        print(f"[ERROR] {e}")
        print("\n[Troubleshooting Tips]")
        print("1. Check whether wsl-ime-daemon.exe is running on Windows:")
        print("   In Windows CMD/PowerShell, execute: tasklist | findstr wsl-ime-daemon")
        print("2. If not running, start it using start-daemon.bat or start-daemon.ps1.")
        print("3. If Windows Firewall blocks port 8765, run add-firewall-rule.bat as Administrator,")
        print("   or execute in PowerShell (Admin):")
        print("   New-NetFirewallRule -DisplayName 'WSL-IME' -Direction Inbound -LocalPort 8765 -Protocol TCP -Action Allow")
        sys.exit(1)


if __name__ == "__main__":
    main()
