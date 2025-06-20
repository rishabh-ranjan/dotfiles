colorscheme vim
set background=light
set backup
set backupdir-=.
set cc=88
set clipboard=unnamedplus
set linebreak
set list
set mouse=a
set swapfile
set undofile

let backup_dir = stdpath('data').'/backup'
if !isdirectory(backup_dir)
	call mkdir(backup_dir, 'p', 0700)
endif

let venv_dir = $HOME.'/.local/venv/nvim'
if !isdirectory(venv_dir)
	execute '!python3 -m venv '.venv_dir
	execute '!'.venv_dir.'/bin/pip3 install pynvim black isort'
endif

let plug_path=stdpath('data').'/site/autoload/plug.vim'
if empty(glob(plug_path))
	execute '!curl -fLo '.plug_path.' --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin()
Plug 'elijahdanko/lf.vim'
Plug 'farmergreg/vim-lastplace'
Plug 'img-paste-devs/img-paste.vim'
Plug 'lervag/vimtex'
Plug 'nickeb96/fish.vim'
Plug 'psf/black'
Plug 'preservim/vim-markdown'
Plug 'rbgrouleff/bclose.vim'  " dependency of lf.vim
Plug 'tpope/vim-commentary'
Plug 'vim-python/python-syntax'
Plug 'webdevel/tabulous'
Plug 'zbirenbaum/copilot.lua'
Plug 'nvim-lua/plenary.nvim'
Plug 'CopilotC-Nvim/CopilotChat.nvim'
" Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'stsewd/isort.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'neovim/nvim-lspconfig'
Plug 'pechorin/any-jump.vim'
Plug 'wellle/context.vim'
Plug 'godlygeek/tabular'
call plug#end()

let g:isort_command = 'isort --profile black'
let g:python_highlight_builtins = 1
let g:python_highlight_exceptions = 1
let g:python_highlight_string_format = 1
let g:python_highlight_string_formatting = 1
let g:python3_host_prog = '~/.local/venv/nvim/bin/python3'
let g:tex_flavor = 'latex'
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_math = 1

augroup noindent
	autocmd!
	autocmd FileType plaintex,tex,latex,html setlocal indentexpr=
augroup end

" augroup cc_for_py
" 	autocmd!
" 	autocmd FileType python setlocal colorcolumn=88
" augroup end

augroup black_on_save
	autocmd!
	autocmd BufWritePre *.py Black
	" autocmd BufWritePre *.py Isort
augroup end

augroup plug_missing
	autocmd!
	autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
				\ | PlugInstall --sync | source $MYVIMRC | endif
augroup end

augroup img_paste
	autocmd!
	autocmd FileType * nmap <buffer><silent> <leader>p :call mdip#MarkdownClipboardImage()<CR>
augroup end

lua << EOF
require'copilot'.setup{
	suggestion = {
		auto_trigger = true,
	},
	filetypes = {
	    yaml = true,
	    markdown = true,
	    help = false,
	    gitcommit = false,
	    gitrebase = false,
	    hgcommit = false,
	    svn = false,
	    cvs = false,
	    ["."] = true,
	  },
}
require'CopilotChat'.setup{}
-- require'treesitter-context'.setup{}
-- require('lspconfig').ruff_lsp.setup{}
EOF

