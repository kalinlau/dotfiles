# Worklog Skill (`/worklog`)

A customized Agent Skill adhering to the [agentskills.io](https://agentskills.io) specification. Designed to maintain and append structured daily progress and technical notes to `WORKLOG.md` using deterministic reverse-chronological ordering.

## Features

- **Double Reverse Ordering**: Places new dates at the top and arranges daily entries chronologically backward (`HH:MM`).
- **Dynamic Focus Coordination**: Updates today's `> **Focus**:` summary when introducing new technical areas.
- **Smart Path Discovery**: Resolves `--file`, finds `./WORKLOG.md` in the current working directory, or walks up to the project root.
- **Structured Categories**: Standardized tagging (`🔨 [Dev]`, `⚙️ [Config]`, `🐛 [Debug]`, `💡 [Design]`, `📝 [Doc]`, `✅ [Done]`, etc.).
- **Zero-Dependency Python Utility**: Bundles `scripts/worklog.py` for deterministic parsing and modification.

## Installation

### Via `npx skills`
```bash
npx skills add kalinlau/worklog-skill
```

### Local Development / Dotfiles Link
To use immediately in your local Antigravity environment:
```bash
ln -s ~/dotfiles/antigravity/skills/worklog ~/.gemini/antigravity-cli/skills/worklog
ln -s ~/dotfiles/antigravity/skills/worklog ~/.agents/skills/worklog
```

## Quick Start

In any agent session:
- `/worklog`: Summarizes recent conversation achievements and prepares a structured entry.
- `/worklog -c dev -t "Refactored parser" -b "**AST**: Implemented full tree traversal"`

Or run directly from the shell:
```bash
python3 scripts/worklog.py \
  --category config \
  --title "Updated Terminal Settings" \
  --bullet "**Details**: Configured Maple Mono NF CN"
```
