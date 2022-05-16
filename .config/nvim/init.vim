set background=light
set backup
set backupdir-=.
set clipboard=unnamedplus
set list
set modelineexpr
set mouse=a
set swapfile
set undofile

let g:python3_host_prog='/home/rishabh/.miniconda3/envs/pynvim/bin/python'

let g:python_highlight_builtins=1
let g:python_highlight_exceptions=1
let g:python_highlight_string_format=1
let g:python_highlight_string_formatting=1

autocmd BufWritePre *.py execute ':Black'

call plug#begin()
Plug 'farmergreg/vim-lastplace'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'psf/black', { 'branch': 'stable' }
Plug 'tpope/vim-commentary'
Plug 'vim-python/python-syntax'
Plug 'webdevel/tabulous'
call plug#end()
