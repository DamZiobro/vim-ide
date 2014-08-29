" Vim filetype plugin file
" Language:     hg log output
" Maintainer:   Ludovic Chabant <ludovic@chabant.com>

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

let b:undo_ftplugin = "setlocal cole< cocu<"

if has("conceal")
    setlocal cole=2 cocu=nc
endif

let &cpo = s:cpo_save
unlet s:cpo_save
