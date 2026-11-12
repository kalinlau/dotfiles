---
name: worklog
description: Record, structure, and append daily work logs, development progress, debug traces, and design reflections to WORKLOG.md in reverse chronological order. Triggers on: /worklog, worklog, 记一下 log, 记log, 写入 worklog, 记录工作, 记录今日工作, 工作日志, update worklog, add worklog.
---

# 📓 Worklog Agent Skill

An open, standard Agent Skill compliant with [agentskills.io](https://agentskills.io) specifications. It provides deterministic, structured logging into `WORKLOG.md` with reverse-chronological ordering, intelligent daily Focus coordination, and standardized category taxonomy.

---

## 🎯 When to Use This Skill

Activate this skill when:
- The user enters `/worklog` or `/worklog <details>`
- The user requests: "记一下 log", "写入 worklog", "记录今日工作", "把刚才的改动记到日志里"
- A major feature, bugfix, architectural design, or configuration milestone is completed and needs persistent audit logging
- Inspecting or initializing the workspace `WORKLOG.md`

---

## 🧭 File Discovery & Target Resolution

The skill resolves the target logging file in the following order:
1. **Explicit path**: Value passed via `--file <path>` or specified in the user prompt (e.g., `写入 ~/workspace/WORKLOG.md`).
2. **Current working directory**: `./WORKLOG.md` in the current working directory.
3. **Repository root**: Upward traversal to find `WORKLOG.md` at the Git root directory.
4. **Auto-initialization**: If no `WORKLOG.md` exists, automatically initialize a new one using the standard template:
   ```markdown
   # 📓 Workspace Worklog

   > 本文件采用**倒序追加**（最新日期与条目始终位于顶部），记录日常工作进度、操作流水、实验思考与灵感。

   ---
   ```

---

## ⚡ Interaction & Operation Modes

### Mode 1: Context Distillation (无参数 `/worklog`)
When the user simply types `/worklog` or says "记一下刚才的内容":
1. **Analyze recent conversation turns**: Identify key technical accomplishments, configurations modified, bugs fixed, or designs formulated.
2. **Classify category**: Select the most fitting category tag from the taxonomy below.
3. **Draft entry**:
   - Extract title and 2–4 concise, high-density bullet points with bold subheadings (`- **子项**：...`).
   - If referenced files exist, format markdown links as `[basename](file:///absolute/path)`.
   - If code/config snippets are essential, embed them cleanly.
4. **Execute write**: Run `scripts/worklog.py` or write to `WORKLOG.md`, updating or appending to the day's `> **Focus**:` if a new domain was touched.

### Mode 2: Direct Command (`/worklog <content>`)
When the user supplies explicit details (e.g., `/worklog -c dev -t "重构解析器" -b "**说明**：支持 AST"`):
1. Parse category, title, and bullet points directly.
2. Apply standard formatting and insert in strict reverse-chronological order.

---

## 🏷️ Standard Category Taxonomy

Always prefix the log entry with the appropriate Emoji and Category bracket:

| Category Code | Display Tag | Typical Scenario |
| :--- | :--- | :--- |
| `dev` | `🔨 [Dev]` | 正在开发功能、编写代码、运行构建或执行重构 |
| `config` | `⚙️ [Config]` | 环境搭建、字体/终端/IDE 调优、配置参数变更 |
| `debug` | `🐛 [Debug]` | 错误排查、异常修复、根因分析与验证手段 |
| `design` | `💡 [Design]` | 架构设计、协议规范梳理、技术选型权衡 |
| `idea` | `💡 [Idea]` | 突发灵感、临时想法、探索性构想 |
| `doc` | `📝 [Doc]` | 阅读笔记、学术论文调研、手册编写、知识沉淀 |
| `done` | `✅ [Done]` | 任务闭环、阶段交付、评测指标达成 |
| `start` | `🚀 [Start]` | 启动新一天工作或开启全新项目主线 |
| `break` | `⏸️ [Break]` | 中场休息或临时暂停 |

---

## 📐 Layout & Ordering Specifications

Every `WORKLOG.md` strictly adheres to the following rules:

1. **Reverse Chronological Order (双重倒序)**:
   - **Date level**: Latest dates (`## 📅 YYYY-MM-DD (Weekday)`) always reside at the top of the file, directly following the top header separator `---`.
   - **Time level**: Within a single date, latest timestamps (`- **HH:MM** ...`) always reside at the top of that day's entry list.
2. **Date Header Format**:
   ```markdown
   ## 📅 YYYY-MM-DD (Weekday)

   > **Focus**: 核心主线描述（新主题可用全角逗号追加）
   ```
3. **Entry Format**:
   ```markdown
   - **HH:MM** 🔨 [Dev] 标题概括：
     - **核心子项1**：具体实现、命令或 [代码链接](file:///absolute/path)
     - **核心子项2**：排查结果或技术要点
   ```
4. **Focus Coordination**:
   - For a new day: summarize today's main intent.
   - For subsequent entries on the same day: if the entry introduces a substantially new domain, append it to `> **Focus**: ...` (separated by `，`).

---

## 🛠️ Execution Tool: `scripts/worklog.py`

This skill provides a deterministic Python helper script located at `scripts/worklog.py`. Agents should prefer calling this script for atomic, bug-free updates:

```bash
# 1. Structured JSON Payload invocation (Recommended for Agents):
python3 <skill-dir>/scripts/worklog.py --json '{
  "category": "Config",
  "title": "调优 Windows Terminal 之 Maple Mono NF CN 连字配置",
  "bullets": [
    "**平衡实用策略**：启用 calt, ss01, ss02, ss04, zero，移除 ss03/ss07",
    "**JSON 片段**：配置 features 字符串 calt=1,ss01=1,ss02=1,ss04=1,zero=1"
  ],
  "append_focus": "Windows Terminal 字体连字调优"
}'

# 2. Command Line Arguments:
python3 <skill-dir>/scripts/worklog.py \
  --category dev \
  --title "完成 AST 解析器重构" \
  --bullet "**性能提升**：解析耗时减少 30%" \
  --append-focus "AST 解析器重构"

# 3. Locate Target WORKLOG.md:
python3 <skill-dir>/scripts/worklog.py --find-file
```

---

## 💡 Best Practices for Agents

1. **Precision & Density**: Avoid generic one-liners like "完成了代码编写". Always state *what* changed, *why*, and *how* (including parameter names, file basenames, or metrics).
2. **File Linking**: Always create clickable file markdown links for referenced files using the `file:///` URI scheme.
3. **Code Quality**: Keep code blocks in log entries concise, capturing only the essential configuration snippet or command line.
