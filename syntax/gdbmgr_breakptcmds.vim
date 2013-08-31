" gdbmgr_breakptcmds.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Dec 15, 2010
" ---------------------------------------------------------------------
" Remove any old syntax stuff hanging around
syn clear

syn match GdbMgrBreakptsCmd_H1	'^\%1l-\+$'
syn match GdbMgrBreakptsCmd_H2	'^\%2lBreakpt.*$'	contains=GdbMgrBreakptsCmd_Nmbr
syn match GdbMgrBreakptsCmd_H3	'^\%1l-\+$'
syn match GdbMgrBreakptsCmd_Nmbr	'#\d\+'

" Highlighting
if !exists("did_gdbmgr_breakptcmd_syntax")
 let did_gdbmgr_breakptcmd_syntax= 1
 hi link GdbMgrBreakptsCmd_H1	Delimiter
 hi link GdbMgrBreakptsCmd_H2	Title
 hi link GdbMgrBreakptsCmd_H3   GdbMgrBreakptsCmd_H1	
 hi link GdbMgrBreakptsCmd_Nmbr	Number
endif
