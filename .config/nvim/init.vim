set background=light
set backup
set backupdir-=.
set cursorline
set list
set mouse=a
set swapfile
set undofile

call plug#begin()
Plug 'farmergreg/vim-lastplace'
Plug 'tpope/vim-commentary'
Plug 'webdevel/tabulous'
Plug 'lukas-reineke/indent-blankline.nvim'
call plug#end()