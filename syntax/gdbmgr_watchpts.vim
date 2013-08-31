" gdbmgr_watchpts.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Oct 26, 2010
" ---------------------------------------------------------------------
" Remove any old syntax stuff hanging around
syn clear

syn match GdbMgrWatchpts_type	'^[arw]'					skipwhite	nextgroup=GdbMgrWatchpts_expr
syn match GdbMgrWatchpts_expr	'\S\+\ze\s*='	contained	skipwhite	nextgroup=GdbMgrWatchpts_equal
syn match GdbMgrWatchpts_equal	'='				contained	skipwhite	nextgroup=GdbMgrWatchpts_na,GdbMgrWatchpts_nmbr
syn match GdbMgrWatchpts_na		'--n/a--'		contained
syn match GdbMgrWatchpts_nmbr	"-\=\d\+\%(\.\d*\)\=\%([eE][-+]\=\d\{1,3}\)\="		contained
syn match GdbMgrWatchpts_nmbr	"-\=\.\d*\%([eE][-+]\=\d\{1,3}\)\="					contained

" Highlighting
if !exists("did_gdbmgr_watchpts_syntax")
 let did_gdbmgr_watchpts_syntax= 1
 hi link GdbMgrWatchpts_type	Statement
 hi link GdbMgrWatchpts_var		Identifier
 hi link GdbMgrWatchpts_equal	Operator
 hi link GdbMgrWatchpts_na		Comment
 hi link GdbMgrWatchpts_nmbr	Number
endif
