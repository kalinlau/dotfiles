set nocompatible " not vi compatible

"------------------
" Syntax and indent
"------------------
syntax on " turn on syntax highlighting
set showmatch " show matching braces when text indicator is over them

" highlight current line, but only in active window
augroup CursorLineOnlyInActiveWindow
    autocmd!
    autocmd VimEnter,WinEnter,BufWinEnter * setlocal cursorline
    autocmd WinLeave * setlocal nocursorline
augroup END

" vim can autodetect this based on $TERM (e.g. 'xterm-256color')
" but it can be set to force 256 colors
" set t_Co=256
if has('gui_running')
    colorscheme solarized
    let g:lightline = {'colorscheme': 'solarized'}
elseif &t_Co < 256
    colorscheme default
    set nocursorline " looks bad in this mode
else
    set background=dark
    let g:solarized_termcolors=256
    colorscheme solarized
    " customized colors
    highlight SignColumn ctermbg=234
    highlight StatusLine cterm=bold ctermfg=245 ctermbg=235
    highlight StatusLineNC cterm=bold ctermfg=245 ctermbg=235
    let g:lightline = {'colorscheme': 'dark'}
    highlight SpellBad cterm=underline
    " patches
    highlight CursorLineNr cterm=NONE
endif

filetype plugin indent on " enable file type detection
set autoindent

"---------------------
" Basic editing config
"---------------------
set shortmess+=I " disable startup message
set nu " number lines
set rnu " relative line numbering
set incsearch " incremental search (as string is being typed)
set hls " highlight search
set listchars=tab:>>,nbsp:~ " set list to see tabs and non-breakable spaces
set lbr " line break
set scrolloff=5 " show lines above and below cursor (when possible)
set noshowmode " hide mode
set laststatus=2
set backspace=indent,eol,start " allow backspacing over everything
set timeout timeoutlen=1000 ttimeoutlen=100 " fix slow O inserts
set lazyredraw " skip redrawing screen in some cases
set autochdir " automatically set current dir to dir of last opened file
set hidden " allow auto-hiding of edited buffers
set history=8192 " more history
set nojoinspaces " suppress inserting two spaces between sentences
" use 4 spaces instead of tabs during formatting
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
" smart case-sensitive search
set ignorecase
set smartcase
" tab completion for files/bufferss
set wildmode=longest,list
set wildmenu
set mouse+=a " enable mouse mode (scrolling, selection, etc)
if &term =~ '^screen'
    " tmux knows the extended mouse mode
    set ttymouse=xterm2
endif
set nofoldenable " disable folding by default

"--------------------
" Misc configurations
"--------------------

" unbind keys
map <C-a> <Nop>
map <C-x> <Nop>
nmap Q <Nop>

" disable audible bell
set noerrorbells visualbell t_vb=

" open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" movement relative to display lines
nnoremap <silent> <Leader>d :call ToggleMovementByDisplayLines()<CR>
function SetMovementByDisplayLines()
    noremap <buffer> <silent> <expr> k v:count ? 'k' : 'gk'
    noremap <buffer> <silent> <expr> j v:count ? 'j' : 'gj'
    noremap <buffer> <silent> 0 g0
    noremap <buffer> <silent> $ g$
endfunction
function ToggleMovementByDisplayLines()
    if !exists('b:movement_by_display_lines')
        let b:movement_by_display_lines = 0
    endif
    if b:movement_by_display_lines
        let b:movement_by_display_lines = 0
        silent! nunmap <buffer> k
        silent! nunmap <buffer> j
        silent! nunmap <buffer> 0
        silent! nunmap <buffer> $
    else
        let b:movement_by_display_lines = 1
        call SetMovementByDisplayLines()
    endif
endfunction

" toggle relative numbering
nnoremap <A-N> :set rnu!<CR>

" save read-only files
command -nargs=0 Sudow w !sudo tee % >/dev/null

"---------------------
" Plugin configuration
"---------------------

" ----- ale -----
let g:ale_set_signs = 1
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚡'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_echo_msg_error_str = 'Error'
let g:ale_echo_msg_warning_str = 'Warning'
let g:ale_completion_enabled = 0

" Linters per filetype
let g:ale_linters = {
\   'css': ['stylelint'],
\   'html': ['htmlhint'],
\   'javascript': ['eslint'],
\   'json': ['jq'],
\   'markdown': ['markdownlint'],
\   'python': ['pylint'],
\}

" Fixers / Formatters per filetype
let g:ale_fixers = {
\   'javascript': ['prettier'],
\   'json': ['prettier'],
\   'markdown': ['prettier'],
\   'python': ['yapf'],
\}

