" gdbmgr_funcstack.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Oct 26, 2010
" ---------------------------------------------------------------------
" Remove any old syntax stuff hanging around
syn clear

syn match	GdbMgrFuncstack_Depth	'^#\d\+'
syn match	GdbMgrFuncstack_In		'\<in\>'						skipwhite	nextgroup=GdbMgrFuncstack_Func
syn match	GdbMgrFuncstack_Func	'\<\h\w*\>'			contained
syn match	GdbMgrFuncstack_At		'\<at\>'						skipwhite	nextgroup=GdbMgrFuncstack_File
syn match	GdbMgrFuncstack_File	'\h[a-zA-z0-9_.]*'	contained				nextgroup=GdbMgrFuncstack_Colon
syn match	GdbMgrFuncstack_Colon	':'					contained				nextgroup=GdbMgrFuncstack_LineNum
syn match	GdbMgrFuncstack_LineNum	'\d\+$'				contained

" Highlighting
if !exists("did_gdbmgr_funcstack_syntax")
 let did_gdbmgr_funcstack_syntax= 1
 hi  link GdbMgrFuncstack_Depth		Number
 hi  link GdbMgrFuncstack_Func		Identifier
 hi  link GdbMgrFuncstack_File		Identifier
 hi  link GdbMgrFuncstack_Colon		Delimiter
 hi  link GdbMgrFuncstack_LineNum	Number
endif

