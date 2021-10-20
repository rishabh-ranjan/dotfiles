set background=light
set backup
set backupdir-=.
set list
set mouse=a
set swapfile
set undofile

let g:python_highlight_builtins=1
let g:python_highlight_exceptions=1
let g:python_highlight_string_format=1
let g:python_highlight_string_formatting=1

call plug#begin()
Plug 'farmergreg/vim-lastplace'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'tpope/vim-commentary'
Plug 'vim-python/python-syntax'
Plug 'webdevel/tabulous'
call plug#end()