" Fix files on save (Requires fixers configured above)
let g:ale_fix_on_save = 1 
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_save = 1

" Jump to the next/previous error
nnoremap <silent> ]e <Plug>(ale_next_error)
nnoremap <silent> [e <Plug>(ale_previous_error)

" Jump to the next/previous warning
nnoremap <silent> ]w <Plug>(ale_next_warning)
nnoremap <silent> [w <Plug>(ale_previous_warning)

" Jump to the next/previous diagnostic (error or warning)
nnoremap <silent> ]d <Plug>(ale_next_wrap)
nnoremap <silent> [d <Plug>(ale_previous_wrap)

" Automatically fix issues in the current buffer.
nnoremap <Leader><Leader>f :ALEFix<CR>

" Automatically lint issues in the current buffer.
nnoremap <Leader><Leader>l :ALELint<CR>

" Toggle ALE linting globally (on/off)
nnoremap <Leader><Leader>t :ALEToggle<CR>

" Toggle ALE linting for the current buffer (on/off)
" <Leader><Leader>T (uppercase T) for "Toggle buffer"
nnoremap <Leader><Leader>T :ALEToggleBuffer<CR>

" Show ALE information (useful for debugging and seeing active linters)
" <Leader><Leader>i for "info"
nnoremap <Leader><Leader>i :ALEInfo<CR>

" Clear diagnostics for current buffer
nnoremap <Leader><Leader>C :ALEReset<CR>
" Clear diagnostics for all buffers
nnoremap <Leader><Leader>A :ALEResetBuffer<CR> 

" ----- ag / ack.vim -----
nnoremap <Leader>a :Ack!<Space>
command -nargs=+ Gag Gcd | Ack! <args>
nnoremap K :Gag "\b<C-R><C-W>\b"<CR>:cw<CR>
if executable('ag')
    let g:ctrlp_user_command = 'ag %s -l --nocolor --hidden -g ""'
    let g:ackprg = 'ag --vimgrep'
endif

"----- argwrap -----
nnoremap <Leader>w :ArgWrap<CR>

"----- buffergator -----
let g:buffergator_suppress_keymaps = 1
nnoremap <Leader>b :BuffergatorToggle<CR>

"----- ctrlp -----
nnoremap ; :CtrlPBuffer<CR>
let g:ctrlp_switch_buffer = 0
let g:ctrlp_show_hidden = 1

" ----- emmet -----
" enable globally for any filetype.
let g:user_emmet_mode='inv'
let g:user_emmet_leader_key=','
let g:user_emmet_settings = webapi#json#decode(
\    join(readfile(expand('~/.config/emmet/snippets_custom.json')), "\n")
\)
let g:user_emmet_install_global = 0
autocmd FileType html,css,markdown,xml,xsl,scss,sass EmmetInstall

"----- easymotion -----
map <Space> <Plug>(easymotion-prefix)

"----- fugitive -----
set tags^=.git/tags;~

" fzf
set rtp+=/opt/homebrew/opt/fzf

"----- gundo -----
nnoremap <Leader>u :GundoToggle<CR>
if has('python3')
    let g:gundo_prefer_python3 = 1
endif

"----- incsearch -----
map / <Plug>(incsearch-forward)
map ? <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

"----- incsearch-easymotion -----
map z/ <Plug>(incsearch-easymotion-/)
map z? <Plug>(incsearch-easymotion-?)
map zg/ <Plug>(incsearch-easymotion-stay)

"----- nerdtree -----
nnoremap <Leader>n :NERDTreeToggle<CR>
nnoremap <Leader>f :NERDTreeFind<CR>

" exit vim if NERDTree is the only window left.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 
    \ && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

"----- vim-markdown -----
let g:markdown_fenced_languages = [
    \ 'bash=sh',
    \ 'c',
    \ 'coffee',
    \ 'erb=eruby',
    \ 'javascript',
    \ 'json',
    \ 'perl',
    \ 'python',
    \ 'ruby',
    \ 'yaml',
    \ 'go',
    \ 'racket',
    \ 'haskell',
\]
let g:markdown_syntax_conceal = 0
let g:markdown_folding = 1

" ultisnips
" Trigger configuration.
" You need to change this to something other than <tab>
" if you use one of the following:
" " - https://github.com/Valloric/YouCompleteMe
" " - https://github.com/nvim-lua/completion-nvim
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" ----- vim-over -----
noremap <Leader>x :OverCommandLine<CR>

" 80 column layout highlight
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

"---------------------
" Local customizations
"---------------------

" local customizations in ~/.vimrc_local
let $LOCALFILE=expand("~/.vimrc_local")
if filereadable($LOCALFILE)
    source $LOCALFILE
endif
