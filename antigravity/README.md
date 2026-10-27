# Antigravity CLI Google Drive 多设备同步套件

本目录存放用于在多台设备（Linux、macOS、Windows WSL）之间通过 Google Drive 双向增量同步 Antigravity CLI 对话历史（包含 `brain/` 和 `conversations/` SQLite 数据库）的工具集。

## 目录结构

- [`agy-sync`](agy-sync)：核心同步命令行工具（支持 `pull`、`push`、`sync`、`status`、`list`）
- [`install-sync.sh`](install-sync.sh)：一键安装部署脚本（自动校验 rclone、生成软链接、配置 Shell 钩子）
- [`agy-wrapper.sh`](agy-wrapper.sh)：Shell 包装器脚本（定义 `agy()` 函数，启动前 pull，退出后 push）

## 一键安装与配置

在任意配置了此 dotfiles 的机器上执行：

```bash
cd ~/dotfiles/antigravity
bash install-sync.sh
```

### 安装内容说明
1. **命令软链接**：将 `agy-sync` 软链接至 `~/.local/bin/agy-sync`，后续直接修改本目录代码立即全系统生效。
2. **配置文件**：在 `~/.config/antigravity-sync/config.env` 生成默认配置（可自定义远程名、云端根目录等）。
3. **Shell 无侵入集成**：在 `~/.shell_local_after` 中添加 `agy-wrapper.sh` 的引用，确保 dotfiles 下受版本控制的 `bashrc` / `zshrc` 保持干净。

## 常用命令

```bash
# 查看同步状态与本地/云端会话数
agy-sync status

# 手动双向增量同步
agy-sync sync

# 手动从云端拉取增量会话
agy-sync pull

# 手动推送本地会话至云端
agy-sync push

# 查看两端最近会话列表
agy-sync list
```
