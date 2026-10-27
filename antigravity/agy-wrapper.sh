#!/usr/bin/env bash
# Antigravity CLI Google Drive Auto-Sync Wrapper
# This file is loaded by ~/.shell_local_after

agy() {
    if command -v agy-sync >/dev/null 2>&1; then
        agy-sync pull --quiet || true
    fi
    command agy "$@"
    local __exit_code=$?
    if command -v agy-sync >/dev/null 2>&1; then
        agy-sync push --quiet || true
    fi
    return $__exit_code
}
