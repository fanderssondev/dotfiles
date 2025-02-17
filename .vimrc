" set compatibility to vim only
set nocompatible

" auto wrap text that extends beyond screen
set wrap

" encoding
set encoding=utf-8

" show line numbers
"set number

" set relative line numbers
set relativenumber

" status bar
set laststatus=2

" call the .vimrc.plug file
if filereadable(expand("~/.vimrc.plug"))
	source ~/.vimrc.plug
endif
