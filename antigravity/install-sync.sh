#!/usr/bin/env bash
# ==============================================================================
# install-sync.sh: Antigravity CLI Google Drive 同步套件安装程序 (dotfiles 版)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_TARGET="${HOME}/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/antigravity-sync"
CONFIG_FILE="${CONFIG_DIR}/config.env"
SHELL_LOCAL_AFTER="${HOME}/.shell_local_after"

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_RED="\033[31m"

echo -e "${COLOR_BLUE}======================================================${COLOR_RESET}"
echo -e "${COLOR_BLUE} Antigravity CLI - Google Drive 多端同步安装向导${COLOR_RESET}"
echo -e "${COLOR_BLUE} 脚本源目录: ${SCRIPT_DIR}${COLOR_RESET}"
echo -e "${COLOR_BLUE}======================================================${COLOR_RESET}"

# 1. 检查 rclone 安装
echo -e "\n[1/5] 检查 rclone 安装环境..."
if command -v rclone >/dev/null 2>&1; then
    echo -e "${COLOR_GREEN}[√] 发现 rclone: $(rclone --version | head -n 1)${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}[!] 未检测到 rclone。请根据你的系统进行安装：${COLOR_RESET}"
    echo "    - Linux / WSL: curl https://rclone.org/install.sh | sudo bash"
    echo "    - macOS: brew install rclone"
    echo "    - Windows: winget install Rclone.Rclone"
    echo ""
    read -rp "是否现在尝试自动安装 rclone？[y/N] " install_rclone || true
    if [[ "${install_rclone:-}" =~ ^[Yy]$ ]]; then
        if command -v curl >/dev/null 2>&1; then
            curl https://rclone.org/install.sh | sudo bash
        else
            echo -e "${COLOR_RED}缺少 curl，请先手动安装 rclone。${COLOR_RESET}"
        fi
    fi
fi

# 2. 检查 Google Drive 远程配置
echo -e "\n[2/5] 检查 Google Drive 远程配置..."
REMOTE_NAME="gdrive"
if command -v rclone >/dev/null 2>&1; then
    if rclone listremotes | grep -q "^${REMOTE_NAME}:$"; then
        echo -e "${COLOR_GREEN}[√] 已检测到 rclone 远程目标 '${REMOTE_NAME}:'${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}[!] 尚未配置名为 '${REMOTE_NAME}' 的 Google Drive 目标。${COLOR_RESET}"
        echo "    请在终端运行: rclone config"
        echo "    配置向导简要步骤："
        echo "      1. 输入 'n' (New remote)"
        echo "      2. name: 'gdrive'"
        echo "      3. Storage: 选择 'drive' (Google Drive)"
        echo "      4. client_id / client_secret 直接回车使用默认"
        echo "      5. scope: 选择 '1' (Full access to all files)"
        echo "      6. 网页授权完成后保存即可。"
    fi
fi

# 3. 初始化配置文件
echo -e "\n[3/5] 初始化配置文件..."
mkdir -p "${CONFIG_DIR}"
if [[ ! -f "${CONFIG_FILE}" ]]; then
    cat > "${CONFIG_FILE}" <<EOF
# Antigravity CLI Google Drive Sync Configuration
REMOTE_NAME="gdrive"
REMOTE_BASE_PATH="Antigravity-sync"
LOCAL_DATA_DIR="${HOME}/.gemini/antigravity-cli"
SYNC_TARGETS=("brain" "conversations")
RCLONE_EXTRA_ARGS="--fast-list --transfers=4 --drive-chunk-size=16M"
EOF
    echo -e "${COLOR_GREEN}[√] 已生成配置文件: ${CONFIG_FILE}${COLOR_RESET}"
else
    echo -e "${COLOR_GREEN}[√] 配置文件已存在: ${CONFIG_FILE}${COLOR_RESET}"
fi

# 4. 软链接部署 agy-sync 到 ~/.local/bin
echo -e "\n[4/5] 部署 agy-sync 命令行工具 (软链接方式)..."
mkdir -p "${BIN_TARGET}"
chmod +x "${SCRIPT_DIR}/agy-sync"
chmod +x "${SCRIPT_DIR}/agy-wrapper.sh"
ln -sf "${SCRIPT_DIR}/agy-sync" "${BIN_TARGET}/agy-sync"
echo -e "${COLOR_GREEN}[√] 已建立软链接: ${BIN_TARGET}/agy-sync -> ${SCRIPT_DIR}/agy-sync${COLOR_RESET}"

# 5. 配置 Shell 自动同步包装器 (通过 ~/.shell_local_after)
echo -e "\n[5/5] 配置 Shell 自动同步包装器..."

SOURCE_CMD="[ -f \"${SCRIPT_DIR}/agy-wrapper.sh\" ] && source \"${SCRIPT_DIR}/agy-wrapper.sh\""

if [[ -f "${SHELL_LOCAL_AFTER}" ]] && grep -q "agy-wrapper.sh" "${SHELL_LOCAL_AFTER}"; then
    echo -e "${COLOR_GREEN}[√] ${SHELL_LOCAL_AFTER} 中已包含 agy-wrapper 加载配置。${COLOR_RESET}"
else
    echo "" >> "${SHELL_LOCAL_AFTER}"
    echo "# Antigravity CLI auto-sync wrapper (dotfiles)" >> "${SHELL_LOCAL_AFTER}"
    echo "${SOURCE_CMD}" >> "${SHELL_LOCAL_AFTER}"
    echo -e "${COLOR_GREEN}[√] 成功将加载指令写入 ${SHELL_LOCAL_AFTER}！${COLOR_RESET}"
    echo -e "    提示：这样可以保持 dotfiles 仓库的 bashrc/zshrc 干净不受影响。"
fi

echo -e "\n${COLOR_GREEN}======================================================${COLOR_RESET}"
echo -e "${COLOR_GREEN} 安装配置完成！${COLOR_RESET}"
echo -e "请运行以下命令生效环境（或重新打开终端）："
echo -e "  source ~/.shell_local_after"
echo -e "\n常用指令："
echo -e "  agy-sync status     查看当前同步状态与本地/云端会话统计"
echo -e "  agy-sync sync       手动执行一次双向增量同步"
echo -e "  agy                 执行原 agy 会在启动前自动 pull，退出后自动 push"
echo -e "${COLOR_GREEN}======================================================${COLOR_RESET}"
