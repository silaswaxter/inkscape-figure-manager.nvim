if exists('g:loaded_inkscape_figure_manager') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

command! InkscapeFigureManagerCreate lua require'inkscape_figure_manager'.create_figure()

command! InkscapeFigureManagerEditFigureUnderCursor lua require'inkscape_figure_manager'.edit_figure_under_cursor()

command! InkscapeFigureManagerEditFirstFigureCurrentLine lua require'inkscape_figure_manager'.edit_figure_first_on_cursor_line()

"command! InkscapeFigureManagerEditFigureFromMarkdownBuffer lua require'inkscape_figure_manager'.edit_figure_from_markdown_document()

"command! InkscapeFigureManagerWatchThisBufferDirectory lua require'inkscape_figure_manager'.watch_user_buffer_directory_for_figures()
 
let &cpo = s:save_cpo " restore user coptions
unlet s:save_cpo

let g:loaded_inkscape_figure_manager = 1
