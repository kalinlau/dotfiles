#!/usr/bin/env python3
"""
worklog.py - Deterministic, AST-aware parser and appender for WORKLOG.md
Complies with agentskills.io specification and Workspace Worklog guidelines.
"""

import argparse
import datetime
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Tuple

CATEGORY_EMOJI_MAP = {
    "dev": "🔨 [Dev]",
    "development": "🔨 [Dev]",
    "config": "⚙️ [Config]",
    "configuration": "⚙️ [Config]",
    "debug": "🐛 [Debug]",
    "fix": "🐛 [Debug]",
    "doc": "📝 [Doc]",
    "documentation": "📝 [Doc]",
    "idea": "💡 [Idea]",
    "design": "💡 [Design]",
    "done": "✅ [Done]",
    "start": "🚀 [Start]",
    "break": "⏸️ [Break]",
}

WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

INITIAL_TEMPLATE = """# 📓 Workspace Worklog

> 本文件采用**倒序追加**（最新日期与条目始终位于顶部），记录日常工作进度、操作流水、实验思考与灵感。

---

<!--
========================================================================
💡 快速记录模板（新的一天或新的条目直接复制此结构插入上方分割线之后）:
========================================================================

## 📅 YYYY-MM-DD (Weekday)
> **Focus**: 一句话描述今日核心目标或主线任务

- **HH:MM** 🚀 [Start] 启动工作
- **HH:MM** 🔨 [Dev] 正在开发功能、运行脚本，可附带命令或文件链接
- **HH:MM** 🐛 [Debug] 遇到的错误、排查过程与解决方案
- **HH:MM** 💡 [Idea] 突发灵感、设计思考、临时想法
- **HH:MM** ⚙️ [Config] 环境搭建、配置调优与环境参数变更
- **HH:MM** 📝 [Doc] 阅读笔记、学术文献调研或文档编写
- **HH:MM** ✅ [Done] 任务闭环、阶段交付
- **HH:MM** ⏸️ [Break] 中场休息或暂停
-->
"""


def find_git_root(start_path: Path) -> Optional[Path]:
    try:
        res = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=str(start_path),
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=False,
        )
        if res.returncode == 0 and res.stdout.strip():
            return Path(res.stdout.strip())
    except Exception:
        pass
    cur = start_path.resolve()
    while cur != cur.parent:
        if (cur / ".git").exists():
            return cur
        cur = cur.parent
    return None


def resolve_worklog_file(specified_path: Optional[str] = None) -> Path:
    if specified_path:
        p = Path(specified_path).expanduser().resolve()
        return p

    cwd = Path.cwd().resolve()
    direct_cwd = cwd / "WORKLOG.md"
    if direct_cwd.is_file():
        return direct_cwd

    git_root = find_git_root(cwd)
    if git_root:
        git_worklog = git_root / "WORKLOG.md"
        if git_worklog.is_file():
            return git_worklog

    cur = cwd
    while cur != cur.parent:
        candidate = cur / "WORKLOG.md"
        if candidate.is_file():
            return candidate
        cur = cur.parent

    return direct_cwd


def get_category_tag(category_input: str) -> str:
    cleaned = category_input.strip()
    if re.match(r"^[\U00010000-\U0010ffff\u2600-\u27bf\ufe0f\s]+\[.+\]", cleaned):
        return cleaned
    lookup = cleaned.lower().strip("[] \t")
    return CATEGORY_EMOJI_MAP.get(lookup, f"📝 [{cleaned}]")


def format_entry(time_str: str, category_tag: str, title: str, bullets: List[str]) -> str:
    lines = [f"- **{time_str}** {category_tag} {title}："]
    for b in bullets:
        for bl in b.splitlines():
            if not bl.strip():
                continue
            if bl.startswith("  - ") or bl.startswith("    - "):
                lines.append(bl)
            elif bl.startswith("- "):
                lines.append(f"  {bl}")
            else:
                lines.append(f"  - {bl}")
    return "\n".join(lines)


