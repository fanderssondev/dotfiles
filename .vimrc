" set compatibility to vim only
set nocompatible

" auto wrap text that extends beyond screen
set wrap

" encoding
set encoding=utf-8

" set relative line numbers
set relativenumber

" show line numbers
set number

" change color of current line number
highlight CursorLineNr cterm=NONE gui=NONE ctermfg=White guifg=#FFFFFF

" set color of the current line
set cursorline
highlight CursorLine ctermbg=236 guibg=#303030 cterm=NONE gui=NONE

" status bar
set laststatus=2

" call the .vimrc.plug file
if filereadable(expand("~/.vimrc.plug"))
	source ~/.vimrc.plug

" CTRL+C to copy to windows clipboard
vnoremap <C-c> :w !clip.exe<CR><CR>

endif
