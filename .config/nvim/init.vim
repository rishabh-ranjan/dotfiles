set background=light
set backup
set backupdir-=.
set list
set modelineexpr
set mouse=a
set swapfile
set undofile

let dir=stdpath('data').'/backup'
if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
endif

let path=stdpath('data').'/site/autoload/plug.vim'
if empty(glob(path))
        execute '!curl -fLo '.path.' --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

let g:python3_host_prog='/home/rishabh/.miniconda3/envs/pynvim/bin/python'

autocmd BufWritePre *.py execute ':Black'

let g:python_highlight_builtins=1
let g:python_highlight_exceptions=1
let g:python_highlight_string_format=1
let g:python_highlight_string_formatting=1

call plug#begin()
Plug 'farmergreg/vim-lastplace'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'psf/black', { 'branch': 'stable' }
Plug 'tpope/vim-commentary'
Plug 'vim-python/python-syntax'
Plug 'webdevel/tabulous'
call plug#end()