def insert_into_worklog(
    content: str,
    target_date: datetime.date,
    time_str: str,
    entry_text: str,
    focus: Optional[str] = None,
    append_focus: Optional[str] = None,
) -> str:
    weekday_str = WEEKDAYS[target_date.weekday()]
    date_header_pattern = rf"## 📅 {target_date.strftime('%Y-%m-%d')} \({weekday_str}\)"
    date_match = re.search(date_header_pattern, content)

    if not date_match:
        # Date doesn't exist yet, insert in reverse chronological order among date sections
        default_focus = focus if focus else (append_focus if append_focus else "日常工作与任务记录")
        new_section = (
            f"## 📅 {target_date.strftime('%Y-%m-%d')} ({weekday_str})\n\n"
            f"> **Focus**: {default_focus}\n\n"
            f"{entry_text}\n\n"
            f"---\n\n"
        )

        all_date_matches = list(re.finditer(r"## 📅 (\d{4}-\d{2}-\d{2})", content))
        if all_date_matches:
            insert_pos = None
            for dm in all_date_matches:
                d_val = datetime.datetime.strptime(dm.group(1), "%Y-%m-%d").date()
                if target_date >= d_val:
                    insert_pos = dm.start()
                    break
            if insert_pos is not None:
                return content[:insert_pos] + new_section + content[insert_pos:]
            else:
                # Target date is older than all existing dates, insert before the bottom comment or at end
                comment_match = re.search(r"<!--\s*===", content)
                if comment_match:
                    c_pos = comment_match.start()
                    return content[:c_pos].rstrip() + "\n\n" + new_section + content[c_pos:]
                return content.rstrip() + "\n\n" + new_section

        # No date sections exist yet
        first_sep = content.find("\n---\n")
        if first_sep != -1:
            insert_pos = first_sep + len("\n---\n")
            if insert_pos < len(content) and content[insert_pos] == "\n":
                insert_pos += 1
            return content[:insert_pos] + new_section + content[insert_pos:]
        else:
            return content + "\n\n" + new_section

    # Date section exists
    date_start = date_match.start()
    date_end_match = re.search(r"\n(?=## 📅 |\Z|<!--)", content[date_start + len(date_match.group(0)) :])
    if date_end_match:
        date_section_end = date_start + len(date_match.group(0)) + date_end_match.start()
    else:
        date_section_end = len(content)

    date_section = content[date_start:date_section_end]

    # Handle focus update
    focus_match = re.search(r"> \*\*Focus\*\*: *(.*?)(?=\n)", date_section)
    if focus_match:
        curr_focus = focus_match.group(1).strip()
        new_focus = curr_focus
        if focus:
            new_focus = focus.strip()
        elif append_focus:
            if append_focus.strip() not in curr_focus:
                sep = "，" if any('\u4e00' <= c <= '\u9fff' for c in curr_focus) else ", "
                new_focus = f"{curr_focus}{sep}{append_focus.strip()}"
        if new_focus != curr_focus:
            old_line = focus_match.group(0)
            new_line = f"> **Focus**: {new_focus}"
            date_section = date_section.replace(old_line, new_line, 1)

    # Insert entry in reverse chronological order
    entry_time_val = tuple(map(int, time_str.split(":")))
    entry_matches = list(re.finditer(r"\n- \*\*(\d{2}:\d{2})\*\*", date_section))

    insert_idx = None
    for em in entry_matches:
        t_val = tuple(map(int, em.group(1).split(":")))
        if entry_time_val >= t_val:
            insert_idx = em.start() + 1
            break

    if insert_idx is not None:
        updated_section = date_section[:insert_idx] + entry_text + "\n" + date_section[insert_idx:]
    else:
        if entry_matches:
            # Slower than all existing entries, append after the last entry
            last_em = entry_matches[-1]
            last_entry_end_match = re.search(r"\n(?=- \*\*|\n---|## |\Z)", date_section[last_em.start() + 1 :])
            if last_entry_end_match:
                end_pos = last_em.start() + 1 + last_entry_end_match.start()
            else:
                end_pos = len(date_section)
            updated_section = date_section[:end_pos].rstrip() + "\n" + entry_text + "\n" + date_section[end_pos:]
        else:
            # No entries yet under this date
            f_match = re.search(r"> \*\*Focus\*\*: .*?\n", date_section)
            if f_match:
                insert_pos = f_match.end()
                updated_section = date_section[:insert_pos] + "\n" + entry_text + "\n" + date_section[insert_pos:]
            else:
                updated_section = date_section + "\n\n" + entry_text

    return content[:date_start] + updated_section + content[date_section_end:]


