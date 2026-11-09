# Vim 插件全览与功能归类

本文档整理了当前 dotfiles 中 `vim/pack/` 目录下的全部 **42 个 Vim 插件**（包含 `vim/pack/vendor/start/` 中的 40 个插件，以及独立包 `auto-pairs` 与 `coc.nvim`），结合项目中的 `vimrc` 和 `vimrc_plugin` 配置，按功能分类梳理其核心功能、关键快捷键与维护建议。

---

## 插件分类概览

```
vim/pack/
├── 1. 代码补全与 LSP 诊断 (3 个)
│   ├── coc.nvim, ultisnips, vim-snippets
├── 2. 文本编辑增强与对象 (6 个)
│   ├── auto-pairs, vim-surround, nerdcommenter, vim-argwrap, vim-visual-multi, gundo.vim
├── 3. 导航搜索与文件管理 (6 个)
│   ├── nerdtree, fzf.vim, vim-easymotion, incsearch.vim,
│   └── incsearch-easymotion.vim, vim-signature
├── 4. 界面美化与状态栏 (3 个)
│   ├── lightline.vim, vim-colors-solarized, vim-over
├── 5. 语言语法与文件类型支持 (16 个)
│   ├── 前端/Web: vim-js, vim-jsx-pretty, typescript-vim, vim-coffee-script, vim-liquid, smarty.vim
│   ├── 系统/通用: rust.vim, vim-markdown, vim-json, vim-toml, vimtex
│   └── 函数式/合约/求解器: haskell-vim, vim-scala, vim-racket, vim-solidity, vim-smt2
└── 6. 外部工具与工作流集成 (8 个)
    ├── vim-git, editorconfig-vim, vim-tmux, vim-vagrant, vim-bundler, vim-emmet, gist-vim, webapi-vim
```

---

## 一、代码补全与 LSP 诊断 (3 个)

