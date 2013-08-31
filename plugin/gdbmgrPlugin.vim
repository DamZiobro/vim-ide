" gdbmgrPlugin.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Feb 11, 2009
"   Version: 1	ASTRO-ONLY
" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_gdbmgrPlugin")
 finish
endif
let g:loaded_gdbmgrPlugin= "v1"
let s:keepcpo      = &cpo
set cpo&vim

" ---------------------------------------------------------------------
"  Commands: {{{1
com! -nargs=*	-complete=file	GdbMgr		call gdbmgr#GdbMgrInit(<q-args>)
com  -nargs=+   -complete=file  DA			call gdbmgr#GdbMgrAttach(<q-args>)
com  -nargs=*	-complete=file	DI			call gdbmgr#GdbMgrInit(<f-args>)

" ---------------------------------------------------------------------
"  Menu: {{{1
if !exists("g:DrChipTopLvlMenu")
 let g:DrChipTopLvlMenu= "DrChip."
endif
exe 'menu '.g:DrChipTopLvlMenu.'Gdbmgr.Attach<tab>:DA	:DA '
exe 'menu '.g:DrChipTopLvlMenu.'Gdbmgr.Init<tab>:DI	:DI<cr>'

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