def main():
    parser = argparse.ArgumentParser(description="WORKLOG.md deterministic parser and appender")
    parser.add_argument("--file", "-f", help="Path to WORKLOG.md (default: auto-detected)")
    parser.add_argument("--category", "-c", default="dev", help="Category name (dev, config, doc, debug, etc.)")
    parser.add_argument("--title", "-t", help="Title of entry")
    parser.add_argument("--bullet", "-b", action="append", default=[], help="Bullet point (can repeat)")
    parser.add_argument("--body", help="Multi-line body with bullets or code snippets")
    parser.add_argument("--time", help="Timestamp HH:MM (default: current local time)")
    parser.add_argument("--date", help="Date YYYY-MM-DD (default: current local date)")
    parser.add_argument("--focus", help="Override today's focus line")
    parser.add_argument("--append-focus", help="Append text to today's focus line")
    parser.add_argument("--json", dest="json_payload", help="JSON string containing entry details")
    parser.add_argument("--preview", action="store_true", help="Print result without modifying file")
    parser.add_argument("--find-file", action="store_true", help="Print resolved target file path and exit")
    parser.add_argument("--init", action="store_true", help="Initialize file with standard template if missing")

    args = parser.parse_args()

    target_file = resolve_worklog_file(args.file)

    if args.find_file:
        print(str(target_file))
        return 0

    if not target_file.exists():
        if args.preview:
            pass
        elif args.init or not args.file:
            target_file.parent.mkdir(parents=True, exist_ok=True)
            target_file.write_text(INITIAL_TEMPLATE, encoding="utf-8")
            print(f"[Init] Initialized new WORKLOG at {target_file}")
        else:
            print(f"Error: Target file {target_file} does not exist. Use --init to create it.", file=sys.stderr)
            return 1

    # Parse JSON payload if provided
    payload = {}
    if args.json_payload:
        try:
            payload = json.loads(args.json_payload)
        except Exception as e:
            print(f"Error parsing --json: {e}", file=sys.stderr)
            return 1

    category = payload.get("category", args.category)
    title = payload.get("title", args.title)
    bullets = payload.get("bullets", args.bullet)
    body = payload.get("body", args.body)
    time_str = payload.get("time", args.time)
    date_str = payload.get("date", args.date)
    focus = payload.get("focus", args.focus)
    append_focus = payload.get("append_focus", args.append_focus)

    if not title:
        print("Error: --title (or title in json) is required.", file=sys.stderr)
        return 1

    now = datetime.datetime.now()
    if not time_str:
        time_str = now.strftime("%H:%M")
    if date_str:
        target_date = datetime.datetime.strptime(date_str, "%Y-%m-%d").date()
    else:
        target_date = now.date()

    if body:
        bullets.extend(body.splitlines())

    category_tag = get_category_tag(category)
    entry_text = format_entry(time_str, category_tag, title, bullets)

    if args.preview:
        print("=== PREVIEW ENTRY ===")
        print(entry_text)
        print("=====================")
        return 0

    original_content = target_file.read_text(encoding="utf-8")
    new_content = insert_into_worklog(
        content=original_content,
        target_date=target_date,
        time_str=time_str,
        entry_text=entry_text,
        focus=focus,
        append_focus=append_focus,
    )

    target_file.write_text(new_content, encoding="utf-8")
    print(f"[Success] Appended worklog entry to {target_file} at {target_date} {time_str}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
