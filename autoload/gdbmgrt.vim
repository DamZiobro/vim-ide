" gdbmgrt.vim : interface to CtagExpl
"   Author: Charles E. Campbell, Jr.
"   Date:   Dec 20, 2010
"   Version: 1v	NOT RELEASED
" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_gdbmgrt")
 finish
endif
let g:loaded_gdbmgrt= "v1a"
let s:keepcpo      = &cpo
set cpo&vim

" ---------------------------------------------------------------------
" gdbmgrt#Init: {{{2
fun! gdbmgrt#Init() dict
"  call Dfunc("gdbmgrt#Init()")
  call gdbmgr#GdbMgrInitEnew()
  setlocal noswf bt=nofile
  nmap <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
  let self.bufnum= bufnr("%")
  setlocal bh=hide noma ro
  let g:CtagExpl_funcref   = function("gdbmgr#ForeignAppFuncref")
  let g:CtagExplForeground = function("gdbmgr#VimDbgForeground")
  if !exists("t:forappdict")
   let t:forappdict= {}
  endif
  let t:forappdict.t= "CtagExpl"
"  call Dret("gdbmgrt#Init : self.bufnum=".self.bufnum)
endfun

" ---------------------------------------------------------------------
" gdbmgrt#Update: srcbufnum is the buffer number of the Source buffer {{{2
fun! gdbmgrt#Update(srcbufnum) dict
"  call Dfunc("gdbmgrt#Update(srcbufnum=".a:srcbufnum.")")
  let g:CtagExpl_chgwin = bufwinnr(a:srcbufnum)
  let Tbuf              = self.bufnum
  let Twin              = bufwinnr(Tbuf)
  let curwin            = winnr()
"  call Decho("Tbuf#".Tbuf." Twin#".Twin." curwin#".curwin)
  if g:CtagExpl_chgwin > 0 && Twin > 0 && !exists("s:didupdate")
   exe Twin."wincmd w"
   setlocal ma nomod noro
   CtagExpl 2
   setlocal bh=hide noma ro
   nmap <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
   let self.bufnum= bufnr("%")
   let s:didupdate= 1
"   call Decho("self.bufnum=".bufnr("%"))
   exe curwin."wincmd w"
  endif
  norm! zMzx
"  call Dret("gdbmgrt#Update")
endfun

" ---------------------------------------------------------------------
" gdbmgrt#Foreground: {{{2
fun! gdbmgrt#Foreground()
"  call Dfunc("gdbmgrt#Foreground()")
  call gdbmgr#VimDbgForeground("t")
"  call Dret("gdbmgrt#Foreground")
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
