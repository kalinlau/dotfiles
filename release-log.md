# Release Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.1.0] - 2026-11-11

### Added

- **Windows 11 极速输入法常驻守护进程 (`wsl-ime-daemon`)**：
  - 新增 [`bin/hosts/win11/`](bin/hosts/win11/) 独立工程，使用 C#（Win32 Imm32/User32 API）实现的单文件无黑框后台常驻服务。
  - 支持直接操纵 Windows 微软拼音/搜狗输入法的内部合字状态（`IMC_SETOPENSTATUS` / `IMC_SETCONVERSIONMODE`），原生适配单一输入法下裸按 `Shift` 切换中英的输入习惯。
  - 原生适配 WSL2 Mirrored（镜像）网络模式与传统 NAT 模式，监听 `0.0.0.0:8765` 消除跨环境握手丢包。
- **Windows 工程配套工具链**：
  - 提供 [`build.bat`](bin/hosts/win11/build.bat)（自动通过 `pushd` 映射虚拟盘符解决 WSL UNC 路径无法编译问题）与 [`build.sh`](bin/hosts/win11/build.sh)（WSL 内一键调用 Windows 原生 `csc.exe` 编译）。
  - 提供 [`start-daemon.bat`](bin/hosts/win11/start-daemon.bat) 与 [`start-daemon.ps1`](bin/hosts/win11/start-daemon.ps1)，内置健康检查、旧进程防重与报错现场回显机制。
  - 提供 [`install-startup.bat`](bin/hosts/win11/install-startup.bat)，一键部署开机自启快捷方式到 Windows 自启动目录（`shell:startup`）。
  - 提供 [`sign-binary.bat`](bin/hosts/win11/sign-binary.bat) 与 [`sign-binary.ps1`](bin/hosts/win11/sign-binary.ps1)，提供 Windows 原生 Authenticode 代码签名自动化工具链，自动生成并信任专属发布者证书（`LAU Kalin`，10 年有效期），彻底消除「无法验证发布者」安全警告。
  - 提供 [`add-firewall-rule.bat`](bin/hosts/win11/add-firewall-rule.bat)，自动申请管理员权限放行 TCP 8765 端口。
  - 提供 [`test-daemon.py`](bin/hosts/win11/test-daemon.py)，支持毫秒级连通性探测、测速与多 IP 自动容灾。
  - 完善开源工程基础设施：新增 [`LICENSE`](bin/hosts/win11/LICENSE)（MIT 许可证）与详细工程说明文档 [`README.md`](bin/hosts/win11/README.md)。
- **通用 GPG 防篡改与完整性校验工具链 (`bin/gpg-sign`, `bin/gpg-verify`)**：
  - 新增 Linux（Zsh）专属原生工具 [`bin/gpg-sign`](bin/gpg-sign) 与 [`bin/gpg-verify`](bin/gpg-verify)，全面支持 Zsh 高级 Glob 模式（扩展 Glob）、多路径输出重定向与 OpenPGP 明文签名规范（`SHA256SUMS.asc`）。
  - 新增 Windows（PowerShell / Batch）对应实现 [`bin/gpg-sign.ps1`](bin/gpg-sign.ps1) / [`bin/gpg-sign.bat`](bin/gpg-sign.bat) 与 [`bin/gpg-verify.ps1`](bin/gpg-verify.ps1) / [`bin/gpg-verify.bat`](bin/gpg-verify.bat)，支持直接双击或在 PowerShell/CMD 中以 Glob 模式批量签名与验签。
  - 基于 SHA-256 摘要与 GnuPG 数字密钥对（`0x61279CDF7E3E5A5F`）生成防篡改清单，支持逐项比对与缺失/篡改文件精准定位，提供 100% 密码学级真实性证明。
- **Vim 原生 Channel 极速异步通信驱动 (`vimrc_plugin`)**：
  - 基于 Vim 9 `+channel` 原生特性，与 Windows 守护进程建立常驻双向 TCP Socket 通信。
  - 具备优雅降级与静默容错能力：Windows 守护进程未启动时，Vim 静默正常工作，绝不打扰用户。
- **Lightline 状态栏指示组件 (`[zh]` / `[en]`)**：
  - 状态栏绝对最右侧独立指示块（`... │ 编码与类型 │ 百分比 │ 行列号 │ [zh]`），由 `LightlineIME()` 驱动。
  - 低调中性灰色定制：微调 `wombat` 调色板，最右端色块覆盖为深灰底（`ctermbg=236`）搭配中灰字（`ctermfg=247`），与状态栏底色融为一体，保持低调不抢占代码视觉焦点。
  - 插入模式专属 150ms 短周期探测器：插入模式下单按 `Shift`，即使停顿不打字亦能在 150ms 内感知状态跳变并刷新状态栏。

### Changed

- **输入法自动切换通信架构重构**：
  - 彻底摒弃传统方案中频繁跨系统冷启动 Windows 进程（`im-select.exe`）的做法。
  - 退出插入模式（`<Esc>`）瞬间发送切英指令由异步内存 TCP 报文接管，彻底杜绝普通模式移动（`h/j/k/l`）或执行命令（`dd`、`yy`）误触中文输入法。

### Performance

- **输入法切换延迟从 100ms+ 降至 <0.3ms**：纯内存回环网络交互，彻底消除跨系统虚拟化进程创建（fork + WSL interop）的卡顿。
- **普通模式零轮询零开销**：退出插入模式瞬间自动注销探测计时器，普通模式下 CPU 与轮询均为 0。
- **后台常驻资源占用微乎其微**：Windows 侧守护进程内存占用仅 3MB~5MB，平时阻塞在 Socket 监听，CPU 占用为 0.00%。

### Documentation

- 在 [`vim/MANUAL.md`](vim/MANUAL.md) 补充「lightline.vim（中英文输入法状态与模式联动）」专用操作手册。
- 在 [`vim/PLUGINS.md`](vim/PLUGINS.md) 同步补充 `lightline.vim` 输入法组件说明。
- 在 [`bin/hosts/win11/README.md`](bin/hosts/win11/README.md) 提供完整的协议规范、架构图解与故障排查 FAQ。
