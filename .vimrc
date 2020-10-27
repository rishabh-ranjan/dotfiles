" Author:   Rishabh Ranjan
" Last change: 2019 June 26

" Keep this stuff right here at the top!
" { Vundle begin (use % to go to Vundle end)
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

Plugin 'JuliaEditorSupport/julia-vim'

" YCM for auto completion
Plugin 'Valloric/YouCompleteMe'
let g:ycm_autoclose_preview_window_after_insertion = 1

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Vundle end }

" Uses settings from defaults.vim provided by vim (8.0 onward)
unlet! skip_defaults_vim
source $VIMRUNTIME/defaults.vim

" Set colorscheme
" Use gruvbox if available
if filereadable($HOME.'/.vim/colors/gruvbox.vim')
    let g:gruvbox_contrast_dark='hard'
    colorscheme gruvbox
    " Better Visual mode highlight
    autocmd Colorscheme * highlight Visual cterm=none ctermbg=237 ctermfg=none
    set background=dark
else
    colorscheme zellner
endif

" Remap <esc>
"inoremap kj <esc>
"vnoremap kj <esc>

" Remap split movements
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Alternative save using ctrl-s
inoremap <C-P> <esc>:w<return>i
nnoremap <C-P> :w<return>

" Open new split panes to right and bottom
set splitbelow
set splitright

" Use system clipboard
set clipboard=unnamed

" Numbering
set number relativenumber
inoremap <C-N> <Esc>:setlocal rnu!<Return>i
nnoremap <C-N> :setlocal rnu!<Return>

" augroup number_toggle
"     autocmd!
"     autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
"     autocmd BufLeave,FocusLost,InsertEnter * set norelativenumber
" augroup END

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

set wrap

" Coding related
" underlines matching parens
highlight MatchParen cterm=underline ctermbg=none ctermfg=none
set tabstop=2
set shiftwidth=2

" Add optional packages.
"
" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
" The ! means the package won't be loaded right away but when plugins are
" loaded during initialization.
if has('syntax') && has('eval')
  packadd! matchit
endif

" cp related
" cpp template from ./codebook/template.cpp
" TODO: use a better way to do this
inoremap <c-u> <esc>:%d <bar> r ~/cc/codebook/template.cpp<return>GA
nnoremap <c-u> <esc>:%d <bar> r ~/cc/codebook/template.cpp<return>GA

" avoid going past col #80
set cc=80
set cursorline

