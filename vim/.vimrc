" === Plugins ===
call plug#begin('~/.vim/plugged')

" File navigation
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdtree'

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Editing
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
Plug 'jiangmiao/auto-pairs'

" UI
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'gruvbox-community/gruvbox'

" Language support
Plug 'dense-analysis/ale'
Plug 'sheerun/vim-polyglot'

" Utility
Plug 'mbbill/undotree'
Plug 'tpope/vim-sleuth'

call plug#end()

" === General ===
set nocompatible
set encoding=utf-8
set fileencoding=utf-8
set backspace=indent,eol,start
set hidden
set autoread
set noswapfile
set nobackup
set nowritebackup
set undofile
set undodir=~/.vim/undodir
set history=1000
set updatetime=300
set timeoutlen=500
set mouse=a
set clipboard=unnamedplus

" === UI ===
set number
set relativenumber
set cursorline
set signcolumn=yes
set showmatch
set showcmd
set showmode
set laststatus=2
set ruler
set wildmenu
set wildmode=longest:list,full
set scrolloff=8
set sidescrolloff=8
set splitbelow
set splitright
set termguicolors
syntax enable
set background=dark
colorscheme gruvbox

" === Airline ===
let g:airline_powerline_fonts = 1
let g:airline_theme = 'gruvbox'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

" === Search ===
set incsearch
set hlsearch
set ignorecase
set smartcase

" === Indentation ===
set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
filetype plugin indent on

" === Performance ===
set lazyredraw
set ttyfast

" === Key mappings ===
let mapleader = " "

" Clear search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Quick save / quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize splits
nnoremap <C-Up> :resize +2<CR>
nnoremap <C-Down> :resize -2<CR>
nnoremap <C-Left> :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

" Move lines up/down in visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Keep cursor centered when scrolling
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n nzzzv
nnoremap N Nzzzv

" Better indenting (stay in visual mode)
vnoremap < <gv
vnoremap > >gv

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Yank to end of line (consistent with D and C)
nnoremap Y y$

" === Plugin keybindings ===

" NERDTree
nnoremap <leader>e :NERDTreeToggle<CR>
nnoremap <leader>nf :NERDTreeFind<CR>
let NERDTreeShowHidden = 1
let NERDTreeIgnore = ['\.git$', 'node_modules', '__pycache__']

" fzf
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fg :Rg<CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fh :History<CR>
nnoremap <leader>fl :Lines<CR>

" Fugitive (git)
nnoremap <leader>gs :Git<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gl :Git log --oneline<CR>

" Undotree
nnoremap <leader>u :UndotreeToggle<CR>

" ALE
let g:ale_fix_on_save = 1
let g:ale_sign_error = '>'
let g:ale_sign_warning = '-'
nmap <leader>an :ALENext<CR>
nmap <leader>ap :ALEPrevious<CR>

" === File type specific ===
autocmd FileType python setlocal tabstop=4 shiftwidth=4
autocmd FileType javascript,typescript,json,yaml,html,css setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType make setlocal noexpandtab

" Strip trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Return to last edit position when opening files
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
