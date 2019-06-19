" Author:   Rishabh Ranjan
" Last change: 2019 June 17
" Add new stuff to the top

" Keep this stuff right here at the top!
" === Vundle begin ===
set nocompatible              " be iMproved, required
set encoding=utf8
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'Valloric/YouCompleteMe'
" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
" Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub
" Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
" === Vundle end ===

" Brace matching
inoremap {<cr> {<cr>}<esc>O<tab>

" Auto indent detection for python
inoremap :<cr> :<cr><tab>

" Enable mouse if available
if has('mouse')
    set mouse=a
endif

" Set colorscheme
" Use gruvbox if available
if filereadable($HOME.'/.vim/colors/gruvbox.vim')
    let g:gruvbox_contrast_dark='hard'
    colorscheme gruvbox
    set background=dark
else
    colorscheme zellner
endif

" Fix visual highlight
augroup my_highlight
    autocmd!
    autocmd ColorScheme * highlight Visual cterm=none ctermbg=237 ctermfg=none
augroup END

" Remappings
inoremap kj <esc>
vnoremap kj <esc>

" Backspace
set backspace=2

" Use system clipboard
set clipboard=unnamed

" Numbering
set number relativenumber
set ruler

augroup number_toggle
    autocmd!
    autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
    autocmd BufLeave,FocusLost,InsertEnter * set norelativenumber
augroup END

" Save undo files
if !isdirectory($HOME.'/.vim/.undo')
    call mkdir($HOME.'/.vim/.undo', 'p', 0700)
endif

set undodir=~/.vim/.undo//
set undofile

" Backup files
if !isdirectory($HOME.'/.vim/.backup')
    call mkdir($HOME.'/.vim/.backup', 'p', 0700)
endif

set backupdir=~/.vim/.backup//
set backup

" Swap files
if !isdirectory($HOME.'/.vim/.swap')
    call mkdir($HOME.'/.vim/.swap', 'p', 0700)
endif

set directory=~/.vim/.swap//
set swapfile

" Highlight searches
set hlsearch

set wrap

" Coding related

syntax on

" underlines matching parens
highlight MatchParen cterm=underline ctermbg=none ctermfg=none

" indentation
set expandtab           " enter spaces when tab is pressed
set tabstop=4
set softtabstop=4
set shiftwidth=4        " spaces to use for auto indent
set autoindent          " copy indent from current line when starting a new line

" Add optional packages.
"
" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
" The ! means the package won't be loaded right away but when plugins are
" loaded during initialization.
if has('syntax') && has('eval')
  packadd! matchit
endif

