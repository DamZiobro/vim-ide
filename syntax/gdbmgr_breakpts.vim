" gdbmgr_breakpts.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Oct 26, 2010
" ---------------------------------------------------------------------
" Remove any old syntax stuff hanging around
syn clear

syn match GdbMgrBreakpts_nmbr		'^#\d\+'
syn match GdbMgrBreakpts_breakpt	'\s\zsbreakpoint\>'
syn match GdbMgrBreakpts_tmpbreakpt	'\<tmp-breakpoint\>'
syn match GdbMgrBreakpts_colon		':'
syn match GdbMgrBreakpts_disabled	'^.*\~$'	contains=GdbMgrBreakpts_tilde
syn match GdbMgrBreakpts_tilde		'\~$'		contained

" Highlighting
if !exists("did_gdbmgr_breakpts_syntax")
 let did_gdbmgr_breakpts_syntax= 1
 hi link GdbMgrBreakpts_nmbr		Number
 hi link GdbMgrBreakpts_breakpt		Identifier
 hi link GdbMgrBreakpts_tmpbreakpt 	Type
 hi link GdbMgrBreakpts_colon		Delimiter
 hi link GdbMgrBreakpts_disabled	Normal
 hi link GdbMgrBreakpts_tilde		Ignore
endif
