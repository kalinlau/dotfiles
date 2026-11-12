#!/usr/bin/env bash
set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Linking Worklog Skill..."

mkdir -p ~/.gemini/antigravity-cli/skills ~/.agents/skills 2>/dev/null || true

ln -sfn "$SKILL_DIR" ~/.gemini/antigravity-cli/skills/worklog || echo "[Note] ~/.gemini/antigravity-cli/skills is read-only or requires permissions"
ln -sfn "$SKILL_DIR" ~/.agents/skills/worklog || echo "[Note] ~/.agents/skills is read-only or requires permissions"

echo "==> Done! Worklog skill installed from $SKILL_DIR"
