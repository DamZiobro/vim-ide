" gdbmgr_expr.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Oct 26, 2010
" ---------------------------------------------------------------------
" Remove any old syntax stuff hanging around
syn clear

syn match GdbMgrExpr_var	'^\s*\h\w*\s*\ze='
syn match GdbMgrExpr_equal	'='
syn match GdbMgrExpr_na		'--n/a--'
syn match GdbMgrExpr_nmbr	"-\=\d\+\%(\.\d*\)\=\%([eE][-+]\=\d\{1,3}\)\="
syn match GdbMgrExpr_nmbr	"-\=\.\d*\%([eE][-+]\=\d\{1,3}\)\="

" Highlighting
if !exists("did_gdbmgr_expr_syntax")
 let did_gdbmgr_expr_syntax= 1
 hi link GdbMgrExpr_var		Identifier
 hi link GdbMgrExpr_equal	Operator
 hi link GdbMgrExpr_na		Comment
 hi link GdbMgrExpr_nmbr	Number
endif
