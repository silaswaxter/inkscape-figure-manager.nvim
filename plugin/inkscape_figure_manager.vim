if exists('g:loaded_inkscape_figure_manager') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
command! InkscapeFigureManagerCreate lua require'inkscape_figure_manager'.create_figure_open()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_inkscape_figure_manager = 1
