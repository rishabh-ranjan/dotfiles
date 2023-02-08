set background=light
set backup
set backupdir-=.
set clipboard=unnamedplus
set linebreak
set list
set mouse=a
set swapfile
set undofile
set wrap

let backup_dir = stdpath('data').'/backup'
if !isdirectory(backup_dir)
	call mkdir(backup_dir, 'p', 0700)
endif

let venv_dir = $HOME.'/.local/venv/nvim'
if !isdirectory(venv_dir)
	execute '!python3 -m venv '.venv_dir
	execute '!'.venv_dir.'/bin/pip3 install pynvim black'
endif

let g:python3_host_prog = '~/.local/venv/nvim/bin/python3'

let plug_path=stdpath('data').'/site/autoload/plug.vim'
if empty(glob(plug_path))
        execute '!curl -fLo '.plug_path.' --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin()
Plug 'farmergreg/vim-lastplace'
Plug 'godlygeek/tabular'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'nickeb96/fish.vim'
Plug 'psf/black', { 'branch': 'stable' }
Plug 'preservim/vim-markdown'
Plug 'tpope/vim-commentary'
Plug 'vim-python/python-syntax'
Plug 'webdevel/tabulous'
call plug#end()

let g:python_highlight_builtins = 1
let g:python_highlight_exceptions = 1
let g:python_highlight_string_format = 1
let g:python_highlight_string_formatting = 1
let g:tabulousLabelNameOptions = ''
let g:tex_flavor = 'latex'
let g:vim_markdown_math = 1

augroup noindent_for_tex
	autocmd!
	autocmd FileType plaintex,tex,latex setlocal indentexpr=
augroup end

augroup black_on_save
	autocmd!
	autocmd BufWritePre *.py Black
augroup end

augroup tabularize_on_save
	autocmd!
	autocmd BufWritePre *.tex Tabularize /&
augroup end

augroup plug_missing
	autocmd!
	autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
				\ | PlugInstall --sync | source $MYVIMRC | endif
augroup end