| 插件名称 | 仓库地址 | 核心功能简介 |
| :--- | :--- | :--- |
| **coc.nvim** | [neoclide/coc.nvim](https://github.com/neoclide/coc.nvim) | 提供语言服务器协议（LSP）支持，包含代码补全、定义跳转、重构、实时诊断、格式化以及 Git 状态集成。 |
| **ultisnips** | [sirver/ultisnips](https://github.com/sirver/ultisnips) | 代码片段展开与编辑引擎，支持 Python 扩展语法。 |
| **vim-snippets** | [honza/vim-snippets](https://github.com/honza/vim-snippets) | 社区维护的代码片段库（包含 UltiSnips 与 SnipMate 格式）。 |

### 关键配置与快捷键
- **补全与片段（Tab 链）**：
  - `<Tab>`：补全菜单打开时向下选词；在片段内跳到下一个占位符；光标前为空白时输入缩进；其他情况触发补全
  - `<S-Tab>`：补全菜单打开时向上选词；在片段内跳到上一个占位符
  - `<CR>`：确认选中补全项
  - `<C-Space>` / `<C-@>`：手动呼出补全菜单
- **代码导航与重构**：
  - `gd` / `gy` / `gi` / `gr`：跳转到定义 / 类型定义 / 实现 / 引用
  - `K`：浮动窗口查看函数签名与文档注释
  - `<leader>rn`：符号重命名
  - `<leader>f`：格式化选中代码；`:Format`：格式化当前文件（已配置保存自动格式化）
  - `<leader>qf`：修复当前行诊断问题
  - `[g` / `]g`：上一个 / 下一个诊断前后跳转
- **Git 变更与状态（coc-git 扩展）**：
  - `[c` / `]c`：上一个 / 下一个 diff 变动块跳转
  - `[C` / `]C`：上一个 / 下一个合并冲突块跳转
  - `<leader>gp`：浮窗预览当前块改动前的 diff 对比
  - `<leader>gb`：浮窗查看当前行代码的提交记录（blame）
  - `<leader>gu`：仅撤销当前块的修改
  - `<leader>gs`：暂存当前块至暂存区（单块 git add）
  - `<leader>gd`：左右分屏对比当前文件与暂存区
- **CocList 列表面板**：
  - `<space>a`：诊断列表；`<space>o`：文件大纲；`<space>s`：搜索符号
  - `<space>c`：命令列表；`<space>e`：扩展管理；`<space>g`：改动文件列表（gstatus）

### 架构设计说明
> [!NOTE]
> - **LSP 与语法检查**：由 `coc.nvim` 统一接管各语言的 Language Server、诊断提示以及格式化流程，避免多插件并存导致的保存竞态。
> - **智能补全链**：通过 `coc-snippets` 联动 UltiSnips，将代码补全、片段展开和占位符跳转统一收敛于 `<Tab>` 键。

---

## 二、文本编辑增强与文本对象 (6 个)

| 插件名称 | 仓库地址 | 核心功能简介 |
| :--- | :--- | :--- |
| **auto-pairs** | [jiangmiao/auto-pairs](https://github.com/jiangmiao/auto-pairs) | 括号、引号等成对符号的自动闭合、自动删除与跳出。 |
| **vim-surround** | [tpope/vim-surround](https://github.com/tpope/vim-surround) | 添加、修改和删除成对的环绕符号（括号、引号、HTML/XML 标签等）。 |
| **nerdcommenter** | [preservim/nerdcommenter](https://github.com/preservim/nerdcommenter) | 快速注释与解注释代码，支持多语言语法。 |
| **vim-argwrap** | [FooSoft/vim-argwrap](https://github.com/FooSoft/vim-argwrap) | 函数参数列表、数组在单行与多行之间的换行展开与折叠。 |
| **vim-visual-multi** | [mg979/vim-visual-multi](https://github.com/mg979/vim-visual-multi) | 多光标同时编辑支持。 |
| **gundo.vim** | [sjl/gundo.vim](https://github.com/sjl/gundo.vim) | 可视化呈现 Vim 撤销树（Undo Tree），可回退至历史分支。 |

### 关键配置与快捷键
- **`auto-pairs`**：`g:AutoPairsFlyMode = 1`, `g:AutoPairsShortcutBackInsert = '<M-b>'`
- **`vim-surround`**：
  - `cs"'`：将双引号改为单引号
  - `ds"`：删除外层双引号
  - `ysiw)`：给当前单词添加括号包裹
  - Visual 模式下 `S"`：将选中区域用双引号包裹
- **`nerdcommenter`**：默认 `<leader>c<space>` 切换单行/选区注释；`<leader>cc` 强制注释
- **`vim-argwrap`**：`<leader>w` 切换光标所在参数或数组的换行展开与单行收拢
- **`vim-visual-multi`**：`<C-N>` 选中当前单词开启多光标；定制前缀 `\v`（避免与 EasyMotion 冲突），支持 `\vj` / `\vk` 垂直增列与 `\vA` 全选匹配项
- **`gundo.vim`**：`<leader>u` 打开/关闭撤销树面板

---

## 三、导航搜索与文件管理 (6 个)

| 插件名称 | 仓库地址 | 核心功能简介 |
| :--- | :--- | :--- |
| **fzf.vim** | [junegunn/fzf.vim](https://github.com/junegunn/fzf.vim) | 基于 fzf 与 ripgrep 的模糊搜索套件，提供文件、缓冲区与代码全局检索。 |
| **nerdtree** | [preservim/nerdtree](https://github.com/preservim/nerdtree) | 树状侧边栏文件管理器。 |
| **vim-easymotion** | [easymotion/vim-easymotion](https://github.com/easymotion/vim-easymotion) | 屏幕可视区域光标快速两键精准跳转。 |
| **incsearch.vim** | [haya14busa/incsearch.vim](https://github.com/haya14busa/incsearch.vim) | 渐进式搜索体验增强，打字时即时高亮匹配项。 |
| **incsearch-easymotion.vim** | [haya14busa/incsearch-easymotion.vim](https://github.com/haya14busa/incsearch-easymotion.vim) | 渐进式搜索与 EasyMotion 联动，回车后直接以字母标签跳转。 |
| **vim-signature** | [kshenoy/vim-signature](https://github.com/kshenoy/vim-signature) | 在侧边栏 SignColumn 显示与快速跳转 Vim Marks 行书签。 |

### 关键配置与快捷键
- **`fzf.vim`**：
  - `<C-p>`：查找项目文件（`:Files`），带浮窗与内容预览
  - `;`：查找并切换已打开的缓冲区（`:Buffers`）
  - `<leader>A`：全局代码内容检索（`:Rg`，调用 ripgrep）
  - `<leader>K`：快速检索光标下的词
  - 弹窗分屏手势：`Alt-v` 垂直分屏、`Alt-s` 水平分屏、`<C-t>` 标签页打开（定制 `g:fzf_action` 避开终端 Ctrl-V 粘贴冲突）
- **`nerdtree`**：`<leader>n` 打开/关闭目录树；`<leader>f` 在树中定位当前文件
- **`vim-easymotion`**：
  - `<leader><leader>s`：输入两个字符，根据屏幕出现的字母标签直达目标位置
  - `g:EasyMotion_smartcase = 1`：小写字母自动匹配大写
- **`incsearch` & `incsearch-easymotion`**：
  - `/` / `?` / `g/`：渐进式搜索并保持高亮
  - `z/` / `z?` / `zg/`：搜索后直接以 EasyMotion 字母标签跳转
- **`vim-signature`**：原生 `m[a-z]` 打标并在符号列即时显示，`]'` / `['` 跳转书签

---

## 四、界面美化与状态栏 (3 个)

| 插件名称 | 仓库地址 | 核心功能简介 |
| :--- | :--- | :--- |
| **lightline.vim** | [itchyny/lightline.vim](https://github.com/itchyny/lightline.vim) | 轻量状态栏增强插件，无重型外部依赖。 |
| **vim-colors-solarized** | [altercation/vim-colors-solarized](https://github.com/altercation/vim-colors-solarized) | Solarized 颜色方案（支持 256 色终端及 GUI）。 |
| **vim-over** | [osyo-manga/vim-over](https://github.com/osyo-manga/vim-over) | 命令行文本替换实时交互式预览。 |

### 关键配置与快捷键
- **`lightline.vim`**：
  - 状态栏集成 `gitbranch`（通过 `LightlineGit()` 整合 `coc-git` 的分支名与改动统计 `+2 ~1 -0`）
  - 状态栏集成 `cocstatus`（LSP 状态）与 `CocRoot`（当前项目根目录路径）
  - 状态栏右侧独立高亮呈现输入法状态 `[zh]` / `[en]`（由 `LightlineIME()` 驱动，退出插入模式自动切回英文）
  - 绑定 `CocStatusChange`, `CocDiagnosticChange`, `CocGitStatusChange` 与模式切换事件自动更新
- **`vim-colors-solarized`**：在 `vimrc` 中为主力配色方案，并针对暗色终端背景定制了 `SignColumn` 与 `StatusLine` 样式
- **`vim-over`**：`<leader>x` 呼出 `:OverCommandLine` 交互替换命令

---

## 五、语言语法与文件类型支持 (16 个)

为指定语言与文件类型提供精确的语法高亮（Syntax）、智能缩进（Indent）、文件类型识别（Ftdetect）以及编译配置支持。

| 插件分类 | 插件名称 | 对应语言 / 文件类型 | 说明与功能亮点 |
| :--- | :--- | :--- | :--- |
| **Web 前端** | **vim-js** | JavaScript (现代规范) | 基于 ECMAScript 规范的高亮，专为现代语法设计，与 `vim-jsx-pretty` 协同。 |
| | **vim-jsx-pretty** | React JSX / TSX | React JSX/TSX 标签高亮，与 `vim-js` 协同。 |
| | **typescript-vim** | TypeScript | TypeScript 语法高亮与基础缩进支持。 |
| | **vim-coffee-script**| CoffeeScript | CoffeeScript 高亮、编译命令与缩进。 |
| | **vim-liquid** | Liquid (Shopify/Jekyll)| Liquid 模板语法高亮。 |
| | **smarty.vim** | Smarty (PHP 模板) | PHP Smarty 模板引擎语法高亮。 |
| **通用 / 系统**| **rust.vim** | Rust | Rust 官方支持插件，提供语法高亮、格式化（`:RustFmt`）与测试。 |
| | **vim-markdown** | Markdown | Markdown 扩展语法高亮，支持代码块多语言嵌套与公式。 |
| | **vim-json** | JSON | JSON 高亮支持，提供语法错误标记及隐藏双引号（conceal）功能。 |
| | **vim-toml** | TOML | TOML 配置文件语法高亮与缩进。 |
| | **vimtex** | LaTeX / TeX | LaTeX 工具链支持（语法高亮、目录跳转、编译支持）。 |
| **函数式与专用**| **haskell-vim** | Haskell | 现代 Haskell 语法高亮、Cabal 与缩进支持。 |
| | **vim-scala** | Scala | Scala 语法支持与 ctags 符号支持。 |
| | **vim-racket** | Racket / Scheme | Racket 方言的 S-表达式缩进与高亮。 |
| | **vim-solidity** | Solidity | 以太坊智能合约开发语言语法高亮。 |
| | **vim-smt2** | SMT-LIB 2 | SMT-LIB v2 形式化验证与约束求解器脚本语法高亮。 |

---

## 六、外部工具与工作流集成 (8 个)

| 插件名称 | 仓库地址 | 核心功能简介 |
| :--- | :--- | :--- |
| **vim-git** | [tpope/vim-git](https://github.com/tpope/vim-git) | 提供 Git commit 提交信息、rebase、config、gitignore 等文件的语法高亮与格式。 |
| **editorconfig-vim** | [editorconfig/editorconfig-vim](https://github.com/editorconfig/editorconfig-vim) | 解析项目根目录下的 `.editorconfig` 文件，统一缩进风格、换行符和编码。 |
| **vim-tmux** | [tmux-plugins/vim-tmux](https://github.com/tmux-plugins/vim-tmux) | `tmux.conf` 配置文件的语法高亮与补全支持。 |
| **vim-vagrant** | [hashivim/vim-vagrant](https://github.com/hashivim/vim-vagrant) | Vagrantfile 语法高亮及在 Vim 内执行 Vagrant 命令封装。 |
| **vim-bundler** | [tpope/vim-bundler](https://github.com/tpope/vim-bundler) | Ruby Bundler 集成，支持 `:Bundle` 及在 Gemfile 中直接 `gf` 跳转到 gem 源码。 |
| **vim-emmet** | [mattn/emmet-vim](https://github.com/mattn/emmet-vim) | 前端 HTML/CSS 缩写代码展开生成工具。 |
| **gist-vim** | [mattn/gist-vim](https://github.com/mattn/gist-vim) | 在 Vim 内直接创建、更新与浏览 GitHub Gist。 |
| **webapi-vim** | [mattn/webapi-vim](https://github.com/mattn/webapi-vim) | 底层工具库：提供 HTTP 请求与 JSON/XML 编解码，供 `gist-vim` 与 `vim-emmet` 使用。 |

### 关键配置与快捷键
- **`vim-emmet`**：
  - `let g:user_emmet_leader_key='<Tab>'`
  - 针对 `java, html, css, markdown, xml, xsl, scss, sass` 自动激活
  - 自定义读取 `~/.config/emmet/snippets_custom.json`
- **`webapi-vim`**：在 `vimrc_plugin` 中用于通过 `webapi#json#decode()` 动态解析 Emmet 自定义 JSON 模板
- **工作流分工说明**：Git 缓冲区状态显示、diff 跳转、代码暂存及 blame 由 `coc-git` 统一驱动；`vim-git` 专注于 Git 相关专用配置文件的语法着色。

---

## 七、长效维护建议与备选考量

1. **Python 依赖与撤销树替代（备选）**：
   - 当前使用的 `gundo.vim` 依赖 Python3 运行环境。若希望完全剥离 Python 依赖，可无缝替换为纯 VimL 实现的社区主流插件 [undotree](https://github.com/mbbill/undotree)。
2. **CoC 扩展与 Language Server 维护**：
   - 定期在 Vim 中执行 `:CocUpdate` 保持 CoC 扩展插件（`coc-git`, `coc-snippets`, `coc-tsserver`, `coc-pyright` 等）处于最新稳定状态。
3. **行宽视觉辅助（80 列规范）**：
   - `vimrc` 中已配置第 81 列的高亮边界提示，辅助日常编辑与 Markdown 维护严格遵从 80 字符以内的排版规范。
