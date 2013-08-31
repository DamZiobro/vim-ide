" gdbmgrh.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Dec 20, 2010
"   Version: 1v	NOT RELEASED
" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_gdbmgrh")
 finish
endif
let g:loaded_gdbmgrh= "v1a"
let s:keepcpo      = &cpo
set cpo&vim
"DechoTabOn

" ---------------------------------------------------------------------
" gdbmgrh#Init: {{{2
fun! gdbmgrh#Init() dict
"  call Dfunc("gdbmgrh#Init()")
  " open a new unnamed buffer
  call gdbmgr#GdbMgrInitEnew()
  setlocal noswf bt=nofile
  " give the new buffer a name
  if !exists("g:hdrtag_winname")
   let g:hdrtag_winname= '[Hdrtag]'
  endif
  exe 'silent file '.g:hdrtag_winname
  " install <c-f6> map to support buffer (application) switching
  nmap <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
  " inform the dictionary of this applications buffer id
  let self.bufnum= bufnr("%")
  " make the buffer hide-able (so that it isn't deleted when out-of-sight),
  "                 not user modifiable, and read-only
  setlocal bh=hide noma ro
  " When hdrtag wants to select a file into a source window, use gdbmgr#ForeignAppFuncRef()
  let g:Hdrtag_funcref= function("gdbmgr#ForeignAppFuncref")
  if !exists("t:forappdict")
   let t:forappdict= {}
  endif
  let t:forappdict.h= "Hdrtag"
"  call Dret("gdbmgrh#Init : self.bufnum=".self.bufnum)
endfun

" ---------------------------------------------------------------------
" gdbmgrh#Update: srcbufnum is the buffer number of the Source buffer {{{2
fun! gdbmgrh#Update(srcbufnum) dict
"  call Dfunc("gdbmgrh#Update(srcbufnum=".a:srcbufnum.") has ".line("$")." lines")
  " let hdrtag know which window the source buffer is in
  " figure out which window the hdrtag buffer itself is in
  " record current window
  let g:hdrtag_chgwin = bufwinnr(a:srcbufnum)
  let Hbuf            = self.bufnum
  let Hwin            = bufwinnr(Hbuf)
  let curwin          = winnr()
"  call Decho("Hbuf#".Hbuf." Hwin#".Hwin." curwin#".curwin." chgwin#".g:hdrtag_chgwin."<".bufname(g:hdrtag_chgwin).">")
  if g:hdrtag_chgwin > 0 && Hwin > 0 && !exists("s:didupdate")
   " switch to hdrtag window
   exe Hwin."wincmd w"
   " make hdrtag window modifiable
   setlocal ma nomod noro
   " Tells hdrtag to (forcibly) do an initialization
   Hdrtag 2
   " restore hiding, not modifiable, read-only to hdrtag window
   setlocal bh=hide noma ro
   " install buffer switching map
   nmap <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
   " insure that the dictionary for "h" knows the associated buffer number
   let self.bufnum= bufnr("%")
   let s:didupdate= 1
"   call Decho("self.bufnum=".bufnr("%"))
   " return to current window
   exe curwin."wincmd w"
  endif
  norm! zMzx

"  call Dret("gdbmgrh#Update : has ".line("$")." lines")
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
