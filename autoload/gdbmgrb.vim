" gdbmgrb.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Dec 20, 2010
"   Version: 1v	NOT RELEASED
" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_gdbmgrb")
 finish
endif
let g:loaded_gdbmgrb= "v1a"
let s:keepcpo      = &cpo
set cpo&vim
"DechoRemOn

" ---------------------------------------------------------------------
" gdbmgrb#Init: {{{2
fun! gdbmgrb#Init() dict
"  call Dfunc("gdbmgrb#Init()")
  " open a new unnamed buffer
  call gdbmgr#GdbMgrInitEnew()
  setlocal noswf bt=nofile
  " give the new buffer a name
  if !exists("g:bufexpl_winname")
   let g:bufexpl_winname= '[BufExplorer]'
  endif
  exe 'silent file '.g:bufexpl_winname
  " install <c-f6> map to support buffer (application) switching
  nmap <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
  " inform the dictionary of this applications buffer id
  let self.bufnum= bufnr("%")
  " make the buffer hide-able (so that it isn't deleted when out-of-sight),
  "                 not user modifiable, and read-only
  setlocal bh=hide noma ro
  " When hdrtag wants to select a file into a source window, use gdbmgr#ForeignAppFuncRef()
  let g:BufExplorerFuncRef    = function("gdbmgr#ForeignAppFuncref")
  let g:bufExplorerFindActive = 0
  if !exists("t:forappdict")
   let t:forappdict= {}
  endif
  let t:forappdict.b= "Bufexplorer"
"  call Dret("gdbmgrb#Init : self.bufnum=".self.bufnum)
endfun

" ---------------------------------------------------------------------
" gdbmgrb#Update: srcbufnum is the buffer number of the Source buffer {{{2
fun! gdbmgrb#Update(srcbufnum) dict
"  call Dfunc("gdbmgrb#Update(srcbufnum=".a:srcbufnum.") has ".line("$")." lines")
  " let hdrtag know which window the source buffer is in
  " figure out which window the hdrtag buffer itself is in
  " record current window
  let g:bufExplorerChgWin = bufwinnr(a:srcbufnum)
  let Bbuf                = self.bufnum
  let Bwin                = bufwinnr(Bbuf)
  let curwin              = winnr()
"  call Decho("Bbuf#".Bbuf." Bwin#".Bwin." curwin#".curwin." chgwin#".g:bufExplorerChgWin."<".bufname(g:bufExplorerChgWin)."> s:didupdate".(exists("s:didupdate")? "=".s:didupdate : "<n/a>"))
  if g:bufExplorerChgWin > 0 && Bwin > 0
   if !exists("s:didupdate")
	" initial update
"	call Decho("initial update")
    " switch to bufexpl window
    exe Bwin."wincmd w"
    " make bufexpl window modifiable
    setlocal ma nomod noro
    " Tells bufexpl to initialize the window
    BufExplorer
    " restore hiding, not modifiable, read-only to bufexpl window
    setlocal bh=hide noma ro
    " install buffer switching map
    nmap <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
    " insure that the dictionary for "b" knows the associated buffer number
    let self.bufnum= bufnr("%")
    let s:didupdate= 1
"    call Decho("self.bufnum=".bufnr("%"))
    " return to current window
    exe curwin."wincmd w"
   else
"	call Decho("not-initial update")
    " switch to bufexpl window
    exe Bwin."wincmd w"
    " make bufexpl window modifiable
    setlocal ma nomod noro
    " Tells bufexpl to initialize the window
    BufExplorer
   endif
  endif
  norm! zMzx

"  call Dret("gdbmgrb#Update : has ".line("$")." lines")
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
