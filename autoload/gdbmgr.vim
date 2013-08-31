" gdbmgr.vim
"   Author: Charles E. Campbell, Jr.  <NdrOchip@ScampbellPfamily.AbizM - NOSPAM>
"   Date:   Jun 18, 2012
"   Version: 1
"redraw!|call DechoSep()|call inputsave()|call input("Press <cr> to continue")|call inputrestore()
"  John 4:10 : Jesus answered her, "If you knew the gift of God, and who it
"              is who says to you, 'Give me a drink,' you would have asked him, and he
"              would have given you living water." 
" GetLatestVimScripts: 4104 1 gdbmgr.vim
" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_gdbmgr")
 finish
endif
let g:loaded_gdbmgr = "v1"
let s:keepcpo            = &cpo
set cpo&vim
"DechoRemOn

" =====================================================================
" Options: {{{1
if !exists("g:gdbmgr_poll")
 let g:gdbmgr_poll= 1
endif
if !exists("g:gdbmgr_clearansi")
 let g:gdbmgr_clearansi= 1
endif
if !exists("g:DrChipTopLvlMenu")
 let g:DrChipTopLvlMenu= "DrChip"
endif
if exists("g:gdbmgr_use_server")
 let s:server= "server "
 let s:output= "output "
else
 let s:server= ""
 let s:output= "p "
endif

" =====================================================================
"  Functions: {{{1

" ---------------------------------------------------------------------
" s:AssemblyInit: {{{2
fun! s:AssemblyInit() dict
"  call Dfunc("s:AssemblyInit()")
  call gdbmgr#GdbMgrInitEnew()
  set ft=asm
  sil file Assembly
  setlocal nobuflisted bh=hide bt=nofile
  let self.bufnum= bufnr("%")
  call s:GdbMgrOptionSafe()
"  call Decho('(AssemblyInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn <buffer> <silent> <F1>			:he gdbmgr-assembly<cr>
  nn <buffer> <silent> <c-F6>		:call gdbmgr#BufSwitch()<cr>
  nn <buffer> <silent> <c-up>		:<c-u>call <SID>FuncstackChgline(v:count1)<cr>
  nn <buffer> <silent> <c-down>		:<c-u>call <SID>FuncstackChgline(-v:count1)<cr>
  nn <buffer> <silent> c			:<c-u>call gdbmgr#GdbMgrCmd("c")<cr>
  nn <buffer> <silent> n			:<c-u>call gdbmgr#GdbMgrCmd("ni ".v:count1)<cr>
  nn <buffer> <silent> s			:<c-u>call gdbmgr#GdbMgrCmd("si ".v:count1)<cr>
  nn <buffer> <silent> <c-l>		:<c-u>call <SID>AssemblyUserUpdate()<cr>
"  call Dret("s:AssemblyInit : bufnum#".self.bufnum)
endfun

" ---------------------------------------------------------------------
" s:AssemblyUpdate: updates the Assembly buffer {{{2
fun! s:AssemblyUpdate() dict
"  call Dfunc("s:AssemblyUpdate()")

  if exists("t:gdbmgrtab")

   " edit the Assembly buffer
   if s:GdbMgrOpenCodedBuf("A") == 0
"	call Dret("s:AssemblyUpdate : no assembly window available")
    return
   endif

   " place the cursor on the current instruction
"   call Decho("place the cursor on the current instruction")
   let curaddr= '^=>\s'
"   let curaddr= s:GdbMgrSend(32,"gmGdb",s:server."display $pc")
"   call Decho("curaddr: ".curaddr)
"   let curaddr= substitute(curaddr,'^.*0x\(\S\+\s\+\)<\S\+>.*$','0x0*\1','')
"   call Decho("curaddr search pattern<".curaddr.">")
   norm! 0

   if search(curaddr,'cw') <= 0
	" unable to find current address in current Assembly buffer
	" reload the buffer
"	call Decho("unable to find current address in current Assembly buffer; reloading it")

    " clean leading newlines and multiple contiguous newlines
    let mesg = s:GdbMgrSend(33,"gmGdb",s:server."disassemble /m")
    let mesg = s:GdbMgrMesgFix(mesg)
    let mesg     = substitute(mesg,'^\n\+','','g')
    let mesg     = substitute(mesg,'\n\{2,}','\n','g')
"    call Decho("cleaned mesg<".mesg.">")
    let mesglist = split(mesg,"\n")

    " clear the threads buffer and make it editable
"    call Decho("clear Assembly's buffer and make it editable")
    setlocal nobuflisted ma noro bh=hide bt=nofile
    sil keepj %d
    let lzkeep= &lz
    set lz

    " display disassembled code
"	call Decho("install disassembled code into Assembly buffer")
    call setline(1,mesglist)
    sil! g/^[* ]/j
    keepj $

    " have the current line be atop the pc
	let curaddrsearch= search(curaddr,'cw')
	if curaddrsearch <= 0
"	 call Decho("unable to find curaddr<".curaddr."> in Assembly buffer! (search returned ".curaddrsearch.")")
	endif
    redraw

    " make Assembly buffer not-editable
"	call Decho("making Assembly buffer not-editable  (curaddrsearch=".curaddrsearch.")")
    let &lz= lzkeep
    setlocal noma ro cul nomod
   else
"	call Decho("placed cursor on current line in Assembly window")
   endif
   " gdbmgr-close the Assembly buffer
   call s:GdbMgrCloseCodedBuf()
  endif
"  call Dret("s:AssemblyUpdate")
endfun

" ---------------------------------------------------------------------
" s:AssemblyUserUpdate: the user has manually requested an update {{{2
fun! s:AssemblyUserUpdate()
"  call Dfunc("s:AssemblyUserUpdate()")
  call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
  call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("manually updated assembly window")
"  call Dret("s:AssemblyUserUpdate")
endfun

" ---------------------------------------------------------------------
" s:BreakptInit: {{{2
fun! s:BreakptInit() dict
"  call Dfunc("s:BreakptInit()")
  call gdbmgr#GdbMgrInitEnew()
  set ft=gdbmgr_breakpts
  sil file Breakpoints
  setlocal nobuflisted bh=hide bt=nofile
  let self.bufnum= bufnr("%")
  call s:GdbMgrOptionSafe()
"  call Decho('(BreakptInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn <buffer> <silent> <F1>		:he gdbmgr-breakpt<cr>
  nn <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
  nn <buffer> <silent> <F6>		:call <SID>BreakptAble()<cr>
  nn <buffer> <silent> c		:call <SID>BreakptCmd()<cr>
"  call Dret("s:BreakptInit : bufnum#".self.bufnum)
endfun

" ---------------------------------------------------------------------
" s:BreakptUpdate: {{{2
fun! s:BreakptUpdate() dict
"  call Dfunc("s:BreakptUpdate()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:BreakptUpdate : gdbmgr never initialized")
   return
  endif

  " prepare to edit Breakpoints window
  if s:GdbMgrOpenCodedBuf("B") == 0
"   call Dret("s:BreakptUpdate : no breakpoints window available")
   return
  endif

  " get breakpoint info from gdb
  let mesg = s:GdbMgrSend(1,"gmGdb",s:server."info breakpoints")
  let mesg = s:GdbMgrMesgFix(mesg)

  " message cleanup
  let mesg= substitute(mesg,'\n\{2,}','\n','g')

  if mesg =~ "gdb not responding as expected"
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
"   call Dret("s:BreakptUpdate : ".mesg)
   return
  endif
  let mesglist = split(mesg,"\n")

  " clear the buffer and make it editable
  setlocal ma noro
  sil keepj %d

  if exists("t:breakptdict")
   unlet t:breakptdict
  endif
  let t:breakptdict = {}
  if mesg =~ "No breakpoints or watchpoints"
   call setline(1,substitute(mesg,'\n\+$','',''))
  else
   let iline= 1
   for mesg in mesglist
"	call Decho("(s:BreakptUpdate) mesg<".mesg.">")
	if mesg =~ '^Num\s\+Type' || mesg =~ 'watchpoint' || mesg =~ 'already hit'
     continue
    endif
	if mesg !~ '\<breakpoint\>'
	 continue
	endif
"    call Decho("mesg<".mesg.">")
    let brknum = substitute(mesg,'^\s*\(\d\+\)\s*\(\S\+\)\s.* at \(\S\+\):\(\d\+\).*$','\1','')
    let brktype= substitute(mesg,'^\s*\(\d\+\)\s*\(\S\+\)\s.* at \(\S\+\):\(\d\+\).*$','\2','')
    let brkfile= substitute(mesg,'^\s*\(\d\+\)\s*\(\S\+\)\s.* at \(\S\+\):\(\d\+\).*$','\3','')
    let brkline= substitute(mesg,'^\s*\(\d\+\)\s*\(\S\+\)\s.* at \(\S\+\):\(\d\+\).*$','\4','')
	let brkdis = (mesg =~ '\s\+n\s\+0x')
"	call Decho("brknum#".brknum." brktype<".brktype."> brkfile<".brkfile."> brkline#".brkline." brkdis=".brkdis)
	if mesg =~ '\<del\>'
	 call setline(iline,printf("#%-3d %15s %15s:%d%s",brknum,"tmp-".brktype,simplify(brkfile),brkline,(brkdis? " ~" : "")))
	else
	 call setline(iline,printf("#%-3d %15s %15s:%d%s",brknum,brktype,simplify(brkfile),brkline,(brkdis? " ~" : "")))
	endif
    let t:breakptdict[simplify(brkfile).':'.brkline] = brknum
    let iline                                        = iline + 1
   endfor
  endif

  keepj $
  setlocal noma ro cul nomod
  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:BreakptUpdate")
endfun

" ---------------------------------------------------------------------
" s:BreakptPollCheck: check if polling should continue {{{2
"    The user may associate commands with breakpoints.
"    There are three possibilities for what gdb produces.
"      Handled by:   =gdbmgr.c
"                   C=CmdPoll
"                   B=BreakptPollCheck
"                   U=BreakptUpdate
"    ++--------------------++-----------------------++--------------------++
"    || No Commands        || Commands, no continue || Commands, continue ||
"    ++-+------------------++-+---------------------++-+------------------++
"    ||C|^Z^Zbreakpoint #  ||C|^Z^Zbreakpoint #     ||C|^Z^Zbreakpoint #  || 
"    || |Breakpoint #,     || |Breakpoint #,        || |Breakpoint #,     ||
"    ++-+------------------++-+---------------------++-+------------------++ 
"    || |^Z^Zframe-begin...|| |^Z^Zframe-begin...   || |^Z^Zframe-begin...||
"    || |(where)           || |(where)              || |(where)           ||
"    || |^Z^Zsource ...    || |^Z^Zsource ...       || |^Z^Zsource ...    ||
"    || |^Z^Zstopped       || |^Z^Zstopped          || |^Z^Zstopped       ||
"    ||B|^Z^Zpre-prompt    ||B|$1=...               ||B|$1=...            ||
"    ||U|                  ||B|$2=...               ||B|$2=...            ||
"    || |                  || |...                  || |...               ||
"    || |                  ||U|^Z^Zpre-prompt       ||C|^Z^Zstarting      ||
"    ++-+------------------++-+---------------------++-+------------------++
"    ||     Returns 0      ||     Returns 0         ||    Returns 1       ||
"    ++-+------------------++-+---------------------++-+------------------++
fun! s:BreakptPollCheck(mesg)
"  call Dfunc("s:BreakptPollCheck(mesg<".a:mesg.">)")
  let mesg     = a:mesg
  let mesg     = s:GdbMgrMesgFix(mesg)
  let starting = "\x1A"."\x1A".'starting'

  " message cleanup
  let mesg= substitute(mesg,'\n\{2,}','\n','g')

  if mesg =~ "gdb not responding as expected"
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
"   call Dret("s:BreakptPollCheck 0 : ".mesg)
   return 0
  endif
  if mesg !~ '^..breakpoint \d\+\n*$'
   " unexpected message
"   call Dret("s:BreakptPollCheck 0 : unexpected mesg<".mesg.">")
   return 0
   break
  endif

  " expected: <c-z><c-z>Breakpoint #,
  let mesg = s:GdbMgrSend(1,"gmGdb",s:server."-empty-string-")
  let mesg = s:GdbMgrMesgFix(mesg)
  let mesg = substitute(mesg,'\n\{2,}','\n','g')
"  call Decho("rcvd expected mesg<".mesg.">")

  if mesg =~ starting
   " looks like a continue may have been in a breakpoints command list
   keepj $
   setlocal noma ro cul nomod
   call s:GdbMgrCloseCodedBuf()
"   call Dret("s:BreakptPollCheck 1 : [starting] encountered")
   return 1
  endif

"  call Dret("s:BreakptPollCheck 0 : ".mesg)
  return 0
endfun

" ---------------------------------------------------------------------
" s:BreakptToggle: this routine is called via a function key {{{2
fun! s:BreakptToggle()
"  call Dfunc("s:BreakptToggle()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:BreakptToggle : gdbmgr never initialized")
   return
  endif

  " get the current filename and line number where a breakpoint is to be installed/cleared
  let curfile = simplify(expand("%"))
  let curline = line(".")
"  call Decho("curfile<".curfile."> curline#".curline)

  " edit breakpoint buffer
  if s:GdbMgrOpenCodedBuf("B") == 0
   " update breakpoint signs
   call s:SourceSigns()
"   call Dret("s:BreakptToggle")
   return
  endif

"  call Decho("t:breakptdict".(exists("t:breakptdict")? string(t:breakptdict) : "<doesn't exist>"))
  if exists("t:breakptdict['".curfile.":".curline."']")
   " clear a breakpoint
"   call Decho("clear a breakpoint")
   call gdbmgr#GdbMgrCmd("clear ".curfile.":".curline,1)
  else
   " install a new breakpoint
"   call Decho("install new breakpoint")
   call gdbmgr#GdbMgrCmd("b ".curfile.":".curline,1)
  endif

  " update breakpoint signs
  call s:SourceSigns()

  " return to originating window
  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:BreakptToggle")
endfun

" ---------------------------------------------------------------------
" s:BreakptTemp: sets up a temporary breakpoint {{{2
fun! s:BreakptTemp()
"  call Dfunc("s:BreakptTemp()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:BreakptTemp : gdbmgr never initialized")
   return
  endif

  let curfile = simplify(expand("%"))
  let curline = line(".")

  if exists("t:breakptdict['".curfile.":".curline."']")
   " clear a breakpoint (not just temporary breakpoints)
"   call Decho("clearing breakpoint")
   call gdbmgr#GdbMgrCmd("clear ".expand("%").":".line("."),1)
  else
   " install a new temporary breakpoint
"   call Decho("installing temporary breakpoint")
   call gdbmgr#GdbMgrCmd("tbreak ".expand("%").":".line("."),1)
  endif

  " update breakpoint signs
  call s:SourceSigns()

"  call Dret("s:BreakptTemp")
endfun

" ---------------------------------------------------------------------
" s:BreakptAble: disables/enables breakpoint under cursor {{{2
fun! s:BreakptAble()
"  call Dfunc("s:BreakptAble()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:BreakptAble : gdbmgr never initialized")
   return
  endif

  let brkcmd= getline(".")
  let brknum= substitute(brkcmd,'^#\(\d\+\)\s.*$','\1','')
"  call Decho("brkcmd<".brkcmd.">")
"  call Decho("brknum#".brknum)

  setlocal ma noro
  if brkcmd =~ '\~$'
   " enable breakpoint on current line
   let mesg = s:GdbMgrSend(34,"gmGdb",s:server."enable ".brknum)
   call setline(".",substitute(brkcmd,' \~$','',''))
  else
   " disable breakpoint on current line
   let mesg = s:GdbMgrSend(35,"gmGdb",s:server."disable ".brknum)
   call setline(".",brkcmd.' ~')
  endif
  setlocal nomod noma ro
  call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)

  " update breakpoint signs
  call s:SourceSigns()

"  call Dret("s:BreakptAble")
endfun

" ---------------------------------------------------------------------
" s:BreakptCmd: permits one to assign one or more commands to the breakpoint under the cursor {{{2
fun! s:BreakptCmd()
"  call Dfunc("s:BreakptCmd() <".getline(".").">")
  " must have +clientserver for this to work
  if !has("clientserver")
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** clientserver not supported by your vim")
"   call Dret("s:BreakptCmd")
   return
  endif

  let brkptnum= substitute(getline("."),'^#\(\d\+\).\{-}$','\1','')
"  call Decho("brkptnum=".brkptnum)
  if brkptnum =~ '^\d\+$'

   " get breakpoint info from gdb
   let mesg = s:GdbMgrSend(1,"gmGdb",s:server."info breakpoints")
   let mesg = s:GdbMgrMesgFix(mesg)
   let mesg = substitute(mesg,'\n\{2,}','\n','g')
   if mesg =~ "gdb not responding as expected"
    call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
"    call Dret("s:BreakptCmd : ".mesg)
    return
   endif
   let mesglist = split(mesg,"\n")
"   call Decho("mesglist".string(mesglist))

   " start up remote GdbmgrBreakptCmds server
   if serverlist() !~ '\<GdbMgrBreakptCmds\>'
    call system("gvim --servername GdbMgrBreakptCmds")
   endif

   " initialize GdbmgrBreakptCmds contents
   while 1
	try
	 call remote_send("GdbMgrBreakptCmds",':set ft=gdbmgr_breakptcmd fo-=at'."\<cr>")
	 break
	catch /^Vim\%((\a\+)\)\=:E241/
	 sleep 200m
	endtry
   endwhile
   call remote_send("GdbMgrBreakptCmds",":put ='--------------'\<cr>")
   call remote_send("GdbMgrBreakptCmds",":put ='Breakpt#".brkptnum." Cmds'\<cr>")
   call remote_send("GdbMgrBreakptCmds",":put ='--------------'\<cr>")
   call remote_send("GdbMgrBreakptCmds","1GddG")
   call remote_send("GdbMgrBreakptCmds",":set nonu ch=1 fo=n2croql nosi noai nomod\<cr>")
   call remote_send("GdbMgrBreakptCmds",':syn on'."\<cr>")
   call remote_send("GdbMgrBreakptCmds",':file Breakpt\#'.brkptnum.'\ Commands'."\<cr>")
   call remote_send("GdbMgrBreakptCmds",':au BufWriteCmd * :call server2client(expand("<client>"),string(getline(4,line("$"))))|set nomod|q'."\<cr>","serverid")
   " load the remote breakptcmds gvim with current commands
   if len(mesglist) > 0
"	call Decho("load remote breakptcmds gvim with current commands")
    let iline    = 4
	let sndit    = 0
    for bpc in mesglist
"	 call Decho("iline#".iline." bpc<".bpc."> sndit=".sndit)
	 if bpc =~ '^'.brkptnum.'\>'
	  let sndit= 1
	 elseif bpc =~ '^\d'
	  let sndit= 0
	  continue
	 elseif bpc =~ 'breakpoint already hit'
	  continue
	 elseif sndit
	  let bpc= substitute(bpc,'^\s\+','','')
"	  call Decho("sending<:call setline(".iline.",'".bpc."')")
      call remote_send("GdbMgrBreakptCmds",':call setline('.iline.",'".bpc."')\n")
      let iline= iline + 1
	 endif
    endfor
"	call Decho("wrote ".(iline-4)." commands to GdbMgrBreakptCmds")
	call remote_send("GdbMgrBreakptCmds",":setlocal nomod\n")
   endif
   " clear the remote command line
   call remote_send("GdbMgrBreakptCmds",':'."\<cr>")
   " get gdb commands from server and send them along to gdb
   sil! let reply= remote_read(serverid)
"   call Decho("reply<".reply.">")
   if reply != ""
	exe "let replylist=".reply
   endif
   let mesg = s:GdbMgrSend(36,"gmGdb",s:server."commands ".brkptnum)
   if exists("replylist") && len(replylist) > 0
	for cmd in replylist
"	 call Decho("sending cmd<".cmd.">")
	 let mesg = s:GdbMgrSend(37,"gmGdb",cmd)
	endfor
   endif
   let mesg = s:GdbMgrSend(38,"gmGdb",s:server."end")
  endif
"  call Dret("s:BreakptCmd")
endfun

" ---------------------------------------------------------------------
" s:CheckptInit: responsible for initializing the checkpoints buffer {{{2
fun! s:CheckptInit() dict
"  call Dfunc("s:CheckptInit()")
  call gdbmgr#GdbMgrInitEnew()
  set ft=gdbmgr_checkpt
  call s:GdbMgrOptionSafe()
  sil! file Checkpts
  setlocal nobuflisted ro bh=hide bt=nofile
  let self.bufnum= bufnr("%")
  nn <buffer> <silent> <F1>				:he gdbmgr-checkpts<cr>
  nn <buffer> <silent> <cr>				:call <SID>CheckptRestart()<cr>
  nn <buffer> <silent> <del>			:call <SID>CheckptDelete()<cr>
  nn <buffer> <silent> <c-F6>			:call gdbmgr#BufSwitch()<cr>
  nn <buffer> <silent> <2-leftmouse>	:<c-u><leftmouse>call <SID>CheckptRestart()<cr>
  nn <buffer> <silent> <s-F7>			:<c-u>call <SID>CheckptSave()<cr>
"  call Dret("s:CheckptInit")
endfun

" ---------------------------------------------------------------------
" s:CheckptUpdate: updates the Checkpts buffer {{{2
fun! s:CheckptUpdate() dict
"  call Dfunc("s:CheckptUpdate()")
  if exists("t:gdbmgrtab")

   " edit the Checkpts buffer
   if s:GdbMgrOpenCodedBuf("H") == 0
"	call Dret("s:CheckptUpdate : no threads window available")
    return
   endif

   let mesg = s:GdbMgrSend(7,"gmGdb",s:server."info checkpoints")
   let mesg = s:GdbMgrMesgFix(mesg)

   " clean leading newlines and multiple contiguous newlines
   let mesg     = substitute(mesg,'^\n\+','','g')
   let mesg     = substitute(mesg,'\n\{2,}','\n','g')
"   call Decho("cleaned mesg<".mesg.">")
   let mesglist = split(mesg,"\n")

   " clear the checkpoints buffer and make it editable
"   call Decho("clear Checkpts buffer and make it editable")
   setlocal nobuflisted ma noro bh=hide bt=nofile
   sil keepj %d
   let lzkeep= &lz
   set lz

   " install checkpoint information into Checkpts buffer
"   call Decho("install thread information into Checkpts buffer")
"   call Decho("mesglist".string(mesglist))
   call setline(1,mesglist)
   sil! g/^[* ]/j
   keepj $
   redraw
   let &lz= lzkeep

   " make it not-editable and close the buffer
   setlocal noma ro cul nomod
   call s:GdbMgrCloseCodedBuf()

  endif
"  call Dret("s:CheckptUpdate")
endfun

" ---------------------------------------------------------------------
" s:CheckptSave: save a new checkpoint {{{2
fun! s:CheckptSave()
"  call Dfunc("s:CheckptSave()")
  if exists("t:gdbmgrtab")
   let mesg = s:GdbMgrSend(7,"gmGdb",s:server."checkpoint")
   let mesg = s:GdbMgrMesgFix(mesg)
   call s:gdbmgr_registry_{t:gdbmgrtab}["H"].Update()
  endif
"  call Dret("s:CheckptSave")
endfun

" ---------------------------------------------------------------------
" s:CheckptRestart: called to select the desired checkpoint for restart (via the <cr> map set up in s:CheckptInit) {{{2
fun! s:CheckptRestart()
"  call Dfunc("s:CheckptRestart()")

  if exists("t:gdbmgrtab")

   " edit the Checkpts buffer
   if s:GdbMgrOpenCodedBuf("H") == 0
"    call Dret("s:FuncstackUpdate : no funcstack window")
    return
   endif
   let curline= getline(".")
   let linenum= line(".")
   if curline =~ '^\s*\d\+'
	let pick= substitute(curline,'^\s*\(\d\+\)\s.*$','\1','')
	if pick =~ '^\d\+$'
"	 call Decho("restarting with checkpoint#".pick)
	 let mesg = s:GdbMgrSend(7,"gmGdb",s:server."restart ".pick)
     let mesg = s:GdbMgrMesgFix(mesg)
     call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
     call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
     call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
     call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
     call s:gdbmgr_registry_{t:gdbmgrtab}["H"].Update()
     call s:gdbmgr_registry_{t:gdbmgrtab}["S"].Update()
     call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
     call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
	 exe linenum
	endif
   else
"	call Decho("no checkpoint pick available on current line")
   endif

   call s:GdbMgrCloseCodedBuf()
  endif

"  call Dret("s:CheckptRestart")
endfun

" ---------------------------------------------------------------------
" s:CheckptDelete: called to delete the selected checkpoint (via the <del> map set up in s:CheckptInit) {{{2
fun! s:CheckptDelete()
"  call Dfunc("s:CheckptDelete()")

  if exists("t:gdbmgrtab")

   " edit the Checkpts buffer
   if s:GdbMgrOpenCodedBuf("H") == 0
"    call Dret("s:FuncstackUpdate : no funcstack window")
    return
   endif
   let curline= getline(".")
   let linenum= line(".")
   if curline =~ '^\s*\d\+'
	let pick= substitute(curline,'^\s*\(\d\+\)\s.*$','\1','')
	if pick =~ '^\d\+$'
	 let mesg = s:GdbMgrSend(7,"gmGdb",s:server."delete checkpoint ".pick)
     let mesg = s:GdbMgrMesgFix(mesg)
	 exe linenum
	endif
   endif

   call s:GdbMgrCloseCodedBuf()
  endif

"  call Dret("s:CheckptDelete")
endfun

" ---------------------------------------------------------------------
" s:CmdInit: initialize command window {{{2
fun! s:CmdInit() dict
"  call Dfunc("s:CmdInit()")
  call gdbmgr#GdbMgrInitEnew()
  set ft=gdbmgr_cmd
  sil file Commands
  setlocal nobuflisted bt=nofile
  call s:GdbMgrOptionSafe()
  setlocal write ma noro ww+=<,>,[,] bh=hide

  let self.bufnum= bufnr("%")
"  call Decho('(CmdInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn  <buffer> <silent> <F1>	:he gdbmgr-command<cr>
  nn  <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
  nn  <buffer> <silent> <cr>	:sil call <SID>CmdExe('normal')<cr>
  ino <buffer> <silent> <cr>	<cr><c-r>=<SID>CmdExe('insert')<cr>
  nn  <buffer> <silent> <s-F6>	:sil call <SID>CmdPoll("manual")<cr>
  ino <buffer> <silent> <s-F6>	<esc>:silent call <SID>CmdPoll("manual")<cr>
  nn  <buffer> <silent> <s-F7>	:<c-u>call <SID>CheckptSave()<cr>
  au InsertEnter Commands call s:CmdExe("insert-start")
"  au InsertLeave Commands call s:CmdExe("insert-leave")
"  call Dret("s:CmdInit : bufnum#".self.bufnum)
endfun

" ---------------------------------------------------------------------
" s:CmdUpdate: {{{2
fun! s:CmdUpdate(newcmd) dict
"  call Dfunc("s:CmdUpdate(newcmd<".a:newcmd.">) s:gdbmgr".t:gdbmgrtab."_running=".s:gdbmgr{t:gdbmgrtab}_running." win#".winnr().",line($)=".line("$"))

  if !exists("t:gdbmgrtab")
"   call Dret("s:CmdUpdate : gdbmgr never initialized in this tab")
   return
  endif

  " prepare to edit Commands buffer
  if s:GdbMgrOpenCodedBuf("C") == 0
"   call Dret("s:CmdUpdate : no commands window available")
   return
  endif

  " clear out ansi escape sequences from newcmd
  if g:gdbmgr_clearansi && a:newcmd =~ '\e\[\(\d\+;\)*\d*m'
   let newcmd= substitute(a:newcmd,'\e\[\(\d\+;\)*\d*m','','g')
  else
   let newcmd= a:newcmd
  endif
"  call Decho("(CmdUpdate) newcmd<".newcmd."> (after ansi cleaning)")

  " skip empty strings and plain newlines while user program not running
"  call Decho("newcmd ".((newcmd == "" || newcmd == "\n")? "matches" : "does not match")." empty/plain-newline")
  if exists("s:gdbmgr{t:gdbmgrtab}_running") && s:gdbmgr{t:gdbmgrtab}_running == "S" && (newcmd == "" || newcmd == "\r")
"   "   call Dret("s:CmdUpdate : skipping empty strings/plain newlines while user pgm not running")
   return
  endif

  " new first line
  if line("$") == 1 && getline(1) == ""
   keepj call setline(1,newcmd)
   let s:gdbmgr_pgmtext{t:gdbmgrtab} = strlen(newcmd)
"   call Decho("(CmdUpdate) new first line<".newcmd.">")
"   call Decho("(CmdUpdate) s:gdbmgr_pgmtext".t:gdbmgrtab."=".s:gdbmgr_pgmtext{t:gdbmgrtab})

  " append text to current last line
  elseif exists("s:cmdupd_lastcmd") && s:cmdupd_lastcmd =~ "\r$"
   $d
   let lastline= substitute(getline("$"),"$",newcmd,'')
   keepj call setline(line("$"),lastline)
   let s:gdbmgr_pgmtext{t:gdbmgrtab} = strlen(lastline)
"   call Decho("(CmdUpdate) setline($,<".lastline.">)  (appended newcmd<".newcmd.">)")
"   call Decho("(CmdUpdate) s:gdbmgr_pgmtext".t:gdbmgrtab."=".s:gdbmgr_pgmtext{t:gdbmgrtab})

   " new last line
  else
   if newcmd =~ '\n$'
	let newcmd= substitute(newcmd,'\n$','','')
	keepj call setline(line("$")+1,newcmd)
	let s:gdbmgr_pgmtext{t:gdbmgrtab} = 0
"	call Decho("(CmdUpdate) setline($+1,<".newcmd.">)  (1: new last line#".line("$").")")
   else
    keepj call setline(line("$")+1,newcmd)
	let s:gdbmgr_pgmtext{t:gdbmgrtab} = strlen(newcmd)
"	call Decho("(CmdUpdate) setline($+1,<".newcmd.">)  (2: new last line#".line("$").")")
   endif
"   call Decho("s:gdbmgr_pgmtext".t:gdbmgrtab."=".s:gdbmgr_pgmtext{t:gdbmgrtab})
  endif

  if g:gdbmgr_clearansi
"   call Decho("(CmdUpdate) cleaning ansi escape codes from Command window")
   sil! keepj %s/\e\[\(\d\+;\)*\d*m//g
   sil! keepj %s/\e$//g
  endif
  keepj $
  if mode() == "i"
   startinsert!
  else
   keepj norm! $
  endif
"  call Decho("(CmdUpdate) place cursor at bottom of Command window (win#".winnr().",line($)=".line("$").") mode=".mode())

  " restore cursor to original window
  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:CmdUpdate : line($)=".line('$'))
endfun

" ---------------------------------------------------------------------
" s:CmdExe: executes a command from the command window {{{2
"           s:CmdInit sets up two autocmds:
"             InsertEnter - calls this routine with "insert-start"
"             InsertLeave - calls this routine with "insert-leave"
fun! s:CmdExe(...)
"  call Dfunc("s:CmdExe() a:0=".a:0.((a:0>0)? "<".string(a:1).">" : "")." s:gdbmgr".t:gdbmgrtab."_running=".s:gdbmgr{t:gdbmgrtab}_running)
  if exists("t:gdbmgrtab")

   if (a:0 == 0 || a:1 == "insert") && line(".") > 1
	let curline= getline(line(".")-1)
   elseif a:0 == 1 && a:1 == "normal"
	let curline= getline(".")
   else
    let curline= getline(".")
   endif
"   call Decho("(CmdExe) raw curline<".curline.">")

   " remove leader
   if exists("s:gdbmgr_pgmtext{t:gdbmgrtab}") && s:gdbmgr_pgmtext{t:gdbmgrtab} > 0 && s:gdbmgr{t:gdbmgrtab}_running != 'Q'
"	call Decho("will remove leader: s:gdbmgr_pgmtext".t:gdbmgrtab."=".s:gdbmgr_pgmtext{t:gdbmgrtab})
	let curline= strpart(curline,s:gdbmgr_pgmtext{t:gdbmgrtab})
"	call Decho("(CmdExe)     curline<".curline."> (removed ".s:gdbmgr_pgmtext{t:gdbmgrtab}." bytes)")
   endif

   " ignore empty curline command
   if curline == ""
"	call Dret("s:CmdExe : ignoring empty curline")
    return ""
   endif

   " handle cfnNsSuU and finish via GdgMgrCmd facility
   if curline =~ '^\s*[fnNsS]\s*\d\+$' || curline =~ '^\s*[cuU]\s*$' || curline =~ '^\s*finish\s*$'
	call gdbmgr#GdbMgrCmd(curline)
"    call Dret("s:CmdExe")
	return
   endif

   " send the command
   if s:gdbmgr{t:gdbmgrtab}_running == 'S'
    let mesg = s:GdbMgrSend(2,"gmGdb",curline)
   else
    let mesg = s:GdbMgrSend(2,"gmPoll",curline)
   endif

   " remove ansi escape sequences
   if g:gdbmgr_clearansi
"	call Decho("(CmdExe) cleaning ansi escape codes from mesg  (#1)")
    let mesg= substitute(mesg,'\e\[\(\d\+;\)*\d*m','','g')
"	call Decho("(CmdExe) resulting mesg<".mesg.">  (#1)")
   endif

   " determine new leader length
   if mesg =~ '\n'
	let s:gdbmgr_pgmtext{t:gdbmgrtab} = strlen(substitute(mesg,'^.*\n','',''))
   else
    let s:gdbmgr_pgmtext{t:gdbmgrtab} = strlen(mesg)
   endif
"   call Decho("(CmdExe) new leader length s:gdbmgr_pgmtext".t:gdbmgrtab."=".s:gdbmgr_pgmtext{t:gdbmgrtab})

   " update display
   if s:gdbmgr{t:gdbmgrtab}_running == "S"
	" s:gdbmgr{t:gdbmgrtab}_running set up by the shared library via gmGdb and gmPoll
"	call Decho("(CmdExe) updating Messages Breakpoints Watchpoints Functionstack Source  (s:gdbmgr".t:gdbmgrtab."_running=".s:gdbmgr{t:gdbmgrtab}_running.")")
    call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
    call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
    call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
    call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
    call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
    call s:gdbmgr_registry_{t:gdbmgrtab}["S"].Update()
   else
"	call Decho("(CmdExe) updating Commands (s:gdbmgr".t:gdbmgrtab."_running=".s:gdbmgr{t:gdbmgrtab}_running.")")
	call s:gdbmgr_registry_{t:gdbmgrtab}["C"].Update(mesg)
   endif
  endif
  call s:CmdPoll("cmdexe")
"  call Dret("s:CmdExe")
  return ""
endfun

" ---------------------------------------------------------------------
" s:CmdPoll: poll for output from program being debugged {{{2
"    events        From
"    ------        -----
"    manual        CmdInit
"    cmdexe        CmdExe
"    step-continue GdbMgrStep
"    step-start    GdbMgrStep
"    c             GdbMgrCmd
"    finish        GdbMgrCmd
"    starting      GdbMgrRun
fun! s:CmdPoll(event)
"  call Dfunc("s:CmdPoll(event<".a:event.">)"." s:gdbmgr".t:gdbmgrtab."_running=".s:gdbmgr{t:gdbmgrtab}_running." g:gdbmgr_poll<".g:gdbmgr_poll.">")

  set lz
  let curcode= s:GetWinCode()
  if !exists("#CmdPollAutocmds") && g:gdbmgr_poll
"   call Decho("install polling autocmds")
   " the *.* allows the source window to poll
   " needed so the maps  s and n can be repeatedly used
   augroup CmdPollAutocmds
    au!
     au CursorHold  Commands,*.* call s:CmdPoll("hold")
	 au CursorHoldI Commands,*.* call s:CmdPoll("ihold")
     au FocusGained Commands,*.* call s:CmdPoll("focusgain")
     au VimResized  Commands,*.* call s:CmdPoll("resize")
   augroup END
   let s:stopped                     = "\x1A"."\x1A".'stopped'
   let s:exited                      = "\x1A"."\x1A".'exited'
   let s:breakpt                     = "\x1A"."\x1A".'breakpoint'
   let s:source                      = "\x1A"."\x1A".'source'
   let s:framebegin                  = "\x1A"."\x1A".'frame-begin'
   let s:endpgm                      = '\<__libc_start_main\>'
   set ut=100
"   set ut=2000 "Decho
  elseif !exists("s:stopped")
   let s:stopped                     = "\x1A"."\x1A".'stopped'
   let s:exited                      = "\x1A"."\x1A".'exited'
   let s:breakpt                     = "\x1A"."\x1A".'breakpoint'
   let s:source                      = "\x1A"."\x1A".'source'
   let s:framebegin                  = "\x1A"."\x1A".'frame-begin'
   let s:endpgm                      = '\<__libc_start_main\>'
   set ut=100
"   set ut=2000 "Decho
  else
   set ut=100
"   set ut=2000 "Decho
  endif

  " query for program output -- keep posting output until no more messages, then start polling
"  call Decho("query for program output")
  let mesg= s:GdbMgrSend(4,"gmPoll")
  if g:gdbmgr_clearansi
"   call Decho("(CmdExe) cleaning ansi escape codes from mesg  (#2)")
   let mesg= substitute(mesg,'\e\[\(\d\+;\)*\d*m','','g')
"   call Decho("resulting mesg<".mesg.">  (#2)")
  endif
  if mesg == "\n" && (a:event == "step-start" || a:event == "step-continue")
   let mesg= ""
  endif

"  call Decho("entering while loop {")
  while mesg != "" && mesg != "\n"
"   call Decho("(CmdPoll while-loop) mesg<".mesg.">  running<".s:gdbmgr{t:gdbmgrtab}_running.">")

   if mesg =~ s:breakpt
	" done to handle commands.  Breakpoint may be followed by a <c-z><c-z>starting,
	" in which case polling should continue.
	if s:BreakptPollCheck(mesg)
	 break
	endif
   endif

   if mesg =~ s:stopped || mesg =~ s:exited || mesg =~ s:breakpt || mesg =~ s:endpgm
    " terminate program-running mode, return to source window
"	call Decho("(CmdPoll while-loop) terminate program-running mode")
	let s:gdbmgr{t:gdbmgrtab}_running = 'S'
	let &ut                           = s:keeput
	if mode() == "i"
"	 call Decho("(CmdPoll) turn insert mode off")
	 noauto stopinsert
	endif

	" remove CmdPollAutocmds
    augroup CmdPollAutocmds
     au!
    augroup END
    augroup! CmdPollAutocmds
"	call Decho("(CmdPoll while-loop) CmdPollAutocmds ".(exists("#CmdPollAutocmds")? "still exist" : "have been removed"))

	 " have cursor go to Source window
	let curcode= "S"

	" update various gdbmgr windows
    if exists("t:gdbmgrtab")
"	 call Decho("(CmdPoll while-loop) update gdbmgr windows")
     call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
	 if s:gdbmgr{t:gdbmgrtab}_running == "R"
	  " this can be caused by a "c" (continue) in a commands list for a breakpoint.
	  " Anyway, we're still running, thus we still need to be polling.
	  break
	 endif
     call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(strpart(mesg,2))
     call gdbmgr#GdbMgrForeground("S")

	 if mesg =~ s:endpgm
"	  call Decho("handling endpgm message")
	  call s:ExprClear()
	  call s:FuncstackClear()
	  let g:gdbmgr_poll= 0
	  break

	 elseif mesg =~ s:exited
"	  call Decho("handling exited message")
	  let mesg= s:GdbMgrSend(39,"gmGdb","-empty-string-")
"	  call Decho("exited mesg<".mesg.">")
	  call s:ExprClear()
	  call s:FuncstackClear()
      call s:gdbmgr_registry_{t:gdbmgrtab}["S"].Update()

	 else
"	  call Decho("handling not-exited, not endpgm message")
      call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
      call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
      call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
      call s:gdbmgr_registry_{t:gdbmgrtab}["S"].Update()
      call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
      call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
	 endif

	 if mesg =~ s:breakpt
	  " for breakpoints, put cursor in source window after updates
"	  call Decho("for breakpoints, put cursor in source window after updating")
	  call s:GotoWinCode("S")
	 endif
    endif

	" leave polling loop (user program no longer in running mode)
	break

   elseif mesg !~ s:source && mesg !~ s:framebegin
    " display the program's output in the Command window
"	call Decho("(CmdPoll while-loop) display program output in Command window")
	if exists("t:gdbmgrtab")
	 if mesg =~  "^\x1A"."\x1A"
	  call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(strpart(mesg,2))
	 else
	  call s:gdbmgr_registry_{t:gdbmgrtab}["C"].Update(mesg)
	 endif
    endif
   endif

   " attempt to get another message from the running program
"   call Decho("(CmdPoll while-loop) query for more program output")
   let mesg= s:GdbMgrSend(5,"gmPoll")
   if g:gdbmgr_clearansi
"	call Decho("(CmdPoll while-loop) cleaning ansi escape codes from mesg  (#3)")
    let mesg= substitute(mesg,'\e\[\(\d\+;\)*\d*m','','g')
"	call Decho("(CmdPoll while-loop) resulting mesg<".mesg.">  (#3)")
   endif
  endwhile
"  call Decho("leaving while loop }")

  " reset CursorHold for polling
"  call Decho("deciding whether to reset CursorHold for polling")
"  call Decho("enabled?       g:gdbmgr_poll=".g:gdbmgr_poll)
"  call Decho("hold or ihold? event<".a:event.">")
"  call Decho("exists?        #CmdPollAutocmds<".(exists("#CmdPollAutocmds")? "exists" : "does not exist").">")
"  call Decho("pgm running?   s:gdbmgr{t:gdbmgrtab}_running<".s:gdbmgr{t:gdbmgrtab}_running.">")
  if g:gdbmgr_poll && (a:event == "hold" || a:event == "ihold") && exists("#CmdPollAutocmds") && s:gdbmgr{t:gdbmgrtab}_running =~ "[RQ]"
"   call Decho("polling: resetting cursorhold event")
   " insure that the command window is visible and active
   call gdbmgr#GdbMgrForeground("C")
   if col(".") > 1
	call feedkeys("\<left>\<right>","n")
   elseif col(".") < col("$")-1
	call feedkeys("\<right>\<left>","n")
   else
    let vekeep= &ve
    set ve=all
	call feedkeys("\<right>\<left>","n")
    let &ve= vekeep
   endif
  else
"   call Decho("did not reset cursorhold: g:gdbmgr_poll=".g:gdbmgr_poll." event<".a:event.">".(exists("#CmdPollAutocmds")? " has CmdPollAutocmds" : " no CmdPollAutocmds"))
  endif
  call s:GotoWinCode(curcode)
  set nolz
  filetype detect

"  call Dret("s:CmdPoll : ut=".&ut." running<".s:gdbmgr{t:gdbmgrtab}_running.">")
endfun

" ---------------------------------------------------------------------
" s:ExprInit: {{{2
fun! s:ExprInit() dict
"  call Dfunc("s:ExprInit()")
  call gdbmgr#GdbMgrInitEnew()
  sil file Expressions
  setlocal ft=gdbmgr_expr nobuflisted bt=nofile
  call s:GdbMgrOptionSafe()
  setlocal write ma noro bh=hide
  let self.bufnum= bufnr("%")
"  call Decho('(ExprInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn  <buffer> <silent> <F1>		:he gdbmgr-expr<cr>
  nn  <buffer> <silent> <F6>		:call <SID>ExprUpdateByMap()<cr>
  ino <buffer> <silent> =			<c-o>:call <SID>ExprUpdateByMap()<cr><esc>A
  nn  <buffer> <silent> <c-F6>		:call gdbmgr#BufSwitch()<cr>
  nn  <buffer> <silent> <c-up>		:<c-u>call <SID>FuncstackChgline(v:count1)<cr>
  nn  <buffer> <silent> <c-down>	:<c-u>call <SID>FuncstackChgline(-v:count1)<cr>
  nn  <buffer> <silent> <c-l>		:call <SID>ExprUpdateByMap()<cr>
"  call Dret("s:ExprInit : bufnum#".self.bufnum)
endfun

" ---------------------------------------------------------------------
" s:ExprUpdate: {{{2
fun! s:ExprUpdate() dict
"  call Dfunc("s:ExprUpdate()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:ExprUpdate : gdbmgr never initialized")
   return
  endif

  " prepare to edit code E buffer
  if s:GdbMgrOpenCodedBuf("E") == 0
"   call Dret("s:ExprUpdate : no expressions window available")
   return
  endif

  " remove blank lines
  sil! keepj g/^\s*$/keepj d

  if line("$") != 1 || getline(1) != ""
	" Expression buffer not empty
   let iline= 1
   while iline <= line("$")
	 let expr  = substitute(getline(iline),'^\s*\(\S*\)\s*=.*\n\=$','\1','')
	 let mesg  = substitute(s:GdbMgrSend(6,"gmGdb",s:server.s:output.expr),'^\s*\$\d\+\s*=\s*','','')
	 let mesg  = substitute(mesg,'\n','','g')
	 if mesg =~ 'No symbol'
	  keepj call setline(iline,expr.' = --n/a--')
	 else
	  keepj call setline(iline,expr.' = '.mesg)
	 endif
	 let iline = iline + 1
   endwhile
  endif

  " restore status quo ante
  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:ExprUpdate")
endfun

" ---------------------------------------------------------------------
" s:ExprUpdateByMap: update called via function key in Expressions buffer {{{2
fun! s:ExprUpdateByMap()
"  call Dfunc("s:ExprUpdateByMap()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:ExprUpdateByMap : gdbmgr never initialized")
   return
  endif

  call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
"  call Dret("s:ExprUpdateByMap")
endfun

" ---------------------------------------------------------------------
" s:ExprClear: {{{2
fun! s:ExprClear()
"  call Dfunc("s:ExprClear()")
  if !exists("t:gdbmgrtab")
"   call Dret("s:ExprClear : not a GdbMgr tab")
   return
  endif

   " edit the Expressions buffer
   if s:GdbMgrOpenCodedBuf("E") == 0
"    call Dret("s:ExprUpdate : no funcstack window")
    return
   endif

   " clear the buffer and make it editable
   setlocal ma noro
   sil! keepj %s/=.*$/= --n\/a--/e

   " close the buffer
   setlocal cul nomod
   call s:GdbMgrCloseCodedBuf()

"  call Dret("s:ExprClear")
endfun

" ---------------------------------------------------------------------
" s:FuncstackInit: {{{2
fun! s:FuncstackInit() dict
"  call Dfunc("s:FuncstackInit()")
  call gdbmgr#GdbMgrInitEnew()
  set ft=gdbmgr_funcstack
  sil file FuncStack
  setlocal nobuflisted bh=hide bt=nofile
  call s:GdbMgrOptionSafe()
  let self.bufnum= bufnr("%")
"  call Decho('(FuncstackInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn <buffer> <silent> <F1>				:he gdbmgr-funcstack<cr>
  nn <buffer> <silent> <up>				:call <SID>FuncstackChgline(v:count1)<cr>
  nn <buffer> <silent> <down>			:call <SID>FuncstackChgline(-v:count1)<cr>
  nn <buffer> <silent> k				:call <SID>FuncstackChgline(v:count1)<cr>
  nn <buffer> <silent> j				:call <SID>FuncstackChgline(-v:count1)<cr>
  nn <buffer> <silent> <c-F6>			:call gdbmgr#BufSwitch()<cr>
  nn <buffer> <silent> <LeftMouse>		<LeftMouse>:call <SID>FuncstackChgline(0)<cr>
  nn <buffer> <silent> <2-LeftMouse>	<LeftMouse>:call <SID>FuncstackChgline(0)<cr>
"  call Dret("s:FuncstackInit : bufnum#".self.bufnum)
endfun

" ---------------------------------------------------------------------
" s:FuncstackUpdate: {{{2
fun! s:FuncstackUpdate() dict
"  call Dfunc("s:FuncstackUpdate()")

  if exists("t:gdbmgrtab")
   let mesg = s:GdbMgrSend(7,"gmGdb",s:server."where")
   let mesg = s:GdbMgrMesgFix(mesg)
   if mesg =~ '\<Source directories searched\>'
"	call Decho("ignoring <Source directories searched>")
    if exists("g:gdbmgr_use_server")
     let mesg = s:GdbMgrSend(1,"gmGdb","server")
	else
     let mesg = s:GdbMgrSend(1,"gmGdb"," ")
	endif
    let mesg = s:GdbMgrMesgFix(mesg)
   endif

   " clean leading newlines and multiple contiguous newlines
   let mesg     = substitute(mesg,'^\n\+','','g')
   let mesg     = substitute(mesg,'\n\{2,}','\n','g')
"   call Decho("cleaned mesg<".mesg.">")
   let mesglist = split(mesg,"\n")

   " edit the Funcstack buffer
   if s:GdbMgrOpenCodedBuf("F") == 0
"	call Dret("s:FuncstackUpdate : no funcstack window available")
    return
   endif

   " clear the buffer and make it editable
   setlocal ma noro
   sil keepj %d

   " put the "where" results into the Funcstack window, then
   " reverse the lines, so that <c-up> is up, etc.
   let lzkeep= &lz
   set lz
   call setline(1,mesglist)
   sil! keepj g/^\s*$/d
   sil! keepj v/^#/-1j
   keepj g/^/m 0
   keepj $
   let s:gdbmgr{t:gdbmgrtab}_curline= line("$")
   redraw
   let &lz= lzkeep

   " make it not-editable and close the buffer
   setlocal noma ro cul nomod
   call s:GdbMgrCloseCodedBuf()
  endif

"  call Dret("s:FuncstackUpdate")
endfun

" ---------------------------------------------------------------------
" s:FuncstackChgline: change line in function stack {{{2
fun! s:FuncstackChgline(chg)
"  call Dfunc("s:FuncstackChgline(chg=".a:chg.")")
  let chg= a:chg

  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:FuncstackChgline : gdbmgr never initialized")
   return
  endif

  " prepare to edit the buffer associated with the Funcstack
  if s:GdbMgrOpenCodedBuf("F") == 0
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** Funcstack not available")
"   call Dret("s:FuncstackChgline : Funcstack not available")
   return
  endif

  " sanity check -- is it an empty buffer?
  if line("$") == 1 && getline(".") == ""
   " Funcstack is empty -- try to update it
   call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
   if line("$") == 1 && getline(".") == ""
	" still empty -- complain and return
    call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** empty Funcstack")
    " close/return-to-window
    call s:GdbMgrCloseCodedBuf()
"    call Dret("s:FuncstackChgline : Funcstack not available")
    return
   endif
  endif

  " modify the current line (in the Funcstack window)
  if chg != 0
   let nowline= line(".")
   let curline= line(".") - chg
   if curline < 1
    let curline = 1
   elseif curline > line("$")
    let curline= line("$")
   endif
   exe "keepj ".curline
   keepj norm! z.
"   call Decho("nowline=".nowline." curline=".curline)
   if nowline == curline
    " no change in curline means there's no more Funcstack in the direction attempted
    " close/return-to-window
    call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** no more Funcstack in that direction")
    call s:GdbMgrCloseCodedBuf()
"    call Dret("s:FuncstackChgline : no more funcstack in that direction")
    return
   endif
"   call Decho("modified Funcstack current line from #".nowline." to #".curline)

  else
   let curline= line(".")
  endif
  " determine if updates are possible (ie. ?? lines, ... in ... lines, etc don't have file+linenumber information)
  let doupdates= getline(curline) =~ ' at '
"  call Decho("getline(curline#".curline.")<".getline(curline).">: doupdates=".doupdates)

  " update the Source window
  if doupdates
   let funcfile= substitute(getline("."),'^.*) at \(\S\+\):\(\d\+\)$','\1','')
   let funcline= substitute(getline("."),'^.*) at \(\S\+\):\(\d\+\)$','\2','')
"   call Decho("funcfile<".funcfile."> funcline#".funcline)
   if funcfile != funcline
	" if the substitute patterns didn't match, don't update source file
    call s:SourceFastUpdate(funcfile,funcline)
   endif
  endif

  " tell gdb in what function we're looking
  if chg == 1
   let mesg= s:GdbMgrSend(8,"gmGdb",s:server."up")
  elseif chg > 1
   let mesg= s:GdbMgrSend(9,"gmGdb",s:server."up ".chg)
  elseif chg == -1
   let mesg= s:GdbMgrSend(10,"gmGdb",s:server."down")
  elseif chg == 0
   let select= substitute(getline("."),'^#\(\d\+\).\{-}$','\1','')
"   call Decho("sending via gmGdb: <",s:server."frame ".select.">")
   let mesg  = s:GdbMgrSend(11,"gmGdb",s:server."frame ".select)
  else
   let mesg= s:GdbMgrSend(11,"gmGdb",s:server."down ".-chg)
  endif

  " update expressions/assembly window
  if doupdates
   call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
  endif

  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:FuncstackChgline")
endfun

" ---------------------------------------------------------------------
" s:FuncstackClear: {{{2
fun! s:FuncstackClear()
"  call Dfunc("s:FuncstackClear()")
  if !exists("t:gdbmgrtab")
"   call Dret("s:FuncstackClear : not a GdbMgr tab")
   return
  endif

   " edit the Funcstack buffer
   if s:GdbMgrOpenCodedBuf("F") == 0
"    call Dret("s:FuncstackUpdate : no funcstack window")
    return
   endif

   " clear the buffer and make it editable
   setlocal ma noro
   sil! keepj %d

   " make it not-editable and close the buffer
   setlocal noma ro cul nomod
   call s:GdbMgrCloseCodedBuf()

"  call Dret("s:FuncstackClear")
endfun

" ---------------------------------------------------------------------
" s:MesgInit: {{{2
fun! s:MesgInit() dict
"  call Dfunc("s:MesgInit()")
  call gdbmgr#GdbMgrInitEnew()
  set ft=gdbmgr_mesg
  call s:GdbMgrOptionSafe()
  sil file Messages
  setlocal nobuflisted bh=hide bt=nofile
  let self.bufnum= bufnr("%")
"  call Decho('(MesgInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn <buffer> <silent> <F1>		:he gdbmgr-messages<cr>
  nn <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
"  call Dret("s:MesgInit : bufnum#".self.bufnum)
endfun

" ---------------------------------------------------------------------
" s:MesgUpdate: post a message into the messages window {{{2
fun! s:MesgUpdate(mesg) dict
"  call Dfunc("s:MesgUpdate(mesg<".a:mesg.">)")
  if !exists("t:gdbmgrtab")
   " sanity check: are we in a GdbMgr tab?
   echohl Error
   redraw|echomsg "(s:MesgUpdate) attempt to post <".a:mesg."> while not in a GdbMgr tab"
   echohl None
  elseif exists("s:gdbmgr_registry_{t:gdbmgrtab}")
   " sanity check: has GdbMgr been initialized?
   if s:GdbMgrOpenCodedBuf("M") == 0
	echomsg a:mesg
"	call Dret("s:MesgUpdate : Message buffer not initialized")
	return
   endif

   " append the message to the Messages buffer
   setlocal ma noro
   if line("$") == 1 && getline(1) == ""
    keepj call setline(1, split(a:mesg,"\n"))
   else
    keepj call setline(line("$")+1, split(a:mesg,"\n"))
   endif
   keepj $
   redraw
   setlocal noma ro nomod
   call s:GdbMgrCloseCodedBuf()

  endif
"  call Dret("s:MesgUpdate")
endfun

" ---------------------------------------------------------------------
" gdbmgr#NetrwCore: invoked by Netrw's x mapping, which calls this {{{2
"                   function via the g:netrw_corehandler function reference
"                   Switches to the source window
fun! gdbmgr#NetrwCore(corefile)
"  call Dfunc("gdbmgr#NetrwCore(corefile<".a:corefile.">)")
  call gdbmgr#GdbMgrForeground("S")

  if s:GdbMgrOpenCodedBuf("S") == 0
"   call Dret("gdbmgr#NetrwCore : no source buffer/window!")
   return
  endif

  let mesg= s:GdbMgrSend(12,"gmGdb","core ".a:corefile)
  call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
  call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
  call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
  call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
  call s:gdbmgr_registry_{t:gdbmgrtab}["S"].Update()

  call s:GdbMgrCloseCodedBuf()
"  call Dret("gdbmgr#NetrwCore")
endfun

" ---------------------------------------------------------------------
" s:NetrwInit: {{{2
fun! s:NetrwInit() dict
"  call Dfunc("s:NetrwInit()")
  call gdbmgr#GdbMgrInitEnew()
  let g:Netrw_corehandler= function("gdbmgr#NetrwCore")
  Explore
"  call Decho('(NetrwInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn <buffer> <silent> <c-F6>		:call gdbmgr#BufSwitch()<cr>
"  call Dret("s:NetrwInit : buf#".bufnr("%"))
endfun

" ---------------------------------------------------------------------
" s:NetrwUpdate: {{{2
fun! s:NetrwUpdate() dict
"  call Dfunc("s:NetrwUpdate() buf#".bufnr("%"))

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr never initialized!"
   echohl None
"   call Dret("s:NetrwUpdate : gdbmgr never initialized")
   return
  endif

"  call Decho('(NetrwUpdate) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>

  if s:gdbmgr_registry_{t:gdbmgrtab}.S.bufnum != 0
   let g:netrw_chgwin  = bufwinnr(s:gdbmgr_registry_{t:gdbmgrtab}.S.bufnum)
   let g:Netrw_funcref = function("gdbmgr#ForeignAppFuncref")
  endif
"  call Dret("s:NetrwUpdate")
endfun

" ---------------------------------------------------------------------
" gdbmgr#ForeignAppFuncref: this function is called by foreign applications/codes {{{2
"                           when it is used to select a file into the Source window.
fun! gdbmgr#ForeignAppFuncref()
"  call Dfunc("gdbmgr#ForeignAppFuncref()")

  " sanity check
  if !exists("t:gdbmgrtab")
"   call Dret("s:ForeignAppFuncref : gdbmgr never initialized")
   return
  endif

  " record the file's particulars for gdbmgr tab-wide access
  let t:srcfile = simplify(expand("%"))
  let t:srcline = line(".")
"  call Decho("set t:srcfile<".t:srcfile.":".t:srcline."> buf#".bufnr("%"))
  setlocal bh=hide noma ro

  " update the Source window registry
  let s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum      = bufnr("%")
  if !exists("s:gdbmgr_registry_{t:gdbmgrtab}[".bufnr("%")."]")
   let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")]     = {}
  endif
  let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code = "S"
  call s:GdbMgrUpdate("b")
"  call Decho("set s:gdbmgr_registry_".t:gdbmgrtab."[S].bufnum=".s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum)
"  call Decho("set s:gdbmgr_registry_".t:gdbmgrtab."[".bufnr("%")."].code=S")

  " handle folding
  if has("folding") && foldclosed('.') > 0
   keepj norm! zMzx
  endif
  keepj norm! z.

  " remove all insert-mode abbreviations -- they're likely to interfere with program operation
  sil iabc

  " set up Source window maps
"  call Decho('(ForeignAppFuncref) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn <buffer> <silent> <F1>			:he gdbmgr-source<cr>
  nn <buffer> <silent> <c-up>		:<c-u>call <SID>FuncstackChgline(v:count1)<cr>
  nn <buffer> <silent> <c-down>		:<c-u>call <SID>FuncstackChgline(-v:count1)<cr>
  nn <buffer> <silent> <F6>			:<c-u>call <SID>BreakptToggle()<cr>
  nn <buffer> <silent> <c-F6>		:<c-u>call gdbmgr#BufSwitch()<cr>
  nn <buffer> <silent> <s-F6>		:<c-u>call <SID>BreakptTemp()<cr>
  nn <buffer> <silent> <F7>			:<c-u>call <SID>SourceEdit()<cr>
  nn <buffer> <silent> c			:<c-u>call gdbmgr#GdbMgrCmd("c")<cr>
  nn <buffer> <silent> f			:<c-u>call gdbmgr#GdbMgrCmd("finish")<cr>
  nn <buffer> <silent> n			:<c-u>call gdbmgr#GdbMgrCmd("n ".v:count1)<cr>
  nn <buffer> <silent> N			:<c-u>call gdbmgr#GdbMgrCmd("N ".v:count1)<cr>
  nn <buffer> <silent> s			:<c-u>call gdbmgr#GdbMgrCmd("s ".v:count1)<cr>
  nn <buffer> <silent> S			:<c-u>call gdbmgr#GdbMgrCmd("S ".v:count1)<cr>
  nn <buffer> <silent> u			:<c-u>call gdbmgr#GdbMgrCmd("u")<cr>
  nn <buffer> <silent> U			:<c-u>call gdbmgr#GdbMgrCmd("U")<cr>

"  call Dret("gdbmgr#ForeignAppFuncref")
endfun

" ---------------------------------------------------------------------
" s:SourceInit: sets up source window based upon t:srcbuf {{{2
fun! s:SourceInit() dict
"  call Dfunc("s:SourceInit() t:srcbuf".(exists("t:srcbuf")? "#".t:srcbuf : " not defined!"))
  if exists("t:srcbuf") && t:srcbuf > 0
   exe "b ".t:srcbuf
   let t:srcfile   = simplify(bufname(t:srcbuf))
"   call Decho("set t:srcfile<".t:srcfile.">  t:srcbuf#".(exists("t:srcbuf")? t:srcbuf : 'n/a'))
   let self.bufnum = bufnr("%")
   setlocal bh=hide cul

   " save user maps
   if !exists("b:saved_user_maps")
	call SaveUserMaps("bn","","<F1>"    ,"gdbmgr")
	call SaveUserMaps("bn","","<c-up>"  ,"gdbmgr")
	call SaveUserMaps("bn","","<c-down>","gdbmgr")
	call SaveUserMaps("bn","","<c-F6>"  ,"gdbmgr")
	call SaveUserMaps("bn","","<F6>"    ,"gdbmgr")
	call SaveUserMaps("bn","","<s-F6>"  ,"gdbmgr")
	call SaveUserMaps("bn","","<s-F6>"  ,"gdbmgr")
	call SaveUserMaps("bn","","<s-F7>"  ,"gdbmgr")
	call SaveUserMaps("bn","","c"       ,"gdbmgr")
	call SaveUserMaps("bn","","f"       ,"gdbmgr")
	call SaveUserMaps("bn","","n"       ,"gdbmgr")
	call SaveUserMaps("bn","","N"       ,"gdbmgr")
	call SaveUserMaps("bn","","s"       ,"gdbmgr")
	call SaveUserMaps("bn","","S"       ,"gdbmgr")
	call SaveUserMaps("bn","","u"       ,"gdbmgr")
	call SaveUserMaps("bn","","U"       ,"gdbmgr")
	call SaveUserMaps("n","","CA"       ,"gdbmgr")
	call SaveUserMaps("n","","CB"       ,"gdbmgr")
	call SaveUserMaps("n","","CH"       ,"gdbmgr")
	call SaveUserMaps("n","","CC"       ,"gdbmgr")
	call SaveUserMaps("n","","CE"       ,"gdbmgr")
	call SaveUserMaps("n","","CF"       ,"gdbmgr")
	call SaveUserMaps("n","","CM"       ,"gdbmgr")
	call SaveUserMaps("n","","CN"       ,"gdbmgr")
	call SaveUserMaps("n","","CS"       ,"gdbmgr")
	call SaveUserMaps("n","","CW"       ,"gdbmgr")
	let b:saved_user_maps= 1
   endif
"   call Decho('(SourceInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
   nn <buffer> <silent> <F1>		:he gdbmgr-source<cr>
   nn <buffer> <silent> <c-up>		:<c-u>call <SID>FuncstackChgline(v:count1)<cr>
   nn <buffer> <silent> <c-down>	:<c-u>call <SID>FuncstackChgline(-v:count1)<cr>
   nn <buffer> <silent> <c-F6>		:<c-u>call gdbmgr#BufSwitch()<cr>
   nn <buffer> <silent> <F6>		:<c-u>call <SID>BreakptToggle()<cr>
   nn <buffer> <silent> <s-F6>		:<c-u>call <SID>BreakptTemp()<cr>
   nn <buffer> <silent> <F7>		:<c-u>call <SID>SourceEdit()<cr>
   nn <buffer> <silent> <s-F7>		:<c-u>call <SID>CheckptSave()<cr>
"   call Decho('has("signs")='.has("signs").' s:signs_defined='.(exists("s:signs_defined")? s:signs_defined : 'n/a'))
   if has("signs") && !exists("s:signs_defined")
    let s:signs_defined = 1
    let xpmpath         = substitute(&rtp,',.*$','','')
"	call Decho(xpmpath."/gdbmgr/pix/breakpt.xpm  is ".(filereadable(xpmpath.'/gdbmgr/pix/breakpt.xpm')?  "readable" : "n/a"))
"	call Decho(xpmpath."/gdbmgr/pix/tbreakpt.xpm is ".(filereadable(xpmpath.'/gdbmgr/pix/tbreakpt.xpm')? "readable" : "n/a"))
    if xpmpath != ""
	 if has("gui_running") && filereadable(xpmpath.'/gdbmgr/pix/breakpt.xpm') && filereadable(xpmpath.'/gdbmgr/pix/tbreakpt.xpm')
"	  call Decho("using xpm icons for breakpoint signs")
	  exe "sign define BreakptSign  icon=".xpmpath.'/gdbmgr/pix/breakpt.xpm'
	  exe "sign define TBreakptSign icon=".xpmpath.'/gdbmgr/pix/tbreakpt.xpm'
	  exe "sign define DBreakptSign  icon=".xpmpath.'/gdbmgr/pix/disbreakpt.xpm'
	  exe "sign define DTBreakptSign icon=".xpmpath.'/gdbmgr/pix/distbreakpt.xpm'
	 else
"	  call Decho("using text for breakpoint signs")
	  exe "sign define BreakptSign  text=B texthl=HLGdbMgrBreakpt"
	  exe "sign define TBreakptSign text=b texthl=HLGdbMgrBreakpt"
	  exe "sign define DBreakptSign  text=B texthl=HLGdbMgrDisBrkpt"
	  exe "sign define DTBreakptSign text=b texthl=HLGdbMgrDisBrkpt"
	  hi default HLGdbMgrBreakpt  ctermfg=Brown ctermbg=white
	  hi default HLGdbMgrDisBrkpt ctermfg=Brown ctermbg=gray
	 endif
 	exe "sign define CurLineSign text==> texthl=HLGdbMgrCurline"
 	hi default HLGdbMgrCurLine ctermfg=red ctermbg=white guifg=brown guibg=white
    endif
   endif
  endif
"  call Dret("s:SourceInit : bufnum#".self.bufnum."<".expand("%").">")
endfun

" ---------------------------------------------------------------------
" s:SourceUpdate: updates file,line#, and signs attached to source window {{{2
fun! s:SourceUpdate() dict
"  call Dfunc("s:SourceUpdate()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:SourceUpdate : gdbmgr never initialized")
   return
  endif
"  call Decho("1: bufnr(%)=".bufnr("%")." expand(%)<".expand("%")."> t:srcfile<".(exists("t:srcfile")? t:srcfile : 'n/a')."> t:srcline=".(exists("t:srcline")? t:srcline : 'n/a'))

  " prepare to edit Source window
  if s:GdbMgrOpenCodedBuf("S") == 0
"   call Dret("s:SourceUpdate : s:GdbMgrOpenCodedBuf(S) yielded 0!")
   return
  endif
"  call Decho("2: bufnr(%)=".bufnr("%")." expand(%)<".expand("%")."> t:srcfile<".(exists("t:srcfile")? t:srcfile : 'n/a')."> t:srcline=".(exists("t:srcline")? t:srcline : 'n/a'))

"  call Decho("3: bufnr(%)=".bufnr("%")." expand(%)<".expand("%")."> t:srcfile<".(exists("t:srcfile")? t:srcfile : 'n/a')."> t:srcline=".(exists("t:srcline")? t:srcline : 'n/a'))
  call s:SourceFastUpdate() " display current filename+fileline
"  call Decho("4: bufnr(%)=".bufnr("%")." expand(%)<".expand("%")."> t:srcfile<".(exists("t:srcfile")? t:srcfile : 'n/a')."> t:srcline=".(exists("t:srcline")? t:srcline : 'n/a'))
  call s:SourceSigns()      " install signs into Source window
"  call Decho("5: bufnr(%)=".bufnr("%")." expand(%)<".expand("%")."> t:srcfile<".(exists("t:srcfile")? t:srcfile : 'n/a')."> t:srcline=".(exists("t:srcline")? t:srcline : 'n/a'))

  " install stepping maps into Source window
  if s:gdbmgr{t:gdbmgrtab}_running == "S"
"   call Decho("s:gdbmgr".t:gdbmgrtab."_running<".s:gdbmgr{t:gdbmgrtab}_running.": set up run-mode nmaps in Source window (srcwin#".winnr().")")
   setlocal noma ro
   nn <buffer> <silent> c		:<c-u>call gdbmgr#GdbMgrCmd("c")<cr>
   nn <buffer> <silent> f		:<c-u>call gdbmgr#GdbMgrCmd("finish")<cr>
   nn <buffer> <silent> n		:<c-u>call gdbmgr#GdbMgrCmd("n ".v:count1)<cr>
   nn <buffer> <silent> N		:<c-u>call gdbmgr#GdbMgrCmd("N ".v:count1)<cr>
   nn <buffer> <silent> s		:<c-u>call gdbmgr#GdbMgrCmd("s ".v:count1)<cr>
   nn <buffer> <silent> S		:<c-u>call gdbmgr#GdbMgrCmd("S ".v:count1)<cr>
   nn <buffer> <silent> u		:<c-u>call gdbmgr#GdbMgrCmd("u")<cr>
   nn <buffer> <silent> U		:<c-u>call gdbmgr#GdbMgrCmd("U")<cr>
  else
"   call Decho("s:gdbmgr".t:gdbmgrtab."_running<".s:gdbmgr{t:gdbmgrtab}_running.": nunmap all pgm-running maps")
   sil! nunmap c
   sil! nunmap f
   sil! nunmap n
   sil! nunmap N
   sil! nunmap s
   sil! nunmap S
   sil! nunmap u
   sil! nunmap U
  endif

  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:SourceUpdate")
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrSourceInitFile: initialize source window file {{{2
"                   Must be called after "file pgm" has been sent to gdb
"  call gdbmgr#GdbMgrSourceInitFile(srcfile,srcline) -- display source file+line at given line number
"  call gdbmgr#GdbMgrSourceInitFile()                -- queries gdb for current source file+line
fun! gdbmgr#GdbMgrSourceInitFile(...)
"  call Dfunc("gdbmgr#GdbMgrSourceInitFile() a:0=".a:0)

  if exists("t:gdbmgrtab")
   if s:GdbMgrOpenCodedBuf("S") == 0
"	call Dret("gdbmgr#GdbMgrSourceInitFile : no source window!")
	return
   endif

	if a:0 == 0
"	 call Decho("case a:0 == 0:")
	 let mesg    = s:GdbMgrSend(13,"gmGdb",s:server."where")
"	 call Decho("mesg<".mesg.">")
	 if mesg =~ "No stack"
      let mesg = s:GdbMgrSend(14,"gmGdb",s:server."list")
      let mesg = s:GdbMgrSend(15,"gmGdb",s:server."info line")
	  if mesg =~ "out of range"
	   call s:GdbMgrCloseCodedBuf()
"	   call Dret("gdbmgr#GdbMgrSourceInitFile : ".mesg)
	   return
	  endif
      let srcfile = substitute(mesg,'^Line \d\+ of "\([^"]\+\)".*$','\1','')
      let srcline = 0+substitute(mesg,'Line \(\d\+\) .*$','\1','')
	 elseif mesg =~ '^#\d\+\s'
	  let srcfile = substitute(mesg,'^.\{-} at \(\S\{-}\.\S\{-}\):\(\d\+\)\_.*$','\1','')
	  let srcline = substitute(mesg,'^.\{-} at \(\S\{-}\.\S\{-}\):\(\d\+\)\_.*$','\2','')
	 endif
	 if exists("srcfile")
	  if srcfile =~ "gdb not responding as expected"
	   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
	   call s:GdbMgrCloseCodedBuf()
"       call Dret("gdbmgr#GdbMgrSourceInitFile : ".mesg)
	   return
	  elseif srcfile =~ "No line number" || srcfile =~ "Line number"
	   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
	   call s:GdbMgrCloseCodedBuf()
"	   call Dret("gdbmgr#GdbMgrSourceInitFile : ".mesg)
	   return
	  endif
	 else
	  let mesg= "unable to determine initial source file"
	  call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
	  call s:GdbMgrCloseCodedBuf()
"      call Dret("gdbmgr#GdbMgrSourceInitFile : ".mesg)
	  return
	 endif

	elseif a:0 == 2
"	 call Decho("case a:0 == 2:")
	 let srcfile= a:1
	 let srcline= a:2
	else
"	 call Decho("case a:0 not 0 or 2:")
	 call s:GdbMgrCloseCodedBuf()
"     call Dret("gdbmgr#GdbMgrSourceInitFile : WHY IS a:0=".a:0."?")
	 return
	endif
"	call Decho("srcfile<".(exists("srcfile")? srcfile : "doesn't exist")."> srcline#".(exists("srcline")? srcline : "doesn't exist"))

	" sometimes one gets stuff from FuncStack that isn't a source file
	if srcfile =~ '^#\d\s\+0'
	 call s:GdbMgrCloseCodedBuf()
"     call Dret("gdbmgr#GdbMgrSourceInitFile : non-source file lockout")
	 return
	endif

	" try to find the source file
	while !filereadable(srcfile)

	 if exists("g:gdbmgr_srcpath") && g:gdbmgr_srcpath != ""
	  " try to find source file using g:gdbmgr_srcpath
"	  call Decho("try to find srcfile<".srcfile."> using g:gdbmgr_srcpath<".g:gdbmgr_srcpath.">")
	  let srcfile2= globpath(g:gdbmgr_srcpath,srcfile)
"	  call Decho("globpath yielded srcfile2<".srcfile2.">")

	  " found srcfile
	  if filereadable(srcfile2)
	   let srcfile= srcfile2
"	   call Decho("found srcfile<".srcfile.">")
	   break
	  endif

	  " found multiple copies of file
	  if srcfile2 =~ '\n'
"	   call Decho("s:srcfiledict".t:gdbmgrtab.": ".(exists('s:srcfiledict{t:gdbmgrtab}')? "exists" : "does not exist"))
"	   call Decho("s:srcfiledict".t:gdbmgrtab.'["'.srcfile.'"]: '.(exists('s:srcfiledict{t:gdbmgrtab}["'.srcfile.'"]')? "exists" : "does not exist"))
	   if exists('s:srcfiledict{t:gdbmgrtab}') && exists('s:srcfiledict{t:gdbmgrtab}["'.srcfile.'"]')
		let srcfile= s:srcfiledict{t:gdbmgrtab}[srcfile]
"		call Decho("srcfile<".srcfile."> (dictionary lookup)")
	    break
	   else
	    let choice  = confirm("Select which ".srcfile.": ",srcfile2)
	    let srclist = split(srcfile2,'\n')
	    if 1 <= choice && choice <= len(srclist)
	     let srcfile2 = srclist[choice-1]
	     if filereadable(srcfile2)
"	      call Decho("found srcfile<".srcfile2.">")
		  " enter srcfile -> srcfile2 mapping into s:srcfiledict dictionary
	      if !exists("s:srcfiledict{t:gdbmgrtab}")
"		   call Decho("creating s:srcfiledict".t:gdbmgrtab)
		   let s:srcfiledict{t:gdbmgrtab}= {}
		  endif
		  let s:srcfiledict{t:gdbmgrtab}[srcfile]= srcfile2
"		  call Decho("let s:srcfiledict".t:gdbmgrtab."[".srcfile."]=".srcfile2)
	      let srcfile= srcfile2
	      break
	     endif
	    endif
	   endif
	  endif
	 endif
"	 call Decho("not readable: srcfile2<".srcfile2.">")
	 if !exists("g:gdbmgr_srcpath") || g:gdbmgr_srcpath == ""
	  let g:gdbmgr_srcpath= ""
	 endif

	 " ask user for a (comma-delimited) source path
	 " an empty string will wipe out the current g:gdbmgr_srcpath
	 " a plain "," will remove the last path component
     redraw
	 call inputsave()
"	 call Decho('get newsrcpath via input("Please give a (comma-delimited) source path: "')
	 let newsrcpath= input("Please give a (comma-delimited) source path for<".srcfile.">: ")
	 call inputrestore()
	 if newsrcpath == ""
	  " clear the source path
	  let g:gdbmgr_srcpath= newsrcpath
	 elseif newsrcpath == ","
	  " remove the last component of the source path
"	  call Decho("remove last component of source path")
	  let g:gdbmgr_srcpath= substitute(g:gdbmgr_srcpath,',[^,]*$','','')
	 else
	  " remove srcfile if given from the newsrcpath
"	  call Decho("remove srcfile when its given from newsrcpath<".newsrcpath.">")
	  let newsrcpath= substitute(newsrcpath,"/".srcfile,"","g")
	  if g:gdbmgr_srcpath == ""
	   let g:gdbmgr_srcpath= newsrcpath
	  else
	   let g:gdbmgr_srcpath= g:gdbmgr_srcpath.",".newsrcpath
	  endif
	 endif
"	 call Decho("g:gdbmgr_srcpath<".g:gdbmgr_srcpath.">")
	 call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("g:gdbmgr_srcpath<".g:gdbmgr_srcpath.">")
	endwhile

	" tell gdb about the source directory
	if srcfile =~ '/'
	 let newpath= substitute(srcfile,'/[^/]\+$','','')
	 if !exists("t:gdbmgr_srcpath")
	  let t:gdbmgr_srcpath          = {}
	  let t:gdbmgr_srcpath[newpath] = 1
	  call s:GdbMgrSend(16,"gmGdb",s:server."directory ".newpath)
	 elseif !has_key(t:gdbmgr_srcpath,newpath)
	  let t:gdbmgr_srcpath[newpath] = 1
	  call s:GdbMgrSend(17,"gmGdb",s:server."directory ".newpath)
	 endif
	endif

	" edit the source file
"	call Decho("edit source file<".srcfile.">")
	exe "sil keepa e! ".srcfile
	let t:srcfile = srcfile
	let t:srcline = srcline
"	call Decho("set t:srcfile<".t:srcfile.":".t:srcline."> buf#".bufnr("%"))

	" remove [Source] buffer
	" (the extra bufname check is because I've caught vim wiping a buffer NOT named [Source] when depending solely on bufnr('[Source]'))
	if bufexists("[Source]")
	 let srcbuf= bufnr('[Source]')
	 if bufname(srcbuf) == '[Source]'
"	  call Dredir("(before)","ls!")
"	  call Decho("removing [Source] buffer#".srcbuf)
	  exe srcbuf."bw"
"	  call Dredir("(after)","ls!")
	 endif
	endif

	" update the registry
"	call Decho("update the registry")
	let s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum      = bufnr("%")
	if !exists("s:gdbmgr_registry_{t:gdbmgrtab}[".bufnr("%")."]")
     let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")]     = {}
	endif
	let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code = "S"
"	call Decho("set s:gdbmgr_registry_".t:gdbmgrtab."[S].bufnum=".s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum)
"	call Decho("set s:gdbmgr_registry_".t:gdbmgrtab."[".bufnr("%")."].code=S")

   exe srcline
   if has("signs")
"	call Decho("initializing signs")
	exe "sil! sign unplace ".t:gdbmgrsignbase
    exe "sign place ".t:gdbmgrsignbase." line=".srcline." name=CurLineSign file=".srcfile
"    call Decho("sign place ".t:gdbmgrsignbase." line=".srcline." name=CurLineSign file=".srcfile)
   endif
   if has("folding") && foldclosed('.') > 0
    keepj norm! zMzx
   endif
   keepj norm! z.
   setlocal cul bh=hide noml
   let t:srcfile= simplify(srcfile)
   let t:srcline= srcline
"   call Decho("set t:srcfile<".t:srcfile.":".t:srcline.">")

   " remove all insert-mode abbreviations -- they're likely to interfere with program operation
   sil iabc

   " set up local maps and settings
"   call Decho('(GdbMgrSourceInitFile) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
   setlocal noma ro
   nn <buffer> <silent> <F1>		:he gdbmgr-source<cr>
   nn <buffer> <silent> <c-up>		:<c-u>call <SID>FuncstackChgline(v:count1)<cr>
   nn <buffer> <silent> <c-down>	:<c-u>call <SID>FuncstackChgline(-v:count1)<cr>
   nn <buffer> <silent> <F6>		:<c-u>call <SID>BreakptToggle()<cr>
   nn <buffer> <silent> <c-F6>		:<c-u>call gdbmgr#BufSwitch()<cr>
   nn <buffer> <silent> <s-F6>		:<c-u>call <SID>BreakptTemp()<cr>
   nn <buffer> <silent> <F7>		:<c-u>call <SID>SourceEdit()<cr>
   nn <buffer> <silent> <s-F7>		:<c-u>call <SID>CheckptSave()<cr>
   nn <buffer> <silent> c			:<c-u>call gdbmgr#GdbMgrCmd("c")<cr>
   nn <buffer> <silent> f			:<c-u>call gdbmgr#GdbMgrCmd("finish")<cr>
   nn <buffer> <silent> n			:<c-u>call gdbmgr#GdbMgrCmd("n ".v:count1)<cr>
   nn <buffer> <silent> N			:<c-u>call gdbmgr#GdbMgrCmd("N ".v:count1)<cr>
   nn <buffer> <silent> s			:<c-u>call gdbmgr#GdbMgrCmd("s ".v:count1)<cr>
   nn <buffer> <silent> S			:<c-u>call gdbmgr#GdbMgrCmd("S ".v:count1)<cr>
   nn <buffer> <silent> u			:<c-u>call gdbmgr#GdbMgrCmd("u")<cr>
   nn <buffer> <silent> U			:<c-u>call gdbmgr#GdbMgrCmd("U")<cr>

   " set up balloon evaluation of variables
"   call Decho("version=".v:version." has(balloon_eval)=".has("balloon_eval")." l:bexpr<".&l:bexpr."> g:gdbmgr_nobeval<".(exists("g:gdbmgr_nobeval")? "exists>" : "does not exist>"))
   if v:version >= 700 && has("balloon_eval") && &l:bexpr == "" && !exists("g:gdbmgr_nobeval")
"	call Decho("setting up balloon evaluation for b#".bufnr("%"))
	let &l:bexpr="gdbmgr#GdbSourceBalloon()"
	set beval
   endif

   call s:GdbMgrCloseCodedBuf()
  endif

"  call Dret("gdbmgr#GdbMgrSourceInitFile : ".(exists("t:srcfile")? "t:srcfile<".t:srcfile.">" : "t:srcfile doesn't exist!"))
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbSourceBalloon: supports beval/l:bexpr handling {{{2
fun! gdbmgr#GdbSourceBalloon()
"  call Dfunc("gdbmgr#GdbSourceBalloon()")
"  call Decho("(gdbmgr#GdbSourceBalloon) s:gdbmgr".(exists("t:gdbmgrtab")? t:gdbmgrtab : "<n/a>")."_running<".(exists("s:gdbmgr{t:gdbmgrtab}_running")? s:gdbmgr{t:gdbmgrtab}_running : "n/a").">")
  if exists("t:gdbmgrtab") && s:gdbmgr{t:gdbmgrtab}_running == "S"
   let srcbuf = s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum
"   call Decho("(gdbmgr#GdbSourceBalloon) srcbuf#".srcbuf)
"   call Decho("(gdbmgr#GdbSourceBalloon) v:beval_text<".v:beval_text.">")
   if v:beval_text =~ '^\h'
    if srcbuf != -1
     let srcwin = bufwinnr(srcbuf)
"     call Decho("(gdbmgr#GdbSourceBalloon) srcwin#".srcwin)
     if srcwin != -1
      if v:beval_winnr+1 == srcwin
	   let mesg = s:GdbMgrSend(18,"gmGdb",s:server.s:output.v:beval_text)
"       call Decho("(gdbmgr#GdbSourceBalloon) mesg<".mesg.">")
       if mesg =~ "=" && mesg !~ 'No symbol "\S\+" in current context'
        let mesg = substitute(mesg,'^.\{-} = ',v:beval_text.' = ','')
        let mesg = substitute(mesg,'\n','','')
"        call Dret("gdbmgr#GdbSourceBalloon <".mesg.">")
        return mesg
       endif
      endif
     endif
    endif
   endif
  endif
"  call Dret("gdbmgr#GdbSourceBalloon <>")
  return ""
endfun

" ---------------------------------------------------------------------
" s:SourceEdit: toggles source window editing/mappings {{{2
fun! s:SourceEdit()
"  call Dfunc("s:SourceEdit()")
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:SourceFastUpdate : gdbmgr never initialized")
   return
  endif

  " prepare to edit Source window
  if s:GdbMgrOpenCodedBuf("S") == 0
"   "   call Dret("s:SourceEdit : s:GdbMgrOpenCodedBuf(S) yielded 0!")
   return
  endif

  if &ma == 1
   " set up gdbmgr-style maps
   if &mod
	call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** source modified!")
   else
	call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("re-entered gdb mode")
   endif
   setlocal noma ro nowrite
   nn <buffer> <silent> <F1>	 :he gdbmgr-source<cr>
   nn <buffer> <silent> <c-up>	 :<c-u>call <SID>FuncstackChgline(v:count1)<cr>
   nn <buffer> <silent> <c-down> :<c-u>call <SID>FuncstackChgline(-v:count1)<cr>
   nn <buffer> <silent> <c-F6>	 :<c-u>call gdbmgr#BufSwitch()<cr>
   nn <buffer> <silent> <F6>	 :<c-u>call <SID>BreakptToggle()<cr>
   nn <buffer> <silent> <s-F6>	 :<c-u>call <SID>BreakptTemp()<cr>
   nn <buffer> <silent> <F7>	 :<c-u>call <SID>SourceEdit()<cr>
   nn <buffer> <silent> <s-F7>	 :<c-u>call <SID>CheckptSave()<cr>
   nn <buffer> <silent> c		 :<c-u>call gdbmgr#GdbMgrCmd("c")<cr>
   nn <buffer> <silent> f		 :<c-u>call gdbmgr#GdbMgrCmd("finish")<cr>
   nn <buffer> <silent> n		 :<c-u>call gdbmgr#GdbMgrCmd("n ".v:count1)<cr>
   nn <buffer> <silent> N		 :<c-u>call gdbmgr#GdbMgrCmd("N ".v:count1)<cr>
   nn <buffer> <silent> s		 :<c-u>call gdbmgr#GdbMgrCmd("s ".v:count1)<cr>
   nn <buffer> <silent> S		 :<c-u>call gdbmgr#GdbMgrCmd("S ".v:count1)<cr>
   nn <buffer> <silent> u		 :<c-u>call gdbmgr#GdbMgrCmd("u")<cr>
   nn <buffer> <silent> U		 :<c-u>call gdbmgr#GdbMgrCmd("U")<cr>

   call s:GdbMgrSetupGotoMaps()

  else
   " remove gdbmgr-style maps and restore user maps
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** Editing a source file invalidates the binary!")
   setlocal ma noro write
   sil! nunmap <buffer> <F1>    
   sil! nunmap <buffer> <c-up>  
   sil! nunmap <buffer> <c-down>
   sil! nunmap <buffer> <c-F6>  
   sil! nunmap <buffer> <F6>    
   sil! nunmap <buffer> <s-F6>  
   sil! nunmap <buffer> <s-F6>  
   sil! nunmap <buffer> <s-F7>  
   sil! nunmap <buffer> c
   sil! nunmap <buffer> f
   sil! nunmap <buffer> n
   sil! nunmap <buffer> N
   sil! nunmap <buffer> s
   sil! nunmap <buffer> S
   sil! nunmap <buffer> u
   sil! nunmap <buffer> U
   call RestoreUserMaps("gdbmgr")
  endif
  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:SourceEdit")
endfun

" ---------------------------------------------------------------------
" s:SourceFastUpdate: just moves the current line and its sign around when it can {{{2
"                     Otherwise, it does a full gdbmgr#GdbMgrSourceInitFile()
"
"   call s:SourceFastUpdate() -- will query with "info line" on its own to find what
"                                the source window should be displaying
"   call s:SourceFastUpdate(filename,fileline)
"                             -- will display the specified file at the given line
fun! s:SourceFastUpdate(...)
"  call Dfunc("s:SourceFastUpdate() a:0=".a:0)

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:SourceFastUpdate : gdbmgr never initialized")
   return
  endif

  if s:GdbMgrOpenCodedBuf("S") == 0
"   call Dret("s:SourceFastUpdate : no Source window/buffer")
   return
  endif

  " get the filename+fileline
  if a:0 < 2
"    call Decho("get the filename+fileline (a:0=".a:0.")")
	" send query to gdb
	let gdbcmd = s:server."where"
	let mesg   = s:GdbMgrSend(19,"gmGdb",gdbcmd)
	let mesg   = s:GdbMgrMesgFix(mesg)

	" clean leading newlines and multiple contiguous newlines
	let mesg= substitute(mesg,'^\n\+','','g')
	let mesg= substitute(mesg,'\n\{2,}','\n','g')
"    call Decho("cleaned mesg<".mesg.">")

	" interpret mesg
	if mesg =~ "No stack"
	 let gdbcmd = s:server."info line"
	 let mesg   = s:GdbMgrSend(20,"gmGdb",s:server."list")
	 let mesg   = s:GdbMgrSend(21,"gmGdb",gdbcmd)
	 if mesg =~ "out of range"
"	  call Dret("s:SourceFastUpdate : ".mesg)
	  return
	 endif
	endif
	let retry= 1
	while  retry
"     call Decho("mesg<".mesg.">")
	 let  retry= 0

	 if  mesg =~ '^#\d\+\s'
	  if mesg !~ '^.\{-} at '
	   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("file and line number not known")
"	   call Dret("s:SourceFastUpdate : file+line not known")
	   return
	  else
	   let filename = substitute(mesg,'^.\{-} at \(\S\{-}\.\S\{-}\):\(\d\+\)\_.*$','\1','')
	   let fileline = substitute(mesg,'^.\{-} at \(\S\{-}\.\S\{-}\):\(\d\+\)\_.*$','\2','')
	  endif
"	  call Decho("case ^#: filename<".filename."> fileline#".fileline)
	 elseif mesg =~ '^Line'
	  let filename = substitute(mesg,'Line \(\d\+\) of "\([^"]\+\)".*$','\2','')
	  let fileline = substitute(mesg,'Line \(\d\+\) of "\([^"]\+\)".*$','\1','')
"	  call Decho("case ^Line: filename<".filename."> fileline#".fileline)
	 elseif  mesg =~ '^Hardware watchpoint'
	  call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
	  let mesg = s:GdbMgrMesgFix(mesg)
	  let retry= 1

	 elseif  mesg == ""
"	  call Dret("s:SourceFastUpdate : ignoring non-response")
      return
	 else
	  call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("bad response: asked<".gdbcmd."> but got mesg<".substitute(mesg,"\n","","g").">!")
"	   call Dret("s:SourceFastUpdate : bad response")
      return
    endif
   endwhile
  else
	" use specified pair
"	call Decho("use specified filename<".a:1."> and fileline#".a:2)
   let filename = a:1
   let fileline = a:2
  endif

  if simplify(expand("%")) == filename
	" same file -- just move current line and associated signs
"   call Decho("in same file: simplify(".expand("%").") same as filename<".filename.">")
   exe fileline
   if has("signs") && exists("t:signidlist")
	 exe "sign unplace ".t:gdbmgrsignbase
	 exe "sign place ".t:gdbmgrsignbase." line=".fileline." name=CurLineSign file=".filename
   endif
	if has("folding") && foldclosed('.') > 0
	 keepj norm! zMzx
	endif
	keepj norm! z.

  else
	" different file
"	call Decho("not in same file: simplify(".expand("%").") differs from filename<".filename.">")
"	call Decho("exe sil! e ".fnameescape(filename))
	exe "sil! e ".fnameescape(filename)
	let s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum= bufnr("%")
"	call Decho("set s:gdbmgr_registry_".t:gdbmgrtab."[S].bufnum=".s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum)
	call gdbmgr#GdbMgrSourceInitFile(filename,fileline)
	if has("folding") && foldclosed('.') > 0
	 keepj norm! zMzx
	endif
	keepj norm! z.
  endif

  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:SourceFastUpdate")
endfun

" ---------------------------------------------------------------------
" s:SourceSigns: update breakpoint signs {{{2
fun! s:SourceSigns()
"  call Dfunc("s:SourceSigns()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:SourceSigns : gdbmgr never initialized")
   return
  endif

  " remove any previously placed signs
  if exists("t:signidlist")
"   call Decho("t:signidlist".string(t:signidlist))
   " remove gdbmgr's signs no matter what buffer/file they're in
"   call Decho("remove all breakpoint signs")
   for id in t:signidlist
	exe "sign unplace ".id
   endfor
   unlet t:signidlist
  endif

  " edit breakpoint buffer
  if s:GdbMgrOpenCodedBuf("B") == 0
   if !exists("s:SourceSignsSendErrorGiven{t:gdbmgrtab}")
	" only emit no Breakpoint buffer message once (per tab)
	let s:SourceSignsSendErrorGiven{t:gdbmgrtab}= 1
    echohl Error
	redraw|echomsg "(s:SourceSigns) attempt to install breakpoints with no breakpoints window"
    echohl None
   endif
"   call Dret("s:SourceSigns")
   return
  endif

  " get Source-window buffer
"  call Decho("get Source's window and buffer numbers")
  let srcbuf = s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum
"  call Decho("srcbuf#".srcbuf.((srcbuf > 0)? "<".bufname(srcbuf).">" : 'n/a'))
  if srcbuf > 0
   let t:srcfile = simplify(bufname(srcbuf))
"   call Decho("set t:srcfile<".t:srcfile.">  srcbuf#".srcbuf)
  else
"   call Decho("srcbuf not present")
  endif

  " place signs (ie. read and interpret the Breakpt buffer)
"  call Decho("place breakpoint signs")
  let id           = t:gdbmgrsignbase
  let t:signidlist = []
  let iline        = 1
  while iline <= line("$")
"   call Decho("(SourceSigns) placing signs: iline=".iline)
   let brkcmd = getline(iline)
   if brkcmd =~ 'Num Type' || brkcmd =~ 'No breakpoints or watchpoints' || brkcmd == ""
	let iline= iline + 1
	continue
   endif
"   call Decho("brkcmd   <".brkcmd.">")
"   call Decho("t:srcfile<".(exists("t:srcfile")? t:srcfile : '--null--').">")
   let brknum  = substitute(brkcmd,'#\(\d\+\)\s\+\(\S\+\)\s\+\(\S\+\):\(\d\+\)\s*\~\=$','\1','')
   let brktype = substitute(brkcmd,'#\(\d\+\)\s\+\(\S\+\)\s\+\(\S\+\):\(\d\+\)\s*\~\=$','\2','')
   let brkfile = substitute(brkcmd,'#\(\d\+\)\s\+\(\S\+\)\s\+\(\S\+\):\(\d\+\)\s*\~\=$','\3','')
   let brkline = substitute(brkcmd,'#\(\d\+\)\s\+\(\S\+\)\s\+\(\S\+\):\(\d\+\)\s*\~\=$','\4','')
   let brkdis  = (brkcmd =~ '\~$')
"   call Decho("brk#   <".brknum.">")
"   call Decho("brktype<".brktype.">")
"   call Decho("brkfile<".brkfile.">")
"   call Decho("brkline<".brkline.">")
"   call Decho("brkdis =".brkdis)
"   call Decho("srcfile<".simplify(t:srcfile).">")
   if brkfile == simplify(t:srcfile) || simplify(t:srcfile) =~ "/".brkfile."$"
    let id           = t:gdbmgrsignbase + brknum
    let t:signidlist = t:signidlist + [id]

	if brkcmd !~ 'tmp-breakpoint'
	 " handle (disabled) temporary breakpoints
	 if !filereadable(brkfile) && g:gdbmgr_srcpath != ""
	  for path in split(g:gdbmgr_srcpath,",")
"	   call Decho("findfile(brkfile<".brkfile.">,path<".path.">)")
	   let tbrkfile= findfile(brkfile,path)
	   if filereadable(tbrkfile)
		break
	   endif
	  endfor
	 endif
	 if !exists("tbrkfile") || tbrkfile == ""
	  let brkfile= t:srcfile
	 else
	  let brkfile= tbrkfile
	 endif
	 if brkdis
	  " handle disabled temporary breakpoints
"	  call Decho("sign place ".id." line=".brkline." name=DBreakptSign file=".fnameescape(brkfile))
	  exe "sign place ".id." line=".brkline." name=DBreakptSign file=".fnameescape(brkfile)
	 else
	  " handle temporary breakpoints
"	  call Decho("sign place ".id." line=".brkline." name=BreakptSign file=".fnameescape(brkfile))
	  exe "sign place ".id." line=".brkline." name=BreakptSign file=".fnameescape(brkfile)
	 endif

	elseif brkdis
	 " handle disabled breakpoints
	 try
	  exe "sil! sign place ".id." line=".brkline." name=DTBreakptSign file=".simplify(t:srcfile)
	 catch /^Vim\%((\a\+)\)\=:E158/
	  exe "sil! sign place ".id." line=".brkline." name=DTBreakptSign file=".brkfile
	 endtry
"     call Decho("sign place ".id." line=".brkline." name=DTBreakptSign file=".brkfile)
"	 call Decho("sign place ".id." line=".brkline." name=BreakptSign file=".fnameescape(brkfile))
	 exe "sign place ".id." line=".brkline." name=BreakptSign file=".fnameescape(brkfile)
    else
	 try
	  exe "sil! sign place ".id." line=".brkline." name=TBreakptSign file=".simplify(t:srcfile)
	 catch /^Vim\%((\a\+)\)\=:E158/
	  exe "sil! sign place ".id." line=".brkline." name=TBreakptSign file=".brkfile
	 endtry
"     call Decho("sign place ".id." line=".brkline." name=TBreakptSign file=".brkfile)
    endif
   endif
   let iline= iline + 1
  endwhile

  " return to previous window
  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:SourceSigns")
endfun

" ---------------------------------------------------------------------
" s:ThreadInit: responsible for initializing the threads buffer {{{2
fun! s:ThreadInit() dict
"  call Dfunc("s:ThreadInit()")
  call gdbmgr#GdbMgrInitEnew()
  set ft=gdbmgr_threads
  call s:GdbMgrOptionSafe()
  sil! file Threads
  setlocal nobuflisted ro bh=hide bt=nofile
  let self.bufnum= bufnr("%")
  nn <buffer> <silent> <F1>				:he gdbmgr-threads<cr>
  nn <buffer> <silent> <cr>				:call <SID>ThreadSelect()<cr>
  nn <buffer> <silent> <c-F6>			:call gdbmgr#BufSwitch()<cr>
  nn <buffer> <silent> <2-leftmouse>	:<c-u><leftmouse>call <SID>ThreadSelect()<cr>
"  call Dret("s:ThreadInit")
endfun

" ---------------------------------------------------------------------
" s:ThreadUpdate: updates the Threads buffer {{{2
fun! s:ThreadUpdate() dict
"  call Dfunc("s:ThreadUpdate()")
  if exists("t:gdbmgrtab")

   " edit the Threads buffer
   if s:GdbMgrOpenCodedBuf("T") == 0
"	call Dret("s:ThreadUpdate : no threads window available")
    return
   endif

   let mesg = s:GdbMgrSend(7,"gmGdb",s:server."info threads")
   let mesg = s:GdbMgrMesgFix(mesg)

   " clean leading newlines and multiple contiguous newlines
   let mesg     = substitute(mesg,'^\n\+','','g')
   let mesg     = substitute(mesg,'\n\{2,}','\n','g')
"   call Decho("cleaned mesg<".mesg.">")
   let mesglist = split(mesg,"\n")

   " clear the threads buffer and make it editable
"   call Decho("clear Threads buffer and make it editable")
   setlocal nobuflisted ma noro bh=hide bt=nofile
   sil keepj %d
   let lzkeep= &lz
   set lz

   " install thread information into Threads buffer
"   call Decho("install thread information into Threads buffer")
"   call Decho("mesglist".string(mesglist))
   call setline(1,mesglist)
   sil! g/^[* ]/j
   keepj $
   redraw
   let &lz= lzkeep

   " make it not-editable and close the buffer
   setlocal noma ro cul nomod
   call s:GdbMgrCloseCodedBuf()

  endif
"  call Dret("s:ThreadUpdate")
endfun

" ---------------------------------------------------------------------
" s:ThreadSelect: called to change the current thread (by the <cr> map set up in s:ThreadInit) {{{2
fun! s:ThreadSelect()
"  call Dfunc("s:ThreadSelect()")

  if exists("t:gdbmgrtab")

   " edit the Threads buffer
   if s:GdbMgrOpenCodedBuf("T") == 0
"    call Dret("s:FuncstackUpdate : no funcstack window")
    return
   endif
   let curline= getline(".")
   let linenum= line(".")
   if curline =~ '^\s*\d\+'
	let pick= substitute(curline,'^\s*\(\d\+\)\s.*$','\1','')
	if pick =~ '^\d\+$'
	 let mesg = s:GdbMgrSend(7,"gmGdb",s:server."thread ".pick)
     let mesg = s:GdbMgrMesgFix(mesg)
     call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
     call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
     call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
	 exe linenum
	endif
   endif

   call s:GdbMgrCloseCodedBuf()
  endif

"  call Dret("s:ThreadSelect")
endfun

" ---------------------------------------------------------------------
" s:WatchpointInit: initializes the Watchpoint buffer {{{2
fun! s:WatchpointInit() dict
"  call Dfunc("s:WatchpointInit()")
  call gdbmgr#GdbMgrInitEnew()
  set ft=gdbmgr_watchpts
  sil file Watchpoints
  setlocal nobuflisted bt=nofile
  call s:GdbMgrOptionSafe()
  setlocal noro ma bh=hide
  let self.bufnum= bufnr("%")
"  call Decho('(WatchpointInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn  <buffer> <silent> <F1>	:he gdbmgr-watchpt<cr>
  nn  <buffer> <silent> <F6>   	:call <SID>WatchUpdateByMap()<cr>
  ino <buffer> <silent> =   	<c-o>:call <SID>WatchUpdateByMap()<cr><esc>A
  nn  <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
"  call Dret("s:WatchpointInit : bufnum#".self.bufnum)
endfun

" ---------------------------------------------------------------------
" s:WatchpointUpdate: updates the Watchpoint buffer {{{2
" Handles watchpoints.  Each line should be of the form
"   [arw] variable-name
fun! s:WatchpointUpdate() dict
"  call Dfunc("s:WatchpointUpdate()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:WatchpointUpdate : gdbmgr never initialized")
   return
  endif

  if s:GdbMgrOpenCodedBuf("W") == 0
"   call Dret("s:WatchpointUpdate : no watchpoint window available")
   return
  endif

  " clear all watchpoints
"	call Decho("clearing all watchpoints")
  let mesg     = s:GdbMgrSend(22,"gmGdb",s:server."info watchpoints")
  let mesg     = s:GdbMgrMesgFix(mesg)
  let mesglist = split(mesg,'\n')
  for mesg in mesglist
   if mesg =~ '\<watchpoint\>'
    let wpid= substitute(mesg,'^\s*\(\d\+\)\s.*$','\1','')
"	  call Decho("clearing watchpoint#".wpid)
	call s:GdbMgrSend(23,"gmGdb",s:server."disable ".wpid)
   endif
  endfor
  sil! keepj %s/\s*=\s.*$//e

  " (re-)install all watchpoints
  if line("$") > 1 || getline(".") != ""
"	 call Decho("(re-)installing all ".line("$")." watchpoints")
   let iline= 1
   while iline <= line("$")
    let wptype= substitute(getline(iline),'^\s*\([arw]\)\s*\(\S\+\)$','\1','')
    let wpvar = substitute(getline(iline),'^\s*\([arw]\)\s*\(\S\+\)$','\2','')
    if wptype !~ '^[arw]$'
     let wpcmd  = "watch"
     let wptype = 'w'
     let wpvar  = getline(iline)
    elseif wptype == 'w'
     let wpcmd= "watch"
    elseif wptype == 'r'
     let wpcmd= "rwatch"
    elseif wptype == 'a'
     let wpcmd= "awatch"
    endif
"	  call Decho("watchpoint: wptype<".wptype."> wpvar<".wpvar."> wpcmd<".wpcmd.">")
    let mesg = s:GdbMgrSend(24,"gmGdb",s:server."".wpcmd." ".wpvar)
    if mesg !~ 'No symbol'
     let mesg = s:GdbMgrSend(25,"gmGdb",s:server.s:output.wpvar)
     let mesg = substitute(mesg,'^\s*\$\d\+\s*[^=!><]=\s*','','')
     let mesg = substitute(mesg,"\n","","")
     call setline(iline,printf("%s %s = %s",wptype,wpvar,mesg))
    else
     call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
    endif
    let iline= iline + 1
   endwhile
  endif

  call s:GdbMgrCloseCodedBuf()
"  call Dret("s:WatchpointUpdate")
endfun

" ---------------------------------------------------------------------
" s:WatchUpdateByMap: update called via function key in Watchpoint buffer {{{2
fun! s:WatchUpdateByMap()
"  call Dfunc("s:WatchUpdateByMap()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   "   call Dret("s:WatchUpdateByMap : gdbmgr never initialized")
   return
  endif

  let curcol  = col(".")
  let curline = getline(".")
"  call Decho("curcol=".curcol." curline<".curline.">")
  if curcol > 2 && curline[col(".")-2] =~ '\s'
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
  else
   call setline(".",curline."=")
  endif
"  call Dret("s:WatchUpdateByMap")
endfun

" ---------------------------------------------------------------------
" s:FindGdbMgrTab: find a GdbMgr tab {{{2
"   Returns tab number of a GdbMgr tab
"           0 if it can't find one
fun! s:FindGdbMgrTab()
"  call Dfunc("s:FindGdbMgrTab()")
  " return tabpagenr if current tab is a GdbMgrTab
  if exists("t:gdbmgrtab")
   let t:gdbmgrtab= tabpagenr()
"   call Dret("s:FindGdbMgrTab ".t:gdbmgrtab)
   return t:gdbmgrtab
  endif

  " search for a GdbMgrTab
  let s:vdt= 0
  tabdo if exists("t:gdbmgrtab")|let s:vdt= tabpagenr()|endif

  " insure t:gdbmgrtab is set correctly and return
  if s:vdt > 0
   exe "tabn ".s:vdt
   unlet s:vdt
"   call Dret("s:FindGdbMgrTab ".t:gdbmgrtab)
   return t:gdbmgrtab
  else
   unlet s:vdt
"   call Dret("s:FindGdbMgrTab 0")
   return 0
  endif
endfun

" ---------------------------------------------------------------------
" s:RegisterForeignCode: maps a code to functions specified in a "foreign" file  {{{2
"                        The foreign file should have the following format, where X
"                        is the new code being supported.
"                        Foreign filename:  autoload/gdbmgrX.vim
"
"                             if &cp || exists("g:loaded_gdbmgrX")
"                              finish
"                             endif
"                             fun! gdbmgrX#Init() dict
"                             ...
"                             endfun
"                             fun! gdbmgrX#Update(srcbufnum) dict
"                             ...
"                             endfun
"                        Returns:  0 on success   -1 on failure
fun! s:RegisterForeignCode(code)
"  call Dfunc("s:RegisterForeignCode(code<".a:code.">)")
  let ret= -1
"  call Decho("run autoload/gdbmgr".a:code.".vim")
  exe "run autoload/gdbmgr".a:code.".vim"
  if exists("*gdbmgr".a:code."#Init")
   let initfunc = "gdbmgr".a:code."#Init"
   let updfunc  = "gdbmgr".a:code."#Update"
"   call Decho("Register initfunc<".initfunc."> updfunc<".updfunc.">")
   call gdbmgr#Register(a:code,initfunc,updfunc)
   let ret= 0
   if !exists("s:foreigncodes_{tabpagenr()}")
	let s:foreigncodes_{tabpagenr()}= []
   endif
   let s:foreigncodes_{tabpagenr()}= s:foreigncodes_{tabpagenr()} + [a:code]
  endif
"  call Dret("s:RegisterForeignCode ".ret." : ".(exists("s:foreigncodes")? string(s:foreigncodes) : "s:foreigncodes n/a"))
  return ret
endfun

" ---------------------------------------------------------------------
" s:GdbMgrBuildBufList: builds a list of all buffers associated with GdbMgr in the current tab {{{2
fun! s:GdbMgrBuildBufList()
"  call Dfunc("s:GdbMgrBuildBufList() curbuf#".bufnr("%")." win#".winnr())

  " sanity check
  if !exists("t:gdbmgrtab")
"   call Dret("s:GdbMgrBuildBufList : gdbmgr never initialized")
   return
  endif
"  call Decho("registry=".string(s:gdbmgr_registry_{t:gdbmgrtab}))

  let curbuf    = bufnr("%")
  let firstcode = s:gdbmgr_registry_{t:gdbmgrtab}[curbuf].code
  let code      = firstcode
  while 1
   if code != 'S'
    call add(s:buflist,s:gdbmgr_registry_{t:gdbmgrtab}[code].bufnum)
   endif
   let nxtcode= s:gdbmgr_registry_{t:gdbmgrtab}[code].nxt
"   call Decho("code<".code."> nxtcode<".nxtcode.">")
   if nxtcode == firstcode
	break
   endif
   let code= nxtcode
  endwhile

"  call Dret("s:GdbMgrBuildBufList s:buflist".string(s:buflist))
endfun

" ---------------------------------------------------------------------
" s:GdbMgrCheckSrcChg: called via a BufWinEnter, handles new source in the source coded window {{{2
fun! s:GdbMgrCheckSrcChg()
"  call Dfunc("s:GdbMgrCheckSrcChg()")

  " bypass source change when so ordered (ex. when initializing a new coded buffer)
  if exists("s:bypassCheckSrcChg") && s:bypassCheckSrcChg
"   call Dret("s:GdbMgrCheckSrcChg : bypassed")
   return
  endif
  if !exists("t:gdbmgrtab")
"  call Dret("s:GdbMgrCheckSrcChg : t:gdbmgrtab doesn't exist")
   return
  endif
  if !exists("s:gdbmgr_registry_{t:gdbmgrtab}['S'].bufnum")
"  call Dret("s:GdbMgrCheckSrcChg : registry for S doesn't exist")
   return
  endif

  if exists("t:gdbmgrtab") && exists('s:gdbmgr_registry_{'.t:gdbmgrtab.'}['.bufnr("%").'].code')
   let code= s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code
  else
   let code= "none"
  endif
"  call Decho("current win#".winnr()." line#".line(".")." buf#".bufnr("%")." code<".code.">")

  " check if the source buffer currently has an associated window
"  call Decho("check if source buffer currently has an associated window")
  let srcbuf = s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum
  let srcwin = bufwinnr(srcbuf)
"  call Decho("srcbuf<".srcbuf."> srcwin#".srcwin." curwin#".winnr()." expand(%)<".expand("%").">")

  if srcwin == -1
   " The current source buffer is not showing.
   " Presumably we now have a new source buffer (if its not already a coded buffer)
"   call Decho("srcbuf not currently in a window")

   if !exists("s:gdbmgr_registry_{t:gdbmgrtab}[bufnr('%')].code")
	" new buffer does not have a code; presumably then its a new source
"	call Decho("new buffer#".bufnr("%")." has no code -- assume its a new source")
	" update the registry with new source buffer
	let s:gdbmgr_registry_{t:gdbmgrtab}['S'].bufnum     = bufnr("%")
	let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")]     = {}
    let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code= 'S'
	let t:srcbuf                                        = bufnr("%")
	" install maps
    nn <buffer> <silent> <F1>		:he gdbmgr-source<cr>
    nn <buffer> <silent> <c-up>		:<c-u>call <SID>FuncstackChgline(v:count1)<cr>
    nn <buffer> <silent> <c-down>	:<c-u>call <SID>FuncstackChgline(-v:count1)<cr>
    nn <buffer> <silent> <c-F6>		:<c-u>call gdbmgr#BufSwitch()<cr>
    nn <buffer> <silent> <F6>		:<c-u>call <SID>BreakptToggle()<cr>
    nn <buffer> <silent> <s-F6>		:<c-u>call <SID>BreakptTemp()<cr>
    nn <buffer> <silent> <F7>		:<c-u>call <SID>SourceEdit()<cr>
    nn <buffer> <silent> c			:<c-u>call gdbmgr#GdbMgrCmd("c")<cr>
    nn <buffer> <silent> f			:<c-u>call gdbmgr#GdbMgrCmd("finish")<cr>
    nn <buffer> <silent> n			:<c-u>call gdbmgr#GdbMgrCmd("n ".v:count1)<cr>
    nn <buffer> <silent> N			:<c-u>call gdbmgr#GdbMgrCmd("N ".v:count1)<cr>
    nn <buffer> <silent> s			:<c-u>call gdbmgr#GdbMgrCmd("s ".v:count1)<cr>
    nn <buffer> <silent> S			:<c-u>call gdbmgr#GdbMgrCmd("S ".v:count1)<cr>
    nn <buffer> <silent> u			:<c-u>call gdbmgr#GdbMgrCmd("u")<cr>
    nn <buffer> <silent> U			:<c-u>call gdbmgr#GdbMgrCmd("U")<cr>

   elseif s:gdbmgr_registry_{t:gdbmgrtab}[bufnr('%')].code == 'S'
	" the buffer previously appears to have been a source buffer.
	" Reinstate the buffer as the source buffer.
"	call Decho("buffer appears previously to have been a source buffer")
	let s:gdbmgr_registry_{t:gdbmgrtab}['S'].bufnum= bufnr("%")
   endif
  else
"   call Decho("already coded: current window#".winnr()." line#".line(".")." buf#".bufnr("%")." code<".code.">")
  endif

  " even though the source-code buffer may have been seen before and kept as hidden,
  " it still needs to have its signs updated.  Also update the Breakpoints buffer.
"  call Decho("refresh signs (srcwin#".srcwin.")")
  call s:SourceSigns()
  call s:GdbMgrUpdate("b")

"  call Dret("s:GdbMgrCheckSrcChg")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrKill: {{{2
fun! s:GdbMgrKill()
"  call Dfunc("s:GdbMgrKill()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:GdbMgrKill : gdbmgr never initialized")
   return
  endif

  " show new funcstack -- which should be "No Function stack"
  call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()

  " show new threads listing
  call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()

  " open the source buffer for editing (actually, map removal)
  if s:GdbMgrOpenCodedBuf("S") == 0
"   call Dret("s:GdbMgrKill : gdbmgr never initialized")
   return
  endif

  " make source window editable and remove local maps
  sil! nunmap <buffer> c
  sil! nunmap <buffer> f
  sil! nunmap <buffer> n
  sil! nunmap <buffer> N
  sil! nunmap <buffer> s
  sil! nunmap <buffer> S
  sil! nunmap <buffer> u

  " restore window
  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:GdbMgrKill")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrMenu: {{{2
fun! s:GdbMgrMenu(...)
"  call Dfunc("s:GdbMgrMenu() a:0=".a:0)
  if a:0 > 0
   let code= a:1
  elseif exists("t:gdbmgrtab")
   if exists("s:gdbmgr_registry_{t:gdbmgrtab}[bufnr('%')]")
    let code= s:gdbmgr_registry_{t:gdbmgrtab}[bufnr('%')].code
   else
"	call Dret("s:GdbMgrMenu : not a Gdbmgr application")
    return
   endif
  else
"   call Dret("s:GdbMgrMenu : not a Gdbmgr window")
   return
  endif
"  call Decho("code=".code)
  exe 'sil! unmenu '.g:DrChipTopLvlMenu.'Gdbmgr'

  if code == "I"
"   call Decho('doing "I" menu')
   exe 'sil! menu '.g:DrChipTopLvlMenu.'Gdbmgr.Attach<tab>:DA	:DA '
   exe 'sil! menu '.g:DrChipTopLvlMenu.'Gdbmgr.Init<tab>:DI	:DI<cr>'

  elseif code == 'A'
"   call Decho('doing "A" menu')
   exe 'sil! menu 500.10 '.g:DrChipTopLvlMenu.'Gdbmgr.Assembly\ Menu	<Nop>'
   exe 'sil! menu 500.20 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP1-	:'
   exe 'sil! menu 500.30 '.g:DrChipTopLvlMenu.'Gdbmgr.Help<tab>\<F1>	<F1>'
   exe 'sil! menu 500.40 '.g:DrChipTopLvlMenu.'Gdbmgr.Buffer\ Switch<tab>\<c-F6>	<c-F6>'
   exe 'sil! menu 500.50 '.g:DrChipTopLvlMenu.'Gdbmgr.Gdb\ continue<tab>c	c'
   exe 'sil! menu 500.60 '.g:DrChipTopLvlMenu.'Gdbmgr.Gdb\ next<tab>n	n'
   exe 'sil! menu 500.70 '.g:DrChipTopLvlMenu.'Gdbmgr.Gdb\ step<tab>s	s'

  elseif code == 'B'
"   call Decho('doing "B" menu')
   exe 'sil! menu 500.10 '.g:DrChipTopLvlMenu.'Gdbmgr.Breakpoints\ Menu	<Nop>'
   exe 'sil! menu 500.20 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP1-	:'
   exe 'sil! menu 500.30 '.g:DrChipTopLvlMenu.'Gdbmgr.Help<tab>\<F1>	<F1>'
   exe 'sil! menu 500.40 '.g:DrChipTopLvlMenu.'Gdbmgr.Buffer\ Switch<tab>\<c-F6>	<c-F6>'

  elseif code == 'C'
"   call Decho('doing "C" menu')
   exe 'sil! menu 500.10 '.g:DrChipTopLvlMenu.'Gdbmgr.Commands\ Menu	<Nop>'
   exe 'sil! menu 500.20 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP1-	:'
   exe 'sil! menu 500.30 '.g:DrChipTopLvlMenu.'Gdbmgr.Help<tab>\<F1>	<F1>'
   exe 'sil! menu 500.40 '.g:DrChipTopLvlMenu.'Gdbmgr.Buffer\ Switch<tab>\<c-F6>	<c-F6>'
   exe 'sil! menu 500.50 '.g:DrChipTopLvlMenu.'Gdbmgr.Exe\ Line<tab>\<cr>	<cr>'
   exe 'sil! menu 500.60 '.g:DrChipTopLvlMenu.'Gdbmgr.Poll<tab>\<s-F6>	<s-F6>'

  elseif code == 'E'
"   call Decho('doing "E" menu')
   exe 'sil! menu 500.10 '.g:DrChipTopLvlMenu.'Gdbmgr.Expressions\ Menu	<Nop>'
   exe 'sil! menu 500.20 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP1-	:'
   exe 'sil! menu 500.30 '.g:DrChipTopLvlMenu.'Gdbmgr.Help<tab>\<F1>	<F1>'
   exe 'sil! menu 500.40 '.g:DrChipTopLvlMenu.'Gdbmgr.Buffer\ Switch<tab>\<c-F6>	<c-F6>'
   exe 'sil! menu 500.50 '.g:DrChipTopLvlMenu.'Gdbmgr.Funcstack\ Up<tab>\<c-up>	<c-up>'
   exe 'sil! menu 500.60 '.g:DrChipTopLvlMenu.'Gdbmgr.Funcstack\ Down<tab>\<c-down>	<c-down>'
   exe 'sil! menu 500.70 '.g:DrChipTopLvlMenu.'Gdbmgr.Update\ Expressions<tab>\<F6>	<F6>'

  elseif code == 'F'
"   call Decho('doing "F" menu')
   exe 'sil! menu 500.10 '.g:DrChipTopLvlMenu.'Gdbmgr.Funcstack\ Menu	<Nop>'
   exe 'sil! menu 500.20 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP1-	:'
   exe 'sil! menu 500.30 '.g:DrChipTopLvlMenu.'Gdbmgr.Help<tab>\<F1>	<F1>'
   exe 'sil! menu 500.40 '.g:DrChipTopLvlMenu.'Gdbmgr.Buffer\ Switch<tab>\<c-F6>	<c-F6>'
   exe 'sil! menu 500.50 '.g:DrChipTopLvlMenu.'Gdbmgr.Funcstack\ Up<tab>\<up>	<up>'
   exe 'sil! menu 500.60 '.g:DrChipTopLvlMenu.'Gdbmgr.Funcstack\ Down<tab>\<down>	<down>'

  elseif code == 'H'
"   call Decho('doing "H" menu')
   exe 'sil! menu 500.10 '.g:DrChipTopLvlMenu.'Gdbmgr.Checkpt\ Menu	<Nop>'
   exe 'sil! menu 500.20 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP1-	:'
   exe 'sil! menu 500.30 '.g:DrChipTopLvlMenu.'Gdbmgr.Help<tab>\<F1>	<F1>'
   exe 'sil! menu 500.40 '.g:DrChipTopLvlMenu.'Gdbmgr.Checkpt\ Restart<tab><cr>	call s:CheckptRestart()'
   exe 'sil! menu 500.50 '.g:DrChipTopLvlMenu.'Gdbmgr.Checkpt\ Delete<tab><del>	call s:CheckptDelete()'
   exe 'sil! menu 500.60 '.g:DrChipTopLvlMenu.'Gdbmgr.Checkpt\ Save<tab><s-F7>	call s:CheckptSave()'

  elseif code == 'M'
"   call Decho('doing "M" menu')
   exe 'sil! menu 500.10 '.g:DrChipTopLvlMenu.'Gdbmgr.Messages\ Menu	<Nop>'
   exe 'sil! menu 500.20 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP1-	:'
   exe 'sil! menu 500.30 '.g:DrChipTopLvlMenu.'Gdbmgr.Help<tab>\<F1>	<F1>'
   exe 'sil! menu 500.40 '.g:DrChipTopLvlMenu.'Gdbmgr.Buffer\ Switch<tab>\<c-F6>	<c-F6>'

  elseif code == 'S'
"   call Decho('doing "S" menu')
   exe 'sil! menu 500.10 '.g:DrChipTopLvlMenu.'Gdbmgr.Source\ Menu	<Nop>'
   exe 'sil! menu 500.20 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP1-	:'
   exe 'sil! menu 500.30 '.g:DrChipTopLvlMenu.'Gdbmgr.Help<tab>\<F1>	<F1>'
   exe 'sil! menu 500.40 '.g:DrChipTopLvlMenu.'Gdbmgr.Buffer\ Switch<tab>\<c-F6>	<c-F6>'
   exe 'sil! menu 500.50 '.g:DrChipTopLvlMenu.'Gdbmgr.Breakpoint\ Set<tab>\<F6>	<F6>'
   exe 'sil! menu 500.60 '.g:DrChipTopLvlMenu.'Gdbmgr.Breakpoint\ Set\ (temporary)<tab>\<s-F6>	<s-F6>'
   exe 'sil! menu 500.70 '.g:DrChipTopLvlMenu.'Gdbmgr.Edit\ Source<tab>\<F7>	<F7>'
   exe 'sil! menu 500.70 '.g:DrChipTopLvlMenu.'Gdbmgr.Checkpt\ Save<tab>\<s-F7>	<s-F7>'
   exe 'sil! menu 500.80 '.g:DrChipTopLvlMenu.'Gdbmgr.Funcstack\ Up<tab>\<c-up>	<c-up>'
   exe 'sil! menu 500.90 '.g:DrChipTopLvlMenu.'Gdbmgr.Funcstack\ Down<tab>\<c-down>	<c-down>'
   exe 'sil! menu 500.100'.g:DrChipTopLvlMenu.'Gdbmgr.Gdb\ continue<tab>c	c'
   exe 'sil! menu 500.110'.g:DrChipTopLvlMenu.'Gdbmgr.Gdb\ finish<tab>f	f'
   exe 'sil! menu 500.120'.g:DrChipTopLvlMenu.'Gdbmgr.Gdb\ next<tab>n	n'
   exe 'sil! menu 500.130'.g:DrChipTopLvlMenu.'Gdbmgr.Gdb\ step<tab>s	s'
   exe 'sil! menu 500.140'.g:DrChipTopLvlMenu.'Gdbmgr.Gdb\ until<tab>u	u'

  elseif code == 'W'
"   call Decho('doing "W" menu')
   exe 'sil! menu 500.10 '.g:DrChipTopLvlMenu.'Gdbmgr.Watchpoints\ Menu	<Nop>'
   exe 'sil! menu 500.20 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP1-	:'
   exe 'sil! menu 500.30 '.g:DrChipTopLvlMenu.'Gdbmgr.Help<tab>\<F1>	<F1>'
   exe 'sil! menu 500.40 '.g:DrChipTopLvlMenu.'Gdbmgr.Buffer\ Switch<tab>\<c-F6>	<c-F6>'
   exe 'sil! menu 500.50 '.g:DrChipTopLvlMenu.'Gdbmgr.Update\ Watchpoints<tab>\<F6>	<F6>'
  endif

  " gdbmgr command line
  exe 'sil! menu 500.300 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP2-	:'
  exe 'sil! menu 500.310 '.g:DrChipTopLvlMenu.'Gdbmgr.Current\ File\ Line<tab>:DC	:DC<cr>'
  exe 'sil! menu 500.320 '.g:DrChipTopLvlMenu.'Gdbmgr.Exec\ Gdb\ Cmd<tab>:D	:D '
  exe 'sil! menu 500.330 '.g:DrChipTopLvlMenu.'Gdbmgr.Kill<tab>:DK	:DK<cr>'
  exe 'sil! menu 500.340 '.g:DrChipTopLvlMenu.'Gdbmgr.Quit<tab>:DQ	:DQ<cr>'
  exe 'sil! menu 500.350 '.g:DrChipTopLvlMenu.'Gdbmgr.Run<tab>:DR	:DR '
  exe 'sil! menu 500.360 '.g:DrChipTopLvlMenu.'Gdbmgr.Set\ Program\ Filename<tab>:DF	:DF '

  " switch buffer selections
  exe 'sil! menu 500.400 '.g:DrChipTopLvlMenu.'Gdbmgr.-SEP3-	:'
  exe 'sil! menu 500.405 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Assembly<tab>CA	CA'
  exe 'sil! menu 500.410 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Breakpoints<tab>CB	CB'
  exe 'sil! menu 500.415 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Checkpoints<tab>CH	CH'
  exe 'sil! menu 500.420 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Commands<tab>CC	CC'
  exe 'sil! menu 500.425 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Expressions<tab>CE	CE'
  exe 'sil! menu 500.430 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Funcstack<tab>CF	CF'
  exe 'sil! menu 500.435 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Messages<tab>CM	CM'
  exe 'sil! menu 500.440 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Netrw<tab>CN	CN'
  exe 'sil! menu 500.445 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Source<tab>CS	CS'
  exe 'sil! menu 500.450 '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ Watchpoints<tab>CW	CW'

  " install Goto coded-window maps and menu entries for foreign apps
  if exists("t:forappdict")
   let imenu= 480
   for code in keys(t:forappdict)
"	call Decho("install Goto coded-window map and menu entry for foreign app<".code.">")
	exe 'sil! menu 500.'.imenu.' '.g:DrChipTopLvlMenu.'Gdbmgr.Go\ to\ '.t:forappdict[code].'<tab>C'.code.'	C'.code
	exe 'nno <silent> C'.code.'	:call gdbmgr#GdbMgrUserGoto("'.code.'")<cr>'
	let imenu= imenu + 2
   endfor
  endif

"  call Dret("s:GdbMgrMenu")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrMesgFix: get rid of newline-only responses from gdb {{{2
fun! s:GdbMgrMesgFix(mesg)
"  call Dfunc("s:GdbMgrMesgFix()")
  let mesg    = a:mesg
  let sendcnt = 0
  while mesg =~ '^\n\+$' && sendcnt < 20
"   call Decho("got mesg<".mesg.">, retry#".(sendcnt+1))
   sleep 200m
   let mesg    = s:GdbMgrSend(1,"gmPoll")
   let sendcnt = sendcnt + 1
  endwhile
"  call Decho("got mesg<".mesg."> sendcnt=".sendcnt)
"  call Dret("s:GdbMgrMesgFix <".mesg.">")
  return mesg
endfun

" ---------------------------------------------------------------------
" s:NormalTermination: {{{2
fun! s:NormalTermination()
"  call Dfunc("s:NormalTermination()")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:NormalTermination : gdbmgr never initialized")
   return
  endif

  if s:GdbMgrOpenCodedBuf("S") == 0
"   call Dret("s:NormalTermination : no source buffer")
   return
  endif

  exe "sil! sign unplace ".t:gdbmgrsignbase
  set noro ma

  call s:GdbMgrCloseCodedBuf()

"  call Dret("s:NormalTermination")
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrAttach: attaches to a pid if given one, otherwise it tries {{{2
"                      to find the pid assuming that its been given a program name
fun! gdbmgr#GdbMgrAttach(gdbattach)
"  call Dfunc("gdbmgr#GdbMgrAttach(gdbattach<".a:gdbattach.">)")
  if !exists("t:gdbmgrtab")
"   call Decho("since t:gdbmgrtab doesn't exist, initializing gdbmgr")
   call gdbmgr#GdbMgrInit('--attaching--')
  endif
  if !exists("t:gdbmgrtab")
   echoerr "(gdbmgr#GdbMgrAttach) unable to initialize gdbmgr!"
"   call Dret("gdbmgr#GdbMgrAttach : unable to initialize gdbmgr")
   return
  endif
  if a:gdbattach =~ '^\d\+$'
   let pid= a:gdbattach
  else
   let gdbattach= substitute(a:gdbattach,'^.*/','','')
   let pidstring = system("ps -ea | grep '[ \\t]".gdbattach."$'")
   if pidstring == ""
	let mesg= gdbattach." does not appear currently to be running on your system"
	call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
"    call Dret("gdbmgr#GdbMgrAttach")
    return
   endif
"   call Decho("pidstring<".pidstring.">")
   let pidlist= split(pidstring,"\n")
"   call Decho("pidlist".string(pidlist))
   if len(pidlist) == 1
	let pid= substitute(pidlist[0],'^\s*\(\d\+\)\s.*$','\1','')
   else
	if has("gui") && has("gui_running") && has("dialog_gui")
	 let choice= confirm("Select process to attach to: ",'&'.join(pidlist,"\n&"))
	elseif !has("gui_running") && has("dialog_con")
	 let choice= confirm("Select process to attach to: ",'&'.join(pidlist,"\n&"))
	else
	 let mesg= "multiple choices of <".a:gdbattach.">, please enter a pid (:DA pid)")
	 call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
"     call Dret("gdbmgr#GdbMgrAttach")
	 return
	endif
"	call Decho("choice=".choice)
	if 1 <= choice && choice <= len(pidlist)
	 let pid= substitute(pidlist[choice-1],'^\s*\(\d\+\)\s.*$','\1','')
"	 call Decho("pid=".pid)
	else
	 let mesg= "try a choice between 1 and ".len(pidlist)
	 call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
"     call Dret("gdbmgr#GdbMgrAttach")
	 return
	endif
   endif
  endif
  if pid > 0
"   call Decho("attaching to pid#".pid)
   call gdbmgr#GdbMgrCmd("attach ".pid)
   sleep 1
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("attached to ".a:gdbattach." with pid#".pid)
   call gdbmgr#GdbMgrForeground("S")
   call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["S"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
  endif
"  call Dret("gdbmgr#GdbMgrAttach")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrOpenCodedBuf: opens a GdbMgr window/buffer {{{2
"                     Returns  window number if successful at opening a window holding the coded buffer
"                     Returns -buffer number if successful at opening a one-line window on the coded buffer
"                     Returns 0 otherwise
"
"                     As a side effect, this routine pushes a list onto a list (s:codedbuflist):
"                       0= code,
"                       1= current eventignore setting,
"                       2= current window,
"                       3= +: selected window -: one-liner temporary]
"                     This function is expected to be matched with calls to s:GdbMgrCloseCodedBuf()
"
"  Use s:GdbMgrOpenCodedBuf  when one wants to both open a specific coded window/buffer and then
"  use s:GdbMgrCloseCodedBuf to return
"  Use let curcode= s:GetWinCode() to save current window and then
"  use call s:GotoWinCode(curcode) to return to that coded window/buffer
fun! s:GdbMgrOpenCodedBuf(code)
"  call Dfunc("s:GdbMgrOpenCodedBuf(code<".a:code.">) s:codedbuflist".(exists("s:codedbuflist")? string(s:codedbuflist) : '<n/a>'))

  " push information onto s:codedbuflist:
  "    0     1                            2               3
  "   [code, current eventignore setting, current window, +: selected window -: one-liner temporary]
  "            (number of 1st buffer associated with buffer) +bufwinnr()      : -bufwinnr()
  let codebufentry = [a:code,&ei,winnr(),0]
"  call Decho("codebufentry".string(codebufentry))
  if !exists("s:codedbuflist")
   let s:codedbuflist = [codebufentry]
  else
   let s:codedbuflist = s:codedbuflist + [codebufentry]
  endif

  let codebuf= s:gdbmgr_registry_{t:gdbmgrtab}[a:code].bufnum
  if codebuf > 0
   " Found buffer associated with code.
   " Do we change windows or temporarily open a one-line window for it?
"   call Decho("found buffer associated with code<".a:code.">=".codebuf)
   let codewin= bufwinnr(codebuf)
   set ei=all

   if codewin > 0
	" change to requested window which already holds requested buffer
"	call Decho("changing to window#".codewin." which currently holds buf#".codebuf." for <".a:code.">")
	exe codewin."wincmd w"
"	call Decho("check: bufnr(%)=".bufnr("%"))
	let s:codedbuflist[-1][3]= codewin
"	call Dret("s:GdbMgrOpenCodedBuf ".codewin." : s:codebuflist".string(s:codedbuflist)." curline#".line("."))
	return codewin
   else
	" temporarily open a one-line window holding the buffer
"	call Decho("temporarily open a one-line window holding buf#".codebuf."<".codebufentry[0].">")
	1split
	exe "keepa b ".codebuf
	let s:codedbuflist[-1][3]= -codebuf
"	call Dret("s:GdbMgrOpenCodedBuf ".-codebuf." : s:codebuflist".string(s:codedbuflist)." curline#".line("."))
	return -codebuf
   endif

  else
   " the buffer associated with the supplied code has not been initialized
"   call Decho("buffer associated with code<".a:code."> has not been initialized")
   call remove(s:codedbuflist,-1,-1)
   if len(s:codedbuflist) == 0
"	call Decho("removing s:codedbuflist (its empty)")
	unlet s:codedbuflist
   endif
"   call Dret("s:GdbMgrOpenCodedBuf 0 : s:codebuflist".(exists("s:codedbuflist")? string(s:codedbuflist) : '<n/a>')." curline#".line("."))
   return 0
  endif

endfun

" ---------------------------------------------------------------------
" s:GdbMgrCloseCodedBuf: pops the s:codedbuflist stack {{{2
"                        Switches window to the stacked original window
"                        Matching function to s:GdbMgrOpenCodedBuf()
"                        (see s:GdbMgrOpenCodedBuf() for explanation of s:codedbuflist)
fun! s:GdbMgrCloseCodedBuf()
"  call Dfunc("s:GdbMgrCloseCodedBuf() s:codedbuflist".(exists("s:codedbuflist")? string(s:codedbuflist) : '<n/a>'))

  " sanity check
  if !exists("s:codedbuflist")
   echoerr "program error - s:codedbuflist doesn't exist!"
"   call Dret("s:GdbMgrCloseCodedBuf : s:codedbuflist doesn't exist!  (program error)")
   return
  endif

  let codebufentry= s:codedbuflist[-1]
  if codebufentry[3] < 0
   " quit the temporary one-line window
   if exists("t:gdbmgrtab") && exists('s:gdbmgr_registry_{'.t:gdbmgrtab.'}['.bufnr("%").'].code')
    let code= s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code
   else
	let code= "none"
   endif
"   call Decho("quitting temporary one-line window (line#".line(".")." buf#".bufnr('%')." code<".code.">)")
   call s:GdbMgrSavePosn()
"   call Decho("bh<".&bh."> ro=".&ro." bl=".&bl." bt<".&bt.">")
   sil! q
  endif

  " return to the original window
  let origwin= codebufentry[2]
  exe origwin."wincmd w"
  if exists("t:gdbmgrtab") && exists('s:gdbmgr_registry_{'.t:gdbmgrtab.'}['.bufnr("%").'].code')
   let code= s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code
  else
   let code= "none"
  endif
"  call Decho("returned to original window#".origwin." line#".line(".")." buf#".bufnr("%")." code<".code.">")

  " restore ei setting
  let &ei= codebufentry[1]

  " pop the s:codedbuflist entry
  call remove(s:codedbuflist,-1,-1)
"  call Decho("codebufentry".string(codebufentry))
  if len(s:codedbuflist) == 0
   unlet s:codedbuflist
  endif

"  call Dret("s:GdbMgrCloseCodedBuf : s:codebuflist".(exists("s:codebuflist")? string(s:codebuflist) : '<n/a>')." curline#".line("."))
endfun

" ---------------------------------------------------------------------
" s:GetWinCode: return the code associated with the current window {{{2
fun! s:GetWinCode()
"  call Dfunc("s:GetWinCode() win#".winnr()." buf#".bufnr("%"))
  if exists("s:gdbmgr_registry_{t:gdbmgrtab}[".bufnr("%")."].code")
   let wincode= s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code
  else
   let wincode= "n/a"
  endif
"  call Dret("s:GetWinCode <".wincode.">")
  return wincode
endfun

" ---------------------------------------------------------------------
" s:GotoWinCode: bring window bearing code to foreground and set current window to that window {{{2
fun! s:GotoWinCode(code)
"  call Dfunc("s:GotoWinCode(code<".a:code.">)")
  call gdbmgr#GdbMgrForeground(a:code)
"  call Dret("s:GotoWinCode")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrOptionSafe: safe-for-gdbmgr options {{{2
fun! s:GdbMgrOptionSafe()
"  call Dfunc("s:GdbMgrOptionSafe()")

  set magic nowrite
  setlocal cino=
  setlocal com=
  setlocal noacd nocin noai noci nospell noaw ch=2 siso=0 sj=0 notop ead=both nogd nosb nospr magic
  setlocal fo=nroql2
  setlocal tw=0
  setlocal report=10000
  setlocal bh=hide bt=nowrite cul noma noswf ro ve=all

"  call Dret("s:GdbMgrOptionSafe")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrOptionSave: save user options {{{2
fun! s:GdbMgrOptionSave()
"  call Dfunc("s:GdbMgrOptionSave()")
  if exists("s:gdbmgrcnt")
   let s:gdbmgrcnt= s:gdbmgrcnt + 1
  else
   let s:gdbmgrcnt = 1
   let s:keepacd    = &acd
   let s:keepaw     = &aw
   let s:keepch     = &ch
   let s:keepcin    = &cin
   let s:keepci     = &ci
   let s:keepea     = &ea
   let s:keepead    = &ead
   let s:keepgd     = &gd
   let s:keeplz     = &lz
   let s:keepmagic  = &magic
   let s:keepsiso   = &siso
   let s:keepsj     = &sj
   let s:keepsb     = &sb
   let s:keepspr    = &spr
   let s:keepstl    = &stl
   let s:keeptop    = &top
   let s:keeput     = &ut
   let s:keepmagic  = &magic
   let s:keepreport = &report
   let s:keepwrite  = &write
   " save user maps
   call SaveUserMaps("un","","<f1>","GdbMgr")
   call SaveUserMaps("un","","<f6>","GdbMgr")
   call SaveUserMaps("un","","<s-f6>","GdbMgr")
   call SaveUserMaps("un","","<c-f6>","GdbMgr")
   call SaveUserMaps("un","","<cr>","GdbMgr")
   call SaveUserMaps("un","","=","GdbMgr")
   call SaveUserMaps("un","","<c-up>","GdbMgr")
   call SaveUserMaps("un","","<c-down>","GdbMgr")
   call SaveUserMaps("un","","<c-l>","GdbMgr")
   call SaveUserMaps("un","","cfnNsSuU","GdbMgr")
  endif
  set lz noea

"  call Dret("s:GdbMgrOptionSave : gdbmgrcnt=".s:gdbmgrcnt)
endfun

" ---------------------------------------------------------------------
" s:GdbMgrOptionRestore: restore user options {{{2
fun! s:GdbMgrOptionRestore()
"  call Dfunc("s:GdbMgrOptionRestore() s:gdbmgrcnt=".s:gdbmgrcnt)

  " handle options -- restore original options when GdbMgr completely closed
  let s:gdbmgrcnt= s:gdbmgrcnt - 1
  if s:gdbmgrcnt <= 0
   let &acd    = s:keepacd
   let &aw     = s:keepaw
   let &ch     = s:keepch
   let &cin    = s:keepcin
   let &ci     = s:keepci
   let &ea     = s:keepea
   let &ead    = s:keepead
   let &gd     = s:keepgd
   let &lz     = s:keeplz
   let &magic  = s:keepmagic
   let &siso   = s:keepsiso
   let &sj     = s:keepsj
   let &sb     = s:keepsb
   let &spr    = s:keepspr
   let &stl    = s:keepstl
   let &top    = s:keeptop
   let &ut     = s:keeput
   let &magic  = s:keepmagic
   let &report = s:keepreport
   let &write  = s:keepwrite
   unlet s:gdbmgrcnt s:keepaw s:keepea s:keeplz s:keepstl s:keeput s:keepmagic

   " restore user maps
   call RestoreUserMaps("GdbMgr")
  endif

"  call Dret("s:GdbMgrOptionRestore")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrPickSignBase: picks a base for sign-IDs which avoids other signs {{{2
fun! s:GdbMgrPickSignBase()
"  call Dfunc("s:GdbMgrPickSignBase() ".((exists("t:othersigns"))? "t:othersigns exists already" : "build t:othersigns"))
  if !exists("t:othersigns")
   " only do this one time per tab
   redir => t:othersigns
    sign place
   redir END
   let t:gdbmgrsignbase= 3020
   " determine the max id being used and use one more than that as the beginning of the t:gdbmgrsignbase
   let signlist= split(t:othersigns,'\n')
   let idlist  = map(signlist,"substitute(v:val,'^.\\{-}\\<id=\\(\\d\\+\\)\\s.*$','\\1','')")
   if len(idlist) > 2
    let idlist = remove(idlist,2,-1)
    let idlist = map(idlist,"str2nr(v:val)")
    let idmax  = max(idlist)
	if idmax > t:gdbmgrsignbase
	 let t:gdbmgrsignbase = idmax + 1
"	 call Decho("t:gdbmgrsignbase=".t:gdbmgrsignbase)
	endif
   endif
   unlet t:othersigns
   let t:othersigns= 1
  endif
"  call Dret("s:GdbMgrPickSignBase : t:gdbmgrsignbase=".t:gdbmgrsignbase)
endfun

" ---------------------------------------------------------------------
" s:GdbMgrQuit: closes down the connection to gdb.  This suffices for when vim is exiting. {{{2
fun! s:GdbMgrQuit()
"  call Dfunc("s:GdbMgrQuit()")
  if exists("#GdbMgrAutocmds")
   augroup GdbMgrAutocmds
    au!
   augroup END
   augroup! GdbMgrAutocmds
  endif
  if exists("#CmdPollAutocmds")
   augroup CmdPollAutocmds
    au!
   augroup END
   augroup! CmdPollAutocmds
  endif
"  call Decho("removed GdbMgrAutocmds")
"  call Decho("using gmClose on all tabs with t:gdbmgr defined")
  tabdo if exists("t:gdbmgr")|call s:GdbMgrSend(26,"gmClose","quit")|unlet t:gdbmgr|endif
"  call Dret("s:GdbMgrQuit")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrResize: resize windows {{{2
fun! s:GdbMgrResize()
"  call Dfunc("s:GdbMgrResize() w#".winnr()." lines=".&lines." columns=".&columns)

  " sanity checks
  if !exists("t:gdbmgrtab")
"   call Dret("s:GdbMgrResize : not a GdbMgr tab")
   return
  endif
  if !exists("w:gdbmgr{t:gdbmgrtab}_isrfixed")
"   call Dret("s:GdbMgrResize : w:gdbmgr".t:gdbmgrtab."_isrfixed doesn't exist, skipping")
   return
  endif
  if !exists("w:gdbmgr{t:gdbmgrtab}_isifixed")
"   call Dret("s:GdbMgrResize : w:gdbmgr".t:gdbmgrtab."_isifixed doesn't exist, skipping")
   return
  endif

"  call Decho("resize:     ofix ocol qwoc ifix icol qwic rfix rows qwrows")
"  call Decho("resize: w#".winnr().
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isofixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isofixed)     : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedocols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedocols)   : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildocols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildocols) : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isifixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isifixed)     : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedicols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedicols)   : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildicols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildicols) : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isrfixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isrfixed)     : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedrows")?    printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedrows)    : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildrows")?  printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildrows)  : '---').
	  \ "  ".expand("%"))

  " rows: determine window height
  if w:gdbmgr{t:gdbmgrtab}_isrfixed <= 0
   let rows= (&lines - w:gdbmgr{t:gdbmgrtab}_fixedrows)/w:gdbmgr{t:gdbmgrtab}_qtywildrows
"   call Decho("rows =".rows." (wildcard)")
  else
   let rows= w:gdbmgr{t:gdbmgrtab}_isrfixed
"   call Decho("rows =".rows." (fixed)")
  endif
  if rows <= 0
   let rows= 1
  endif
"  call Decho("rows =".rows)

  " columns: determine outer-column width
  if !exists("w:gdbmgr{t:gdbmgrtab}_isofixed")
   let w:gdbmgr{t:gdbmgrtab}_isofixed= 0
  endif
  if !exists("w:gdbmgr{t:gdbmgrtab}_fixedocols")
   let w:gdbmgr{t:gdbmgrtab}_fixedocols= 0
  endif
  if !exists("w:gdbmgr{t:gdbmgrtab}_qtywildocols")
   let w:gdbmgr{t:gdbmgrtab}_qtywildocols= 1
  endif
  if w:gdbmgr{t:gdbmgrtab}_isofixed <= 0
   let ocols= (&columns - w:gdbmgr{t:gdbmgrtab}_fixedocols)/w:gdbmgr{t:gdbmgrtab}_qtywildocols
"   call Decho("ocols=".ocols." (outercols wildcard)")
  else
   let ocols= w:gdbmgr{t:gdbmgrtab}_isofixed
"   call Decho("ocols=".ocols." (outercols fixed)")
  endif
  if ocols <= 0
   let ocols= 1
  endif
"  call Decho("ocols=".ocols)

  " columns: determine inner-column width
  if w:gdbmgr{t:gdbmgrtab}_isifixed <= 0
   let icols= (ocols - w:gdbmgr{t:gdbmgrtab}_fixedicols)/w:gdbmgr{t:gdbmgrtab}_qtywildicols
"   call Decho("icols=".icols." (innercols wildcard)")
  else
   let icols= w:gdbmgr{t:gdbmgrtab}_isifixed
"   call Decho("icols=".icols." (innercols fixed)")
  endif
  if icols <= 0
   let icols= 1
  endif
"  call Decho("icols=".icols)

  " resize the window
  exe "res ".rows
  exe "vert res ".icols

"  call Dret("s:GdbMgrResize : ".rows."x".icols)
endfun

" ---------------------------------------------------------------------
" s:GdbMgrRunUpdate: updates GdbMgr tab with results of run {{{2
fun! s:GdbMgrRunUpdate(mesg)
"  call Dfunc("s:GdbMgrRunUpdate(mesg<".a:mesg.">)")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:GdbMgrRunUpdate : gdbmgr never initialized")
   return
  endif

  if a:mesg =~ '\<Breakpoint\>'
   " regular breakpoint encountered
"   call Decho("regular breakpoint encountered")
   call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
   let brknum  = substitute(a:mesg,'^.*Breakpoint \(\d\+\),.*$','\1','')
   let brkfile = substitute(a:mesg,'^.*Breakpoint.* at \(\S\+\):\(\d\+\)\n.*$','\1','')
   let brkline = substitute(a:mesg,'^.*Breakpoint.* at \(\S\+\):\(\d\+\)\n.*$','\2','')
"   call Decho("brknum#".brknum." brk<".brkfile.":".brkline.">")
   call s:SourceFastUpdate(brkfile,brkline)
   call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()

  elseif a:mesg =~ '\<Program exited\>'
   " Program terminated
"   call Decho("program exited")
   call s:SourceFastUpdate()
   call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(a:mesg)

  elseif a:mesg =~ ') at \S\+:\d\+\n$'
   " temporary break encountered
"   call Decho("temporary breakpoint encountered")
   call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
   let stopfile = substitute(a:mesg,'^.*) at \(\S\+\):\(\d\+\)\n$','\1','')
   let stopline = substitute(a:mesg,'^.*) at \(\S\+\):\(\d\+\)\n$','\2','')
   call s:SourceFastUpdate(stopfile,stopline)
   call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()

  elseif s:gdbmgr{t:gdbmgrtab}_running == "R"
   " running mode
"   call Decho("starting")
   sil call s:CmdPoll(a:mesg)

  else
   " I don't understand the message, so ask using "info line"
"   call Decho("GdbMgrRunUpdate doesn't understand<".a:mesg.">")
   call s:SourceFastUpdate()
   call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
  endif

"  call Dret("s:GdbMgrRunUpdate")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrSend: sends a string to the function specified by a:tgtfunc in the gdbmgr library {{{2
fun! s:GdbMgrSend(id,tgtfunc,...)
"  call Dfunc("s:GdbMgrSend(id=".a:id." tgtfunc<".a:tgtfunc.">,...) a:0=".a:0)

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   "   call Dret("s:GdbMgrSend : gdbmgr never initialized")
   return
  endif

  " sanity check
  if exists("s:gdbmgr".t:gdbmgrtab."_running")
   if s:gdbmgr{t:gdbmgrtab}_running == "R" && a:tgtfunc == "gmGdb"
	" sorry, can't send gmGdb commands when user-program is running
"	call Decho("PROBLEM: running<".s:gdbmgr{t:gdbmgrtab}_running."> tgtfunc<".a:tgtfunc.">")
   elseif s:gdbmgr{t:gdbmgrtab}_running == "S" && a:tgtfunc == "gmPoll"
	" sorry, can't send gmPoll commands when user-program is stopped
"	call Decho("PROBLEM: running<".s:gdbmgr{t:gdbmgrtab}_running."> tgtfunc<".a:tgtfunc.">")
   endif
  endif

  " send the argument string(s)
  if a:0 > 0
   if a:1 == "-empty-string-"
"	call Decho("sendstring<> (force emtpy-string)")
    let response = libcall("gdbmgr.so",a:tgtfunc,"")
   elseif a:1 != ""
"    call Decho("sendstring<".a:1.">")
    let response = libcall("gdbmgr.so",a:tgtfunc,a:1)
   else
"    call Dret("s:GdbMgrSend : gdbmgr refusing to send empty string")
    return
   endif
 
  " initialize GdbMgr
  elseif a:tgtfunc == "gmInit"
"   call Decho("initializing GdbMgr: libcall'ing gdbmgr.so<".a:tgtfunc.">")
   let response = libcall("gdbmgr.so",a:tgtfunc," ")
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(response)
 
  else
   " just call the target function (gmGdb or gmPoll, typically)
   let response = libcall("gdbmgr.so",a:tgtfunc,"")
  endif

  " if tgtfunc is gmGdb, then the first byte is S==stopped R=running Q=query C=commands
  if a:tgtfunc == "gmGdb" || a:tgtfunc == "gmPoll"
   let s:gdbmgr{t:gdbmgrtab}_running = strpart(response,0,1)
   let response                      = strpart(response,1,strlen(response)-1)
"   call Decho("tgtfunc<".a:tgtfunc."> running<".s:gdbmgr{t:gdbmgrtab}_running.">=".((s:gdbmgr{t:gdbmgrtab}_running == "R")? "running" : (s:gdbmgr{t:gdbmgrtab}_running == "Q")? "query" : "stopped"))
  else
   let s:gdbmgr{t:gdbmgrtab}_running = "S"
  endif

  " D commands ... D p something ... D end results in a number of $# = ... responses */
"  call Decho("response<".response.'> =~ ^\$\d? '.(response =~ '^\$\d'))
  " COMBAK: the following while loop is responsible for hanging gdbmgr up when processing core dumps,
  " Expressions, etc.  I need to target it at D commands only!
"   while response =~ '^\$\d'
"    call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(response)
"    let response = libcall("gdbmgr.so",a:tgtfunc,"")
"    " if tgtfunc is gmGdb, then the first byte is S==stopped R=running Q=query C=commands
"    if a:tgtfunc == "gmGdb" || a:tgtfunc == "gmPoll"
"     let s:gdbmgr{t:gdbmgrtab}_running = strpart(response,0,1)
"     let response                      = strpart(response,1,strlen(response)-1)
"    call Decho("tgtfunc<".a:tgtfunc."> running<".s:gdbmgr{t:gdbmgrtab}_running.">=".((s:gdbmgr{t:gdbmgrtab}_running == "R")? "running" : (s:gdbmgr{t:gdbmgrtab}_running == "Q")? "query" : "stopped"))
"    else
"     let s:gdbmgr{t:gdbmgrtab}_running = "S"
"    endif
"   endwhile

  let CZ= "\x1a"
  if response =~ "^".CZ.CZ."empty$"
   let response= ""
  endif

"  call Dret("s:GdbMgrSend <".response."> : running<".s:gdbmgr{t:gdbmgrtab}_running.">")
  return response
endfun

" ---------------------------------------------------------------------
" s:GdbMgrSetupGotoMaps: set up the go-to-coded-window maps {{{2
fun! s:GdbMgrSetupGotoMaps()
"  call Dfunc("s:GdbMgrSetupGotoMaps()")

  nno <silent>  CA	:call gdbmgr#GdbMgrUserGoto("A")<cr>
  nno <silent>  CB	:call gdbmgr#GdbMgrUserGoto("B")<cr>
  nno <silent>  CH	:call gdbmgr#GdbMgrUserGoto("H")<cr>
  nno <silent>  CC	:call gdbmgr#GdbMgrUserGoto("C")<cr>
  nno <silent>  CE	:call gdbmgr#GdbMgrUserGoto("E")<cr>
  nno <silent>  CF	:call gdbmgr#GdbMgrUserGoto("F")<cr>
  nno <silent>  CM	:call gdbmgr#GdbMgrUserGoto("M")<cr>
  nno <silent>  CN	:call gdbmgr#GdbMgrUserGoto("N")<cr>
  nno <silent>  CS	:call gdbmgr#GdbMgrUserGoto("S")<cr>
  nno <silent>  CW	:call gdbmgr#GdbMgrUserGoto("W")<cr>
"  call Dret("s:GdbMgrSetupGotoMaps")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrStep: supports [cnNsSu] maps {{{2
fun! s:GdbMgrStep(cmdmesg)
"  call Dfunc("s:GdbMgrStep(cmdmesg<".a:cmdmesg.">)")

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("s:GdbMgrStep : gdbmgr never initialized")
   return
  endif
  let CZ= "\x1a"

  if a:cmdmesg == "" || a:cmdmesg =~ ') at \S\+:\d\+\n' || a:cmdmesg =~ CZ.CZ."stopped"
   call gdbmgr#GdbMgrForeground("S")
   call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["E"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["S"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
  elseif a:cmdmesg =~ '^Continuing.'
   call s:CmdPoll("step-continue")
"   call Dret("s:GdbMgrStep : continuing")
   return
  elseif a:cmdmesg == "starting"
   call s:CmdPoll("step-start")
"   call Dret("s:GdbMgrStep : starting")
   return
  elseif a:cmdmesg =~ "The program is not being run."
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** Please use :DR to start program")
  elseif a:cmdmesg =~ "gdb not responding as expected" || a:cmdmesg =~ "not meaningful  in the outermost"
"   call Dret("s:GdbMgrStep : ".a:cmdmesg)
   return
  elseif a:cmdmesg =~ ""
"   call Dret("s:GdbMgrStep : <".a:cmdmesg.">")
   return
  else
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("(s:GdbMgrStep) needs to be extended to handle cmdmesg<".a:cmdmesg.">")
"   call Decho("(s:GdbMgrStep) needs to be extended to handle cmdmesg<".a:cmdmesg.">")
  endif

"  call Dret("s:GdbMgrStep")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrUpdate: runs updates with arguments as needed by the given code {{{2
"                 Called by gdbmgr#GdbMgrStack()
fun! s:GdbMgrUpdate(code)
"  call Dfunc("s:GdbMgrUpdate(code<".a:code.">)")
  if !exists("s:gdbmgr_registry_{t:gdbmgrtab}['".a:code."'].bufnum")
"   call Dret("s:GdbMgrUpdate")
   return
  endif
  if a:code =~ '[bht]'
   if exists("s:gdbmgr_registry_{t:gdbmgrtab}['S'].bufnum")
    call s:gdbmgr_registry_{t:gdbmgrtab}[a:code].Update(s:gdbmgr_registry_{t:gdbmgrtab}['S'].bufnum)
   endif
  elseif a:code !~ '[CM]'
   " message window "updates" just put text into the window.  No message given here, so no update needed.
   " command window updates interact closely with gdb/polling etc
   call s:gdbmgr_registry_{t:gdbmgrtab}[a:code].Update()
  endif
"  call Dret("s:GdbMgrUpdate")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrVimResized: called when the vim window is resized {{{2
fun! s:GdbMgrVimResized()
"  call Dfunc("s:GdbMgrVimResized()")

  windo call s:GdbMgrResize()

  if s:GdbMgrOpenCodedBuf("S") == 0
"   call Dret("s:GdbMgrVimResized : no source buffer!")
   return
  endif
  if exists("t:srcline") && exists("t:srcfile")
   call setpos('.',[bufnr('%'),t:srcline,1,0])
   norm! z.
  endif
  call s:GdbMgrCloseCodedBuf()
  call s:GotoWinCode("S")
  call s:GdbMgrMenu()

"  call Dret("s:GdbMgrVimResized")
endfun

" ---------------------------------------------------------------------
" s:GdbMgrSavePosn: save buffer position when leaving buffer {{{2
"  Problem found with temporary one-line windows; doing sil! q caused
"  the line in that buffer to be forgotten.
fun! s:GdbMgrSavePosn()
  if exists("t:gdbmgrtab")
   let s:bufsp{t:gdbmgrtab}_{bufnr("%")}= SaveWinPosn()
  endif
endfun

" ---------------------------------------------------------------------
" s:GdbMgrRestorePosn: {{{2
fun! s:GdbMgrRestorePosn()
  if exists("t:gdbmgrtab") && exists("s:bufsp".t:gdbmgrtab."_".bufnr("%"))
   call RestoreWinPosn(s:bufsp{t:gdbmgrtab}_{bufnr("%")})
   unlet s:bufsp{t:gdbmgrtab}_{bufnr("%")}
  endif
endfun

" ---------------------------------------------------------------------
" gdbmgr#BufSwitch: buffer local <c-F6> switches buffers with this function {{{2
"                    The .code and .nxt members are set up by s:WinCtrl()
fun! gdbmgr#BufSwitch()
"  call Dfunc("gdbmgr#BufSwitch() buf#".bufnr("%")." win#".winnr())

  " sanity checks
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("gdbmgr#BufSwitch : gdbmgr never initialized")
   return
  endif
  if !exists("s:gdbmgr_registry_{t:gdbmgrtab}[bufnr('%')]")
"   call Decho("bufname(bufnr('%')=".bufnr('%').")<".bufname(bufnr('%')).">")
"   call Dret("gdbmgr#BufSwitch : s:gdbmgr_registry_".t:gdbmgrtab."[".bufnr('%')."] doesn't exist!")
   return
  endif

  let code   = s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code
  let nxtcode= s:gdbmgr_registry_{t:gdbmgrtab}[code].nxt

"  call Decho("code   <".code."> buf#".bufnr("%")." line#".line("."))
"  call Decho("nxtcode<".nxtcode.">")

  if code == nxtcode
   " no change -- only one code sharing this window
"   call Dret("gdbmgr#BufSwitch : no change  (only one code sharing win#".winnr().")")
   return
  endif

"  call s:ShowRegistry()  " Decho

  " disable any BufWinLeave events
  let eikeep= &l:ei
  setlocal ei+=BufWinLeave

"  call Decho("editing buffer s:gdbmgr_registry_".t:gdbmgrtab."[".nxtcode."].bufnum=".s:gdbmgr_registry_{t:gdbmgrtab}[nxtcode].bufnum)
  exe "keepa b ".s:gdbmgr_registry_{t:gdbmgrtab}[nxtcode].bufnum
"  call Decho("1st check: buf#".bufnr("%")." in win#".bufwinnr(bufnr("%"))." line#".line("."))

  " restore ei
"  call Decho("restoring l:ei=".eikeep)
  let l:ei= eikeep
"  call Decho("2nd check: buf#".bufnr("%")." in win#".bufwinnr(bufnr("%"))." line#".line("."))

  if exists("s:foreigncodes_{tabpagenr()}") && index(s:foreigncodes_{tabpagenr()},nxtcode) >= 0
"   call Decho("updating foreign code<".nxtcode.">  srcbuf#".s:gdbmgr_registry_{t:gdbmgrtab}['S'].bufnum)
   sil call s:gdbmgr_registry_{t:gdbmgrtab}[nxtcode].Update(s:gdbmgr_registry_{t:gdbmgrtab}['S'].bufnum)
  endif
  redraw
"  call Decho('(BufSwitch) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
  nn <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
"  call Dret("gdbmgr#BufSwitch : showing code<".nxtcode.">'s buf#".bufnr("%")." win#".winnr()." line#".line("."))
endfun

" ---------------------------------------------------------------------
" gdbmgr#Register: register a window-display code {{{2
"    Also see s:WinCtrl() for how it sets up the registry based on window display codes
"
"   Every tab has a
"     t:gdbmgrtab  : an integer counting the qty of GdbMgr tab displays
"                    Done this way because t:gdbmgrtab is associated with the tab,
"                    but the tab-number (tabpagenr()) may change as (other) tabs are
"                    inserted and/or deleted.
"
"   The GdbMgr Registry:
"     s:gdbmgr_registry_{t:gdbmgrtab}[code].bufnum    : maps code to buffer number
"     s:gdbmgr_registry_{t:gdbmgrtab}[code].Init()    : maps code to associated initialization function
"     s:gdbmgr_registry_{t:gdbmgrtab}[code].Update()  : maps code to associated update         function
"     s:gdbmgr_registry_{t:gdbmgrtab}[code].nxt       : next     code sharing this window
"     s:gdbmgr_registry_{t:gdbmgrtab}[code].prv       : previous code sharing this window
"     s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code: maps buffer number to code
"
"    Window Display Codes:
"     CODE  WINDOW
"      A    Assembly window
"      B    Breakpoint window
"      C    Command window
"      E    Expression window
"      F    Function stack window
"      H    Checkpoint window
"      M    Messages window
"      S    Source code window
"      T	Thread window
"      W    Watchpoint window
"
"      Note for future codes: r and c are reserved to mean row specification and column specification
fun! gdbmgr#Register(code,init,update)
"  call Dfunc("gdbmgr#Register(code<".a:code."> init<".a:init."> update<".a:update.">)")
  call s:FindGdbMgrTab()
  if !exists("s:gdbmgr_registry_{t:gdbmgrtab}")
   let s:gdbmgr_registry_{t:gdbmgrtab}= {}
  endif
  let s:gdbmgr_registry_{t:gdbmgrtab}[a:code]        = {}
  let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].bufnum = 0
  let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt    = ' '
  let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].prv    = ' '
  let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].Init   = function(a:init)
  let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].Update = function(a:update)
"  call Decho("gdbmgr_registry_".t:gdbmgrtab."[".a:code."]=".string(s:gdbmgr_registry_{t:gdbmgrtab}))
"  call Dret("gdbmgr#Register")
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrClose: closes down the gdb connection and all windows and associated buffers *except* for the source window {{{2
fun! gdbmgr#GdbMgrClose()
"  call Dfunc("gdbmgr#GdbMgrClose()")

  if exists("t:gdbmgrtab")
   let gdbmgrtab = t:gdbmgrtab
   let srcbuf    = s:gdbmgr_registry_{t:gdbmgrtab}["S"].bufnum
   let s:buflist = []
   windo call s:GdbMgrBuildBufList()
"   call Decho("buflist".string(s:buflist))
   for bufnum in s:buflist
    setlocal ma
    exe "keepa ".bufnum."bw"
   endfor

   call s:GdbMgrQuit()

   " remove any previously placed signs
   if exists("t:signidlist")
    " remove gdbmgr's signs no matter what buffer/file they're in
"    call Decho("remove all breakpoint signs")
    for id in t:signidlist
     exe "sign unplace ".id
    endfor
    unlet t:signidlist
   endif

   if exists("s:buflist")                    |unlet s:buflist                    |endif
   if exists("s:gdbmgr_registry_{gdbmgrtab}")|unlet s:gdbmgr_registry_{gdbmgrtab}|endif
   if exists("t:breakptdict")                |unlet t:breakptdict                |endif
   if exists("t:othersigns")                 |unlet t:othersigns                 |endif
   if exists("s:gdbmgr{t:gdbmgrtab}_running")|unlet s:gdbmgr{t:gdbmgrtab}_running|endif
   if exists("t:signidlist")                 |unlet t:signidlist                 |endif
   if exists("t:srcbuf")                     |unlet t:srcbuf                     |endif
   if exists("t:srcfile")                    |unlet t:srcfile                    |endif
   if exists("t:gdbmgrsignbase")             |unlet t:gdbmgrsignbase             |endif
   if exists("t:gdbmgrtab")                  |unlet t:gdbmgrtab                  |endif
   if exists("t:gdbmgr_srcpath")             |unlet t:gdbmgr_srcpath             |endif
   if exists("g:netrw_corehandler")          |unlet g:netrw_corehandler          |endif
   if exists("g:Netrw_funcref")              |unlet g:Netrw_funcref              |endif

   call s:GdbMgrOptionRestore()
  endif

"  call Dret("gdbmgr#GdbMgrClose")
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrCmd: executes a gdb command {{{2
"      Supports  :D gdbcmd --args--
"      Also supports indirect calls such as :DR --args--
fun! gdbmgr#GdbMgrCmd(gdbcmd,...)
"  call Dfunc("gdbmgr#GdbMgrCmd(gdbcmd<".a:gdbcmd.">) a:0=".a:0." win#".winnr())
  let gdbcmd= a:gdbcmd

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   redraw|echomsg "***error*** gdbmgr has never been initialized!"
   echohl None
"   call Dret("gdbmgr#GdbMgrCmd")
   return
  endif

  " record current window
  let curwin= winnr()
"  call Decho("curwin#".curwin)

  " pre-gdb command handling
"  call Decho("pre-gdb command handling")
  if gdbcmd =~ '^\s*watch\s'
   call s:WatchpointPost(gdbcmd)
  elseif gdbcmd =~# '^\s*run\s'
   call gdbmgr#GdbMgrRun(gdbcmd,0)
  elseif gdbcmd =~# '^\s*kill\>'
   call s:GdbMgrKill()
  elseif gdbcmd =~# '^\s*[cnsu]'
   call gdbmgr#GdbMgrForeground("C")
  elseif gdbcmd =~# '^\s*where'
   call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
   exe curwin."wincmd w"
"   call Dret("gdbmgr#GdbMgrCmd")
   return
  endif

  " perform gdb command
"  call Decho("perform gdb<".gdbcmd."> command")
  let mesg= s:GdbMgrSend(27,"gmGdb",gdbcmd)
  call s:gdbmgr_registry_{t:gdbmgrtab}["C"].Update(gdbcmd)

  " handle queries
  if s:gdbmgr{t:gdbmgrtab}_running == "Q"
"   call Decho("handle queries  (s:gdbmgr".t:gdbmgrtab."_running<".s:gdbmgr{t:gdbmgrtab}_running.">)")
   if exists("mesg") && mesg != ""
    call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
   endif
   exe curwin."wincmd w"
"   call Dret("gdbmgr#GdbMgrCmd")
   return
  endif

  if a:0 == 0 || a:1 != 0
   " if gdbmgr#GdbMgrCmd(gdbcmd,0) is called, then this message won't be issued
   if exists("mesg") && mesg != ""
    call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
   endif
  endif

  " post-gdb command handling
"  call Decho("post-gdb<".gdbcmd."> command handling")
  if mesg =~ "Program exited normally"
   if has("signs")
	call s:NormalTermination()
   endif
  elseif gdbcmd =~ '^\s*file\>'
   call gdbmgr#GdbMgrSourceInitFile()
   syn on
  elseif gdbcmd =~ '^\s*b\s'
   call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
  elseif gdbcmd =~ '^\s*clear\s\='
   call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
  elseif gdbcmd =~ '^\s*tbreak\s'
   call s:gdbmgr_registry_{t:gdbmgrtab}["B"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["W"].Update()
  elseif gdbcmd =~ '^\s*run\>'
   call s:GdbMgrRunUpdate(mesg)
  elseif gdbcmd =~ '^\s*c\>'
   call s:CmdPoll("c")
  elseif gdbcmd =~ '^\s*[nNsSuU]\>'
   call s:GdbMgrStep(mesg)
  elseif gdbcmd =~ '^\s*[sn]i\>'
   call s:GdbMgrStep(mesg)
   call s:gdbmgr_registry_{t:gdbmgrtab}["A"].Update()
  elseif gdbcmd =~ '^\s*finish'
   call s:GdbMgrStep(mesg)
   call s:CmdPoll("finish")
  elseif gdbcmd =~ '^\s*core\s' || gdbcmd =~ '^\s*target\s\+core\s\+core'
   call gdbmgr#GdbMgrSourceInitFile()
   call s:gdbmgr_registry_{t:gdbmgrtab}["F"].Update()
   call s:gdbmgr_registry_{t:gdbmgrtab}["T"].Update()
  endif
  exe curwin."wincmd w"
"  call Dret("gdbmgr#GdbMgrCmd")
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrForeground: brings the specified code's buffer to the foreground {{{2
"                          and sets current window to hold that coded buffer.
"                          Returns the previous code associated with that window,
"                          which may, of course, be the same as the requested code.
fun! gdbmgr#GdbMgrForeground(code)
"  call Dfunc("gdbmgr#GdbMgrForeground(code<".a:code.">)")

  " sanity checks
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("gdbmgr#GdbMgrForeground : gdbmgr not initialized yet")
   return
  endif
"  call Decho("sanity check passed: t:gdbmgrtab initialized (to ".t:gdbmgrtab.")")
  if !exists("s:gdbmgr_registry_{t:gdbmgrtab}[a:code]")
"   call Decho("s:gdbmgr_registry_".t:gdbmgrtab."[".a:code."] doesn't exist!")
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** attempted to bring never-initialized code<".a:code."> to foreground")
"   call Dret("gdbmgr#GdbMgrForeground <".a:code."> : code<".a:code."> not available")
   return a:code
  endif
"  call Decho("sanity check passed: s:gdbmgr_registry_".t:gdbmgrtab."[".a:code."] exists")

  " get the buffer and window numbers associated with the desired code
  let bufcode = s:gdbmgr_registry_{t:gdbmgrtab}[a:code].bufnum
  if bufcode <= 0
"   call Decho("s:gdbmgr_registry_".t:gdbmgrtab."[".a:code."] not initialized")
   call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** attempted to bring never-initialized code<".a:code."> to foreground")
"   call Dret("gdbmgr#GdbMgrForeground <".a:code."> : code<".a:code."> not available")
   return a:code
  endif
"  call Decho("sanity check passed: s:gdbmgr_registry_".t:gdbmgrtab."[".a:code."].bufnum initialized to ".bufcode)
  let wincode = bufwinnr(bufcode)
"  call Decho("put code<".a:code.">'s buf#".bufcode."<".bufname(bufcode)."> in the foreground: wincode#".wincode)

  " is the window/buffer already showing?  If so, make sure its the active window.
  if wincode > 0
   exe wincode."wincmd w"
"   call Dret("gdbmgr#GdbMgrForeground <".a:code."> : code<".a:code."> already in foreground")
   return a:code
  endif
"  call Decho("code<".a:code.">'s buf#".bufcode." win#".wincode.": currently not in foreground")

  " find the buffer which is in foreground but shares the window with the desired coded-buffer
"  call Decho("find buffer in foreground sharing window with desired code<".a:code.">")
  let fgcode = s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt
  
  while fgcode != a:code
   let fgbuf = s:gdbmgr_registry_{t:gdbmgrtab}[fgcode].bufnum
   let fgwin = bufwinnr(fgbuf)
"   call Decho("(GdbMgrForeground while-loop) fgcode<".fgcode."> fgbuf#".fgbuf." fgwin#".fgwin)
   if fgwin > 0
    " switch to window associated with desired new code
    exe fgwin."wincmd w"
    " get the current code using that window
    let prvcode= s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code
    " switch to new code's buffer
    exe "keepa b ".bufcode
"	call Decho('(GdbMgrForeground while-loop) setting <c-f6> to call gdbmgr#BufSwitch() in buf#%'.bufnr("%"))
	nn <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
"    call Dret("gdbmgr#GdbMgrForeground <".prvcode."> (returning previous code)")
    return prvcode
   endif
   let fgcode = s:gdbmgr_registry_{t:gdbmgrtab}[fgcode].nxt
  endwhile

"  call Decho("sanity check fail: unable to find desired coded buffer (".a:code.")")
  call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***warning*** attempted to bring never-initialized code<".a:code."> to foreground")

"  call Dret("gdbmgr#GdbMgrForeground <".a:code.">")
  return a:code
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrUserGoto: goto a coded buffer/window if available, otherwise give directions {{{2
fun! gdbmgr#GdbMgrUserGoto(code)
"  call Dfunc("gdbmgr#GdbMgrUserGoto(code<".a:code.">)")
  if exists("s:gdbmgr_registry_{t:gdbmgrtab}['".a:code."']")
"   call Decho("s:gdbmgr_registry_".t:gdbmgrtab."[".a:code."] exists")
   if exists("s:gdbmgr_registry_{t:gdbmgrtab}['".a:code."'].bufnum") && s:gdbmgr_registry_{t:gdbmgrtab}[a:code].bufnum > 0
"	call Decho("s:gdbmgr_registry_".t:gdbmgrtab."[".a:code."].bufnum=".s:gdbmgr_registry_{t:gdbmgrtab}[a:code].bufnum)
    call gdbmgr#GdbMgrForeground(a:code)
"    call Dret("gdbmgr#GdbMgrUserGoto")
	return
   endif
  endif
  call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update("***note*** choose a window and use :Dstack ".a:code)
"  call Dret("gdbmgr#GdbMgrUserGoto")
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrInitEnew: does enew to create a new coded buffer, but prevents a CheckSrcChg on it {{{2
fun! gdbmgr#GdbMgrInitEnew()
"  call Dfunc("gdbmgr#GdbMgrInitEnew()")
  let s:bypassCheckSrcChg= 1|sil! enew|let s:bypassCheckSrcChg= 0
"  call Dret("gdbmgr#GdbMgrInitEnew")
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrInit: transform current tab into a GdbMgrTab, start gdb, and communications with gdb {{{2
fun! gdbmgr#GdbMgrInit(...)
"  call Dfunc("gdbmgr#GdbMgrInit() a:0=".a:0)

  " sanity check -- GdbMgr has already been initialized
  if exists("t:gdbmgrtab")
"   call Dret("gdbmgr#GdbMgrInit : already initialized")
   return
  endif

  echo "gdbmgr init [*        ]: installing commands and maps"

  " set up additional gdbmgr commands
  com  -nargs=+   				D			call gdbmgr#GdbMgrCmd(<q-args>)
  com  -nargs=0					DC			call gdbmgr#GdbMgrSourceInitFile()
  com  -nargs=?	-complete=file	DF			call gdbmgr#GdbMgrCmd("file ".<q-args>)
  com  -nargs=0					DK			call gdbmgr#GdbMgrCmd("kill")
  com  -nargs=* -complete=file	DR  		call gdbmgr#GdbMgrRun(<q-args>)
  com  -nargs=0					DQ			call gdbmgr#GdbMgrClose()
  com  -nargs=1					Dstack		call gdbmgr#GdbMgrStack(<q-args>)
  com  -nargs=0					Dunstack	call gdbmgr#GdbMgrUnstack()
"  com  -nargs=0					Dreg		call gdbmgr#ShowRegistry()	" Decho

  " set up the go-to-coded-window maps
  call s:GdbMgrSetupGotoMaps()

  " save user's options and maps
  call s:GdbMgrOptionSave()
  if a:0 > 0
   let curfile= expand(a:1)
  else
   let curfile= expand("%")
  endif

  " install buffer enter/leave autocmds
  au BufEnter * call s:GdbMgrRestorePosn()

  " examine the command line arguments, if any
  " Allows initializations:  :DI                  :DI winctrl
  "                          :DI pgmname          :DI winctrl pgmname
  "                          :DI pgmname core...  :DI winctrl pgmname core...
  if curfile != '--attaching--'
"   call Decho("initialization: is curfile<".curfile."> executable? ------------------")
   if executable(substitute(curfile,'\.[^.]\+$','','')) && !isdirectory(curfile)
    " if current file, less its suffix, is executable, assume that the "curfile" is the program to be debugged
"    call Decho("case: curfile<".curfile."> is executable")
    let gdbcmd= substitute(curfile,'\.[^.]\+$','','')
"    call Decho("curfile<".curfile."> is executable, assuming its the pgm to be debugged")
   else
"    call Decho("case: curfile<".curfile."> is not executable")
    let curfiles = split(glob("*"),"\n")
    for curfile in curfiles
" 	call Decho("considering<".curfile.">")
 	if executable(curfile)
 	 let gdbcmd= curfile
" 	 call Decho("gdbcmd<".gdbcmd."> (found executable)")
 	 break
 	endif
    endfor
    if !exists("gdbcmd")
     echohl WarningMsg
 	echomsg "***warning*** no executable found"
     echohl None
"     call Decho("curfile<".curfile."> is not executable")
    endif
   endif
  endif

  " default window control list
  let gdbmgr_winctrl= [['c25','r-,N-'],['c-','r5,M-,F-','r-,SC-','r5,E-,B-,W-']]

  " user overrides to winctrl
"  call Decho("user overrides to winctrl---------------------------------------------")
  if exists("g:gdbmgr_winctrl")
   " user has specified a default window control list -- use it
   let gdbmgr_winctrl= g:gdbmgr_winctrl
  elseif exists("g:gdbmgr_stdwinctrl")
   if     g:gdbmgr_stdwinctrl == 1
    let gdbmgr_winctrl= [["c25","r-,N-"],["c-","r5,M-,F-","r-,S-,C-","r5,E-,B-,W-"]]
   elseif g:gdbmgr_stdwinctrl == 2
	let gdbmgr_winctrl= [["c-","r-,SC-"],["c40","r-,M-","r-,F-","r-,B-","r-,E-","r-,W-","r-,N-"]]
   endif
  endif
"  call Decho("gdbmgr_winctrl<".string(gdbmgr_winctrl).">")

"  call Decho("begin while loop for explicit settings -------------------------------")
  let i= 1
  while i <= a:0
   if executable(a:{i})
	" user is explicitly setting the program name to be debugged
"	call Decho("user explicitly setting pgmname")
	let gdbcmd= a:{i}
   elseif type(a:{i}) == 3
	" user is explicitly setting the window control string
"	call Decho("user explicitly setting winctrl string")
	let gdbmgr_winctrl= a:{i}
   elseif a:{i} =~ '^core' && exists("gdbcmd") && gdbcmd != ""
	" user wants to debug the program with a pre-existing core dump
"	call Decho("user wants to debug a core dump")
	let coredump= a:{i}
   endif
   let i= i + 1
  endwhile

  " handle optional core file if provided as second argument via arglist
  if argc() >= 2 && argv(argc()-1) =~ '^core.*'
	let coredump= argv(argc()-1)
  endif

"  call Decho("gdbmgr_winctrl".string(gdbmgr_winctrl)." gdbcmd<".(exists("gdbcmd")? gdbcmd : '--n/a--')."> coredump<".(exists("coredump")? coredump : "").">")

  " initialize the GdbMgr display, register functions, etc
  echo "gdbmgr init [**       ]: display, registry"
"  call Decho("initialize GdbMgr display, register functions, etc -------------------")
  if !exists("t:gdbmgrtab")
"   call Decho("(GdbMgrInit) make new tab, set up autocmds")
   tabnew

   " assign each GdbMgrTab its own number
   let t:gdbmgrtab= s:gdbmgrcnt
   if !exists("s:gdbmgrsignbase")
	sil call s:GdbMgrPickSignBase()
   endif
"   call Decho("set t:gdbmgrtab=".t:gdbmgrtab."  t:gdbmgrsignbase=".t:gdbmgrsignbase)

  " initialize running state to R
  let s:gdbmgr{t:gdbmgrtab}_running= "R"

   " Registration -- associates codes to initialization functions, update functions, and gdbmgr-library functions
"   call Decho("registry: maps code to initialization and update functions")
   call gdbmgr#Register('A', "s:AssemblyInit"  , "s:AssemblyUpdate")
   call gdbmgr#Register('B', "s:BreakptInit"   , "s:BreakptUpdate")
   call gdbmgr#Register('C', "s:CmdInit"       , "s:CmdUpdate")
   call gdbmgr#Register('E', "s:ExprInit"      , "s:ExprUpdate")
   call gdbmgr#Register('F', "s:FuncstackInit" , "s:FuncstackUpdate")
   call gdbmgr#Register('H', "s:CheckptInit"   , "s:CheckptUpdate")
   call gdbmgr#Register('M', "s:MesgInit"      , "s:MesgUpdate")
   call gdbmgr#Register('N', "s:NetrwInit"     , "s:NetrwUpdate")
   call gdbmgr#Register('S', "s:SourceInit"    , "s:SourceUpdate")
   call gdbmgr#Register('T', "s:ThreadInit"    , "s:ThreadUpdate")
   call gdbmgr#Register('W', "s:WatchpointInit", "s:WatchpointUpdate")

   " set up the GdbMgr windows
"   let eikeep= &ei  "Decho
"   set ei=all       "Decho
   echo "gdbmgr init [***      ]: windows"
   let sprkeep= &spr
   let sbkeep = &sb
   set nospr nosb
   call s:WinCtrl(gdbmgr_winctrl)
   let &spr= sprkeep
   let &sb = sbkeep
"   call Decho("resize:     ofix ocol qwoc ifix icol qwic rfix rows qwrows")
"   windo call Decho("resize: w#".winnr().
	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isofixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isofixed)     : '---').
	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedocols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedocols)   : '---').
	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildocols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildocols) : '---').
	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isifixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isifixed)     : '---').
	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedicols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedicols)   : '---').
	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildicols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildicols) : '---').
	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isrfixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isrfixed)     : '---').
	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedrows")?    printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedrows)    : '---').
	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildrows")?  printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildrows)  : '---').
       \ "  ".expand("%"))
"   let &ei= eikeep   "Decho

   " set netrw's g:netrw_chgwin window to the Source window
   if !exists("g:netrw_winsize") || g:netrw_winsize >= 0
	let g:netrw_winsize= -25
   endif
   if s:gdbmgr_registry_{t:gdbmgrtab}.N.bufnum != 0
	let prvcode= gdbmgr#GdbMgrForeground("N")
    call s:gdbmgr_registry_{t:gdbmgrtab}.N.Update()
	if prvcode != "N"
	 call gdbmgr#GdbMgrForeground(prvcode)
	endif
   endif

   " place cursor in source window
   echo "gdbmgr init [****     ]: source window"
   if s:gdbmgr_registry_{t:gdbmgrtab}.S.bufnum != 0
    exe bufwinnr(s:gdbmgr_registry_{t:gdbmgrtab}.S.bufnum)."wincmd w"
   else
	1wincmd w
   endif

  endif

"  call Decho("initialize gdbmgr library --------------------------------------------")
  if !exists("t:gdbmgr")
   " initialize gdbmgr library/gdb
   echo "gdbmgr init [*****    ]: library"
"   call Decho("sending gmInit to gdbmgr library")
   let t:gdbmgr= s:GdbMgrSend(28,"gmInit")
"   call Decho("initialized t:gdbmgr=".t:gdbmgr)
   if t:gdbmgr != "gdb ready"
	" looks like gmInit() didn't return that gdb is ready to use
"	call Decho("gdb is unusable: t:gdbmgr<".t:gdbmgr.">")
	call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(t:gdbmgr)
	echohl Error
	echomsg "(GdbMgrInit) unable to connect to gdb!"
	echohl None
	call s:GdbMgrOptionRestore()
    if exists("t:gdbmgrsignbase")               |unlet t:gdbmgrsignbase               |endif
    if exists("t:signidlist")                   |unlet t:signidlist                   |endif
    if exists("s:gdbmgr_registry_{t:gdbmgrtab}")|unlet s:gdbmgr_registry_{t:gdbmgrtab}|endif
    if exists("t:gdbmgrtab")                    |unlet t:gdbmgrtab                    |endif
    unlet t:gdbmgr
	sleep 2
"	call Dret("gdbmgr#GdbMgrInit : didn't receive \"gdb ready\" message")
	return
   endif
  else
   " otherwise kill the program currently running under gdb
   call Dechno("kill the program currently running under gdb")
   call s:GdbMgrSend(29,"gmGdb",s:server."kill")
  endif

  " tell gdb what program (+core-dump) is to be debugged
"  call Decho("tell gdb what pgm is to be debugged ----------------------------------")
  echo "gdbmgr init [******   ]: gdb"
  if exists("gdbcmd") && gdbcmd != ""
"   call Decho("sending to gmGdb: <file ".gdbcmd.">")
   let mesg= s:GdbMgrSend(30,"gmGdb",s:server."file ".gdbcmd)
   if mesg =~ '^\*\*\*error\*\*\*' || mesg =~ '^\*\*\*warning\*\*\*' || mesg =~ "not recognized"
"	call Decho("handle mesg<".mesg.">")
	echohl Error
	echomsg "(GdbMgrInit) ".mesg
	echohl None
	call s:GdbMgrOptionRestore()
    if exists("t:gdbmgrsignbase")               |unlet t:gdbmgrsignbase               |endif
    if exists("t:signidlist")                   |unlet t:signidlist                   |endif
    if exists("s:gdbmgr_registry_{t:gdbmgrtab}")|unlet s:gdbmgr_registry_{t:gdbmgrtab}|endif
    if exists("t:gdbmgrtab")                    |unlet t:gdbmgrtab                    |endif
    unlet t:gdbmgr
	sleep 2
"	call Dret("gdbmgr#GdbMgrInit : received message<".mesg."> during initialization")
	return
   else
	if exists("coredump")
"	 call Decho("handle coredump<".coredump.">")
	 let mesg= s:GdbMgrSend(31,"gmGdb","core ".coredump)
	endif
    call gdbmgr#GdbMgrSourceInitFile()
    " update foreign app support functions with source window number
	if exists("s:foreigncodes_{tabpagenr()}")
"	 call Decho("update foreign app windows")
	 let srcbuf= s:gdbmgr_registry_{t:gdbmgrtab}['S'].bufnum
	 let srcwin= bufwinnr(srcbuf)
	 let curwin= winnr()
"	 call Decho("srcbuf#".srcbuf)
"	 call Decho("srcwin#".srcwin)
"	 call Decho("curwin#".curwin)
"     call Decho("s:foreigncodes_".tabpagenr().": ".string(s:foreigncodes_{tabpagenr()}))
	 " Update every foreigncode display
	 for foreigncode in s:foreigncodes_{tabpagenr()}
"	  call Decho("handling foreigncode<".foreigncode.">")
	  let foreignbuf = s:gdbmgr_registry_{t:gdbmgrtab}[foreigncode].bufnum
"	  call Decho("foreignbuf#".foreignbuf)
	  if foreignbuf > 0
	   let prvcode= gdbmgr#GdbMgrForeground(foreigncode)
"	   call Decho("calling s:gdbmgr_registry_".t:gdbmgrtab."[".foreigncode."].Update(srcbuf<".srcbuf.">)")
	   call s:gdbmgr_registry_{t:gdbmgrtab}[foreigncode].Update(srcbuf)
"	   call Decho('(GdbMgrInit) setting <c-f6> to call gdbmgr#BufSwitch() in buf#'.bufnr("%"))
	   nn <buffer> <silent> <c-F6>	:call gdbmgr#BufSwitch()<cr>
	   if prvcode != foreigncode
		" restore previous code display in window overlying a foreign app
	    call gdbmgr#GdbMgrForeground(prvcode)
"		call Decho("prvcode<".prvcode.">")
"	    call Dredir("nmap <c-f6>")
	   endif
	  endif
	 endfor
	endif
   endif
  endif

"  call Decho("set up menus----------------------------------------------------------")
  echo "gdbmgr init [*******  ]: menus"
  call s:GdbMgrMenu("S")

  " set up status line for GdbMgr and menus
"  call Decho("set up status line ---------------------------------------------------")
  set stl=%1*%f%*\ %m\ Win#%{winnr()}\ Posn[%l,%c]\ %P
  call gdbmgr#GdbMgrForeground("S")
  sil! filetype detect

  " set up a BufWinEnter to handle new source in the source code window
  echo "gdbmgr init [******** ]: source"
  au BufWinEnter *	call s:GdbMgrCheckSrcChg()

  " enable autocmds
  augroup GdbMgrAutocmds
   au!
   au VimLeave		*	call s:GdbMgrQuit()
   au BufEnter		*	call s:GdbMgrMenu()
   au VimResized	*	call s:GdbMgrVimResized()
  augroup END
  redraw!
  echo "gdbmgr init [*********]: Done!"

"  call Decho("GdbMgr initialization now complete -----------------------------------")
"  call Dret("gdbmgr#GdbMgrInit")
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrRun: this routine is directly called by :DR {{{2
"                   It is also called by gdbmgr#GdbMgrCmd(), but with (...,0)
"                   s:gdbmgr_running: if true, gdb is running a process
"                                     initialized to stopped (S) by gdbmgr#GdbMgrInit()
"                                     when set to R, s:SourceUpdate()   installs cfnNsSuU maps
"                                     when set to S, s:SourceUpdate() uninstalls cfnNsSuU maps
fun! gdbmgr#GdbMgrRun(gdbcmd,...)
"  call Dfunc("gdbmgr#GdbMgrRun(gdbcmd<".a:gdbcmd.">) a:0=".a:0." s:gdbmgr".t:gdbmgrtab."_running=".s:gdbmgr{t:gdbmgrtab}_running)
  let gdbcmd= a:gdbcmd

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("gdbmgr#GdbMgrRun : gdbmgr not initialized yet!")
   return
  endif

  if gdbcmd !~ '^run'
   " this happens when :DR ... is used
"   call Decho("initiate running mode")
"   call Decho("1: bufnr(%)=".bufnr("%")." expand(%)<".expand("%")."> t:srcfile<".(exists("t:srcfile")? t:srcfile : 'n/a')."> t:srcline=".(exists("t:srcline")? t:srcline : 'n/a'))
   call gdbmgr#GdbMgrForeground("C")
   if gdbcmd == ""
    let gdbcmd= "run"
   else
    let gdbcmd= "run ".gdbcmd
   endif
  endif
"  call Decho("2: bufnr(%)=".bufnr("%")." expand(%)<".expand("%")."> t:srcfile<".(exists("t:srcfile")? t:srcfile : 'n/a')."> t:srcline=".(exists("t:srcline")? t:srcline : 'n/a'))

  if a:0 == 0 || a:1 != 0
   " issue command to go to run mode
   call gdbmgr#GdbMgrCmd(gdbcmd)
   call s:CmdPoll("starting")
   if s:gdbmgr{t:gdbmgrtab}_running == "R"
	call s:GotoWinCode("C")
   else
	call s:GotoWinCode("S")
   endif
  endif

"  call Dret("gdbmgr#GdbMgrRun : line($)=".line("$"))
endfun

" ---------------------------------------------------------------------
" gdbmgr#ShowRegistry: shows the registry contents {{{2
fun! gdbmgr#ShowRegistry()
  let eikeep= &ei
  set ei+=BufEnter
  let curwin= winnr()
"  windo call s:ShowRegistry()  " Decho
  exe curwin."wincmd w"
  let &ei= eikeep
endfun

" ---------------------------------------------------------------------
" s:ShowRegistry: {{{2
fun! s:ShowRegistry()

  if !exists("s:gdbmgr_registry_{t:gdbmgrtab}[".bufnr("%")."].code")
"   call Decho("win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> has no code!")
   return
  endif
  let code= s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code
"  call Decho("---- win#".winnr()." code<".code."> --- --- --- ---")
  " For debugging: give next/prev circular links
"  let dbgnxt     = s:gdbmgr_registry_{t:gdbmgrtab}[code].nxt                                                                         " Decho
"  let dbgnxtlist = code.":".bufnr("%")                                                                                               " Decho
"  while dbgnxt != code && dbgnxt != 'n/a'                                                                                            " Decho
"   let dbgbuf     = exists("s:gdbmgr_registry_{t:gdbmgrtab}[dbgnxt].bufnum")? s:gdbmgr_registry_{t:gdbmgrtab}[dbgnxt].bufnum : 'n/a' " Decho
"   let dbgnxtlist = dbgnxtlist." ".dbgnxt.":".dbgbuf                                                                                 " Decho
"   let dbgnxt     = exists("s:gdbmgr_registry_{t:gdbmgrtab}[dbgnxt].nxt")? s:gdbmgr_registry_{t:gdbmgrtab}[dbgnxt].nxt       : 'n/a' " Decho
"  endwhile                                                                                                                           " Decho
"  let dbgbuf     = exists("s:gdbmgr_registry_{t:gdbmgrtab}[dbgnxt].bufnum")? s:gdbmgr_registry_{t:gdbmgrtab}[dbgnxt].bufnum  : 'n/a' " Decho
"  let dbgnxtlist = dbgnxtlist." ".dbgnxt.":".dbgbuf                                                                                  " Decho
"  let dbgnxt     = exists("s:gdbmgr_registry_{t:gdbmgrtab}[dbgnxt].nxt")? s:gdbmgr_registry_{t:gdbmgrtab}[dbgnxt].nxt        : 'n/a' " Decho
"  call Decho("next list: ".dbgnxtlist)
"  let dbgprv     = s:gdbmgr_registry_{t:gdbmgrtab}[code].prv                                                                         " Decho
"  let dbgprvlist = code.":".bufnr("%")                                                                                               " Decho
"  while dbgprv != code && dbgprv != 'n/a'                                                                                            " Decho
"   let dbgbuf     = exists("s:gdbmgr_registry_{t:gdbmgrtab}[dbgprv].bufnum")? s:gdbmgr_registry_{t:gdbmgrtab}[dbgprv].bufnum : 'n/a' " Decho
"   let dbgprvlist = dbgprvlist." ".dbgprv.":".dbgbuf                                                                                 " Decho
"   let dbgprv     = exists("s:gdbmgr_registry_{t:gdbmgrtab}[dbgprv].prv")? s:gdbmgr_registry_{t:gdbmgrtab}[dbgprv].prv       : 'n/a' " Decho
"  endwhile                                                                                                                           " Decho
"  let dbgbuf     = exists("s:gdbmgr_registry_{t:gdbmgrtab}[dbgprv].bufnum")? s:gdbmgr_registry_{t:gdbmgrtab}[dbgprv].bufnum  : 'n/a' " Decho
"  let dbgprvlist = dbgprvlist." ".dbgprv.":".dbgbuf                                                                                  " Decho
"  let dbgprv     = exists("s:gdbmgr_registry_{t:gdbmgrtab}[dbgprv].prv")? s:gdbmgr_registry_{t:gdbmgrtab}[dbgprv].prv        : 'n/a' " Decho
"  call Decho("prev list: ".dbgprvlist)

endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrStack: stacks a code atop the current window {{{2
fun! gdbmgr#GdbMgrStack(code)
"  call Dfunc("gdbmgr#GdbMgrStack(code<".a:code.">)")
"  call gdbmgr#ShowRegistry()  " Decho

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("gdbmgr#GdbMgrStack : gdbmgr never initialized")
   return
  endif

  " if the requested code has never been registered, check if its a foreign app
  if !exists("s:gdbmgr_registry_".t:gdbmgrtab."['".a:code."'].bufnum")
"   call Decho("requested code<".a:code."> never previously registered")
   if s:RegisterForeignCode(a:code)
    echohl Error
	echomsg "***error*** code<".a:code."> is not supported"
    echohl None
"	call Dret("gdbmgr#GdbMgrStack : code<".a:code."> not supported")
    return
   endif

   " initialize a new foreign app with the given code
"   call Decho("case 1: initialize a foreign app for code<".a:code.">")
   let curcode= s:GetWinCode()
   let nxtcode= s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt
"   call Decho("curcode<".curcode."> nxtcode<".nxtcode.">")
   call s:gdbmgr_registry_{t:gdbmgrtab}[a:code].Init()
   let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].bufnum   = bufnr("%")
   let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")]      = {}
   let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code = a:code
   let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt      = nxtcode
   let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].prv      = curcode
   let s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt     = a:code
   let s:gdbmgr_registry_{t:gdbmgrtab}[nxtcode].prv     = a:code
   call s:GdbMgrUpdate(a:code)
"   call gdbmgr#ShowRegistry()  " Decho
"   call Dret("gdbmgr#GdbMgrStack")
   return
  endif
"  call Decho("requested code<".a:code."> is for an internal app")

  " get the buffer associated with the code
  let bufnum = s:gdbmgr_registry_{t:gdbmgrtab}[a:code].bufnum
  if bufnum <= 0
   " buffer is registered but the associated buffer doesn't exist.
   " This happens when there's a built-in code+buffer but it wasn't in the user's winctrl
"   call Decho("case 2,3: code<".a:code."> has a zero bufnum registered to it")
   let curbuf  = bufnr("%")
"   call Decho("curbuf#".curbuf." is ".(exists("s:gdbmgr_registry_".t:gdbmgrtab."[".curbuf."].code")? "" : " not ")."registered")

   if exists("s:gdbmgr_registry_".t:gdbmgrtab."[".curbuf."].code")
    let curcode = s:gdbmgr_registry_{t:gdbmgrtab}[curbuf].code
"	call Decho("case 2: window currently has a code<".curcode.">")
    let nxtcode = s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt
    let prvcode = s:gdbmgr_registry_{t:gdbmgrtab}[curcode].prv
"	call Decho("(before ".a:code.") curbuf#".curbuf." nxtcode<".nxtcode."> prvcode<".prvcode."> win#".winnr())
    call s:gdbmgr_registry_{t:gdbmgrtab}[a:code].Init()
    let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].bufnum  = bufnr("%")
    let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")]     = {}
    let s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code= a:code
    let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].prv     = curcode
    let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt     = nxtcode
    let s:gdbmgr_registry_{t:gdbmgrtab}[nxtcode].prv    = a:code
    let s:gdbmgr_registry_{t:gdbmgrtab}[prvcode].nxt    = a:code

   else
"	call Decho("case 3: replace non-coded buffer")
    call s:gdbmgr_registry_{t:gdbmgrtab}[a:code].Init()
	let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].prv     = a:code
	let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt     = a:code
   endif
   call s:gdbmgr_registry_{t:gdbmgrtab}[a:code].Update()
"   call gdbmgr#ShowRegistry()  " Decho
"   call Dret("gdbmgr#GdbMgrStack : just stacked code<".a:code."> in win#".winnr())
   return
  endif

  " get the window associated with the buffer
  let win = bufwinnr(bufnum)
"  call Decho("a:code<".a:code."> has buf#".bufnum." in win#".win)

  if win == -1
   " if there is no such window...
   if s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt == ' '
	" coded buffer is currently not on a stack anywhere, nor is it visible
"	call Decho("case 4: buf#".bufnum." not currently on a stack anywhere")
    let curcode= s:GetWinCode()
	if curcode == "n/a"
"	 call Decho("case 5: buf#".bufnum." not currently on a stack anywhere")
     let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt    = a:code
     let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].prv    = a:code
	 let emptybufnr= bufnr("%")
	 exe "b! ".bufnum
	 exe "bw ".emptybufnr
	else
     let nxtcode= s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt
"     call Decho("curcode<".curcode."> nxtcode<".nxtcode.">")
     let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt    = nxtcode
     let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].prv    = curcode
     let s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt   = a:code
     let s:gdbmgr_registry_{t:gdbmgrtab}[nxtcode].prv   = a:code
     call gdbmgr#BufSwitch()
	endif
	call s:GdbMgrUpdate(a:code)
"    call gdbmgr#ShowRegistry()  " Decho
"    call Dret("gdbmgr#GdbMgrStack")
	return

   else
	" coded buffer is currently not visible but on a stack
	" unstack the coded buffer
"	call Decho("coded buf#".bufnum." currently not visible but on a stack, so unstack it")
	call gdbmgr#GdbMgrUnstack(a:code)
   endif

  else
   " there is such a window, so the code is visible
   if s:GetWinCode() == a:code
	" requested code for stacking is visible and in the current window.
	" Do nothing.
"	call Decho("case 6: coded buf#".bufnum." visible in win#".win." and is current window")
	let mesg= "requested code<".a:code."> is already currently showing in current window"
    call s:gdbmgr_registry_{t:gdbmgrtab}["M"].Update(mesg)
"    call gdbmgr#ShowRegistry()  " Decho
"	call Dret("gdbmgr#GdbMgrStack : ".mesg)
	return
   endif

   " Make the buffer no longer visible, then unstack it
"   call Decho("case 7: coded buf#".bufnum." visible in win#".win)
"   call Decho("make buf#".bufnum." no longer visible then unstack it")

   " record current window
   " switch to window containing a:code'd buffer
   " unstack it
   " return to recorded window
   let curwin= winnr()
   exe win."wincmd w"
   call gdbmgr#GdbMgrUnstack(a:code)
   exe curwin."wincmd w"
  endif
  " COMBAK: move M atop F, then M back to empty.

  " restack the coded buffer in the current window
  " since it previously existed it shouldn't need initializing
  " Make the new coded buffer follow the current buffer, and then
  " do a BufSwitch to activate it.
  let curbuf= bufnr("%")
  if exists("s:gdbmgr_registry_".t:gdbmgrtab."[".curbuf."].code")
"   call Decho("case 8: restack a:code<".a:code."> buf#".bufnum." (after coded buffer)")
   let curcode= s:GetWinCode()
   let nxtcode= s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt
"   call Decho("a:code<".a:code."> curcode<".curcode."> nxtcode<".nxtcode."> bufnum#".bufnum)
   let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].bufnum = bufnum
   let s:gdbmgr_registry_{t:gdbmgrtab}[bufnum].code   = a:code
   let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt    = nxtcode
   let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].prv    = curcode
   let s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt   = a:code
   let s:gdbmgr_registry_{t:gdbmgrtab}[nxtcode].prv   = a:code
  else
"   call Decho("case 9: restack a:code<".a:code."> buf#".bufnum." (replace non-coded buffer)")
   exe "b! ".bufnum
   let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].prv = a:code
   let s:gdbmgr_registry_{t:gdbmgrtab}[a:code].nxt = a:code
  endif
  call s:GdbMgrUpdate(a:code)
  call gdbmgr#BufSwitch()
"  call gdbmgr#ShowRegistry()  " Decho

"  call Dret("gdbmgr#GdbMgrStack")
endfun

" ---------------------------------------------------------------------
" gdbmgr#GdbMgrUnstack: unstacks the current code'd buffer from the current window {{{2
"                       Note: Buffer is left hidden, but is no longer on the stack (or visible).
fun! gdbmgr#GdbMgrUnstack(...)
"  call Dfunc("gdbmgr#GdbMgrUnstack() a:0=".a:0)
"  call gdbmgr#ShowRegistry()  " Decho

  " sanity check
  if !exists("t:gdbmgrtab")
   echohl Error
   echomsg "***error*** gdbmgr has not been initialized!"
   echohl None
"   call Dret("gdbmgr#GdbMgrUnstack : gdbmgr never initialized")
   return
  endif

  " disable any BufWinLeave events
  let eikeep= &l:ei
  setlocal ei+=BufWinLeave

  if a:0 == 1
   let curcode= a:1
  else
   let curcode= s:GetWinCode()
  endif
"  call Decho("unstacking code<".curcode.">")
  let nxtcode= s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt
  let prvcode= s:gdbmgr_registry_{t:gdbmgrtab}[curcode].prv
"  call Decho("prvcode<".prvcode."> nxtcode<".nxtcode.">")
  if nxtcode == prvcode && nxtcode == curcode
   " this window only has one code assigned to it.  Make it empty.
   enew!
   setlocal noma ro nomod
   let s:gdbmgr_registry_{t:gdbmgrtab}[prvcode].nxt    = ' '
   let s:gdbmgr_registry_{t:gdbmgrtab}[nxtcode].prv    = ' '
   let s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt    = ' '
   let s:gdbmgr_registry_{t:gdbmgrtab}[curcode].prv    = ' '
"   let l:ei= eikeep
"   call gdbmgr#ShowRegistry()  " Decho
"   call Dret("gdbmgr#GdbMgrUnstack : window now empty")
   return
  else
   if a:0 == 0
    call gdbmgr#BufSwitch()
   endif
   let s:gdbmgr_registry_{t:gdbmgrtab}[prvcode].nxt    = nxtcode
   let s:gdbmgr_registry_{t:gdbmgrtab}[nxtcode].prv    = prvcode
   let s:gdbmgr_registry_{t:gdbmgrtab}[curcode].nxt    = ' '
   let s:gdbmgr_registry_{t:gdbmgrtab}[curcode].prv    = ' '
  endif

  " restore ei
  let l:ei= eikeep

"  call gdbmgr#ShowRegistry()  " Decho
"  call Dret("gdbmgr#GdbMgrUnstack")
endfun

" ---------------------------------------------------------------------
" s:WinCtrl: control what and where windows will display {{{2
"   Accepts a List of strings, each list entry corresponds to a WinCtrl String for that row
"   The first entry in each entry must be R:rows.  Separate windows are separated by
"   commas.  A "-" for rows or columns is the wildcard -- it'll grow to what's remaining.
"     ccols specifies qty of columns in the current []
"     rrows specifies qty of rows for the windows in this row
"     Bcols Breakpoint window
"     Ccols Command window
"     Ecols Expression window
"     Fcols Function stack window
"     Mcols Messages window
"     Ncols Netrw window
"     Scols Source code window
"     Tcols Threads window
"     Wcols Watchpoint window
"   The default WinCtrl string is given in gdbmgr#GdbMgrInit(); currently, that's
"     call s:WinCtrl(['r5,M-,F-','r-,S-','r5,E-,B-,W-'])
fun! s:WinCtrl(winctrl,...)
"  call Dfunc("s:WinCtrl(winctrl".string(a:winctrl).") a:0=".a:0)

  " Window parameters are stored as w:gdbmgr{t:gdbmgrtab}_WINDOWPARAMETER
  " Parameter    | abbrv  | local/script   | description
  "              |        |  cols          | fixed qty of columns
  "              |        |  wildcnt       | qty of wild specifications (c-, r-)
  "              |        |  qtycols       | qty of columns taken up, including vertical separators
  " isofixed     | ofix   | s:isofixed     | qty outer columns (ie. columns in a row-list) (0 if wild)
  " fixedocols   | ocol   | s:fixedocols   | sum of fixed outer columns
  " qtywildocols | qwoc   | s:qtywildocols | wildcnt when counting outer columns
  " isifixed     | ifix   | isifixed       | qty inner columns (ie. columns in a row-list) (0 if wild)
  " fixedicols   | icol   | fixedcols      | sum of fixed inner column specs plus both fixed and wild separators
  " qtywildicols | qwic   | wildcnt        | wildcnt when counting inner columns
  " isrfixed     | rfix   | isrfixed       | qty of fixed rows in winspec primitive
  " fixedrows    | rows   | fixedrows      | sum of fixed rows plus both fixed and wild separators
  " qtywildrows  | qwrows | qtywildrows    | wildcnt when counting rows

  " determine qty columns available for this window
"  call Decho("determine qty columns available for this window")
  if a:0 == 0
   let qtycols= &columns - 1 " -1 for signs column
   " parse the winctrl string for vertical container windows (outer columns)
"   call Decho("parse winctrl string for vertical container windows")
   let winspeccnt= 0
   let wildcnt   = 0
   let cols      = 0
   let outercols = 1
   for winspec in a:winctrl
"	call Decho("winspec<".string(winspec)."> type(winspec)=".type(winspec)."<".((type(winspec) == 3)? "List" : (type(winspec) == 1)? "String" : "not a List or String").">")
    if type(winspec) == 3
	 " the winspec itself is a List
 	 let winspeccnt= winspeccnt + 1
"	 call Decho("winspec#".winspeccnt.": ".string(winspec))
	 if winspec[0] !~ '^c'
	  echohl Error|redraw|echomsg "(s:WinCtrl) malformed winctrl list"|echohl None
"      call Dret("s:WinCtrl : malformed winctrl list")
      return
	 elseif winspec[0] == "c-"
	  let wildcnt   = wildcnt + 1
	  let outercols = outercols + 1
	 else
	  let cols      = cols + substitute(winspec[0],'^c\(\d\+\).\{-}$','\1','')
	  let outercols = outercols + 1
	 endif
    endif
   endfor
   " allow for window separator columns
   let qtycols= qtycols + outercols - 1
"   call Decho("winspeccnt=".winspeccnt." wildcnt=".wildcnt." cols=".cols)
"   call Decho("qtycols= [qtycols=".(qtycols-outercols+1)."+[outercols=".outercols."]-1=".qtycols)

   " has vertical container windows
   if winspeccnt > 0
"	call Decho("has vertical container windows")
    " sanity check
	if winspeccnt != len(a:winctrl)
     echohl Error
	 redraw|echomsg "(s:WinCtrl) malformed winctrl list"
     echohl None
"     call Dret("s:WinCtrl : malformed winctrl list")
     return
    endif

	" determine qty columns in wild-column vertical container windows
    if wildcnt > 0
	 let wildcols= (qtycols - cols + 1)/wildcnt
	else
	 let wildcols= 0
	endif
"	call Decho("wildcols=".wildcols." (qty columns in wild-column vertical container windows)")

	" sanity check
	if wildcols < 0
	 echohl Error
	 redraw|echomsg "(s:WinCtrl) too many columns specified (".cols.") for your screen"
	 echohl None
"	 call Dret("s:WinCtrl : too many columns specified")
     return
	endif

	" vertical container-window splits
	let iwin      = 1
	let ocolsleft = &columns
    for winspec in a:winctrl
"	 call Decho("iwin#".iwin." winspec<".string(winspec).">")
	 if winspec[0] == 'c-'
	  " wild column split
"	  call Decho("wild column split")
	  if iwin < len(a:winctrl)
	   let ocolsleft= ocolsleft - cols - 1
	   exe wildcols."vsplit"
       " record parameters for s:GdbMgrResize()
       let w:gdbmgr{t:gdbmgrtab}_isofixed     = s:isofixed
       let w:gdbmgr{t:gdbmgrtab}_fixedocols   = s:fixedocols
       let w:gdbmgr{t:gdbmgrtab}_qtywildocols = s:qtywildocols
"	   call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_isofixed    =".s:isofixed)
"	   call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_fixedocols  =".s:fixedocols)
"	   call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_qtywildocols=".s:qtywildocols)
	  endif
	  let s:isofixed     = 0
	  let s:fixedocols   = cols + 1
	  let s:qtywildocols = wildcnt
"	  call Decho("setting s:isofixed=".s:isofixed." s:fixedocols=".s:fixedocols." s:qtywildocols=".s:qtywildocols)
	  call s:WinCtrl(winspec[1:],wildcols)
	 else
	  " fixed column split
	  let cols      = 0 + substitute(winspec[0],'^c','','')
	  let ocolsleft = ocolsleft - cols - 1
"	  call Decho("fixed column split: cols=".cols." ocolsleft=".ocolsleft)
      " prepare to record parameters for s:GdbMgrResize()
	  let s:isofixed     = cols
	  let s:fixedocols   = 0
	  let s:qtywildocols = 0
"	  call Decho("setting s:isofixed=".s:isofixed." s:fixedocols=".s:fixedocols." s:qtywildocols=".s:qtywildocols)
      let w:gdbmgr{t:gdbmgrtab}_isofixed     = s:isofixed
      let w:gdbmgr{t:gdbmgrtab}_fixedocols   = s:fixedocols
      let w:gdbmgr{t:gdbmgrtab}_qtywildocols = s:qtywildocols
"	  call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_isofixed    =".s:isofixed)
"	  call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_fixedocols  =".s:fixedocols)
"	  call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_qtywildocols=".s:qtywildocols)
	  if iwin < len(a:winctrl)
	   exe cols."vsplit"
	  endif
	  call s:WinCtrl(winspec[1:],cols)
	 endif
	 wincmd l
	 let iwin= iwin + 1
	endfor

"	call Decho("after performing vertical container-window splits")
"	call Decho("winvar:     ofix ocol qwoc ifix icol qwic rfix rows qwrows")
"	windo call Decho("vsplit: w#".winnr().
 	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isofixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isofixed)     : '---').
 	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedocols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedocols)   : '---').
 	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildocols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildocols) : '---').
 	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isifixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isifixed)     : '---').
 	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedicols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedicols)   : '---').
 	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildicols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildicols) : '---').
 	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isrfixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isrfixed)     : '---').
 	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedrows")?    printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedrows)    : '---').
 	   \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildrows")?  printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildrows)  : '---'))
"    call Dret("s:WinCtrl")
    return
   endif
"   call Decho("no vertical container windows detected")
  else
   " handle inner row, column window
"   call Decho("handle inner row,column for win#".winnr()."  (case a:0=".a:0.")  isofixed=".s:isofixed." fixedocols=".s:fixedocols." qtywildocols=".s:qtywildocols)
   let qtycols = a:1
"   call Decho("[qtycols=a:1]=".qtycols)
   " record parameters for s:GdbMgrResize()
   let w:gdbmgr{t:gdbmgrtab}_isofixed     = s:isofixed
   let w:gdbmgr{t:gdbmgrtab}_fixedocols   = s:fixedocols
   let w:gdbmgr{t:gdbmgrtab}_qtywildocols = s:qtywildocols
  endif

  " determine wildrows
  let fixedrows = 0
  let wildcnt   = 0
  for rowspec in a:winctrl
   if rowspec =~ '^r\d'
	let fixedrows= fixedrows + substitute(rowspec,'^r\(\d\+\)','\1','') + 1
"	call Decho("determine wildrows (fixed): rowspec<".rowspec."> fixedrows=".fixedrows)
   else
	let wildcnt   = wildcnt + 1
	let fixedrows = fixedrows + 1
"	call Decho("determine wildrows (wild ): wildcnt=".wildcnt." fixedrows=".fixedrows)
   endif
  endfor
"  call Decho("end loop: wildcnt=".wildcnt." fixedrows=".fixedrows)
  if wildcnt > 0
   " account for lines in display, cmdheight, and qty of horizontal window separators
   let wildrows= (&lines - &cmdheight - fixedrows)/wildcnt
"   call Decho("wildrows=([&lines=".&lines."]-[cmdheight=".&cmdheight."]-[fixedrows=".fixedrows."]-".(len(a:winctrl)-1).")/[wildcnt=".wildcnt."]=".wildrows)
  else
   let wildrows= 0
"   call Decho("wildrows=0  (since wildcnt=".wildcnt.")")
  endif

  " horizontal splits
  let firstwin  = winnr()
"  call Decho("firstwin is win#".firstwin)
  for rowspec in a:winctrl[0:-2]
"   call Decho("hsplits: rowspec<".rowspec.">  win#".winnr())

   " lay out the rows
   let colspecs= split(rowspec,',')
   if colspecs[0] =~ '^r\d'
	" fixed rows
    let rows= substitute(colspecs[0],'^r\(\d\+\).*$','\1','')
"	call Decho("hsplits: (fixed) rows<".rows.">")
   else
	" wild rows
	let rows= wildrows
"	call Decho("hsplits: (wild ) rows<".rows.">")
   endif
"   call Decho("exe ".rows."split")
"   call Decho(" ---row sep---")
   if rows > 0
    exe rows."split"
   endif
   " record parameters for s:GdbMgrResize()
   let w:gdbmgr{t:gdbmgrtab}_isofixed     = s:isofixed
   let w:gdbmgr{t:gdbmgrtab}_fixedocols   = s:fixedocols
   let w:gdbmgr{t:gdbmgrtab}_qtywildocols = s:qtywildocols
   if colspecs[0] =~ '^r\d'
    let w:gdbmgr{t:gdbmgrtab}_isrfixed    = rows
	let w:gdbmgr{t:gdbmgrtab}_fixedrows   = 0
	let w:gdbmgr{t:gdbmgrtab}_qtywildrows = 0
   else
	let w:gdbmgr{t:gdbmgrtab}_isrfixed    = 0
	let w:gdbmgr{t:gdbmgrtab}_fixedrows   = fixedrows + &cmdheight
	let w:gdbmgr{t:gdbmgrtab}_qtywildrows = wildcnt
   endif
"   call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_isrfixed   =".w:gdbmgr{t:gdbmgrtab}_isrfixed)
"   call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_fixedrows  =".w:gdbmgr{t:gdbmgrtab}_fixedrows)
"   call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_qtywildrows=".w:gdbmgr{t:gdbmgrtab}_qtywildrows)
   wincmd j
  endfor

  " record parameters for s:GdbMgrResize() for last row
"  call Decho("record parameters for last row")
  let rowspec = a:winctrl[-1]
  let colspecs= split(rowspec,',')
  if colspecs[0] =~ '^r\d'
   let w:gdbmgr{t:gdbmgrtab}_isrfixed    = 0+substitute(colspecs[0],'^r\(\d\+\).*$','\1','')
   let w:gdbmgr{t:gdbmgrtab}_fixedrows   = 0
   let w:gdbmgr{t:gdbmgrtab}_qtywildrows = 0
  else
   let w:gdbmgr{t:gdbmgrtab}_isrfixed    = 0
   let w:gdbmgr{t:gdbmgrtab}_fixedrows   = fixedrows + &cmdheight
   let w:gdbmgr{t:gdbmgrtab}_qtywildrows = wildcnt
  endif
"  call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_isrfixed   =".w:gdbmgr{t:gdbmgrtab}_isrfixed)
"  call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_fixedrows  =".w:gdbmgr{t:gdbmgrtab}_fixedrows)
"  call Decho("recording: w#".winnr().":gdbmgr".t:gdbmgrtab."_qtywildrows=".w:gdbmgr{t:gdbmgrtab}_qtywildrows)

"  call Decho("after performing horizontal splits")
"  call Decho("winvar:     ofix ocol qwoc ifix icol qwic rfix rows qwrows")
"  windo call Decho("hsplit: w#".winnr().
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isofixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isofixed)     : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedocols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedocols)   : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildocols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildocols) : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isifixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isifixed)     : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedicols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedicols)   : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildicols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildicols) : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isrfixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isrfixed)     : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedrows")?    printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedrows)    : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildrows")?  printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildrows)  : '---'))

  " split each row into inner-column-based windows
"  call Decho("split each row into inner-column-based windows")
  exe firstwin."wincmd w"
  for rowspec in a:winctrl
   let colspecs= split(rowspec,',')
"   call Decho("rowspec<".string(rowspec).">")
"   call Decho("colspecs".string(colspecs))

   " determine the qty of columns in the current row
   let wildcnt   = 0
   let fixedcols = 0
   for colspec in colspecs
	if colspec =~ '^r'
	 continue
	elseif colspec =~ '\a\+\d'
	 let fixedcols= fixedcols + substitute(colspec,'\a\+\(\d\+\)','\1','') + 1
"     call Decho("determine wildcols: colspec<".colspec.">")
	else
	 let wildcnt   = wildcnt + 1
	 let fixedcols = fixedcols + 1
"	 call Decho("determine wildcols: wildcnt=".wildcnt)
    endif
   endfor
"   call Decho("end loop: wildcnt=".wildcnt)
   if wildcnt > 0
	" account for columns in display and one column per vertical window separator
	let wildcols= (qtycols - fixedcols + 1)/wildcnt
"	call Decho("wildcols=([qtycols=".qtycols."]-[fixedcols=".fixedcols."])/[wildcnt=".wildcnt."]=".wildcols)
   else
	let wildcols= 0
   endif

   " vertical splits
   for colspec in colspecs[0:-2]
"	call Decho("vsplits: colspec<".colspec.">")
	if colspec =~ '^r'
	 continue
	endif
	if colspec =~ '\a\+\d\+'
	 " fixed inner columns
	 let cols         = substitute(colspec,'\a\+\(\d\+\)','\1','')
	 let isifixed     = cols
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_isifixed     = ".w:gdbmgr{t:gdbmgrtab}_isifixed)
	else
	 " wild inner columns
	 let cols         = wildcols
	 let isifixed     = 0
	endif
"	call Decho("exe ".cols."vsplit")
	if cols > 0
     let isrfixed     = w:gdbmgr{t:gdbmgrtab}_isrfixed
     let fixedrows    = w:gdbmgr{t:gdbmgrtab}_fixedrows
     let qtywildrows  = w:gdbmgr{t:gdbmgrtab}_qtywildrows
	 exe cols."vsplit"
     " record parameters for s:GdbMgrResize()
     let w:gdbmgr{t:gdbmgrtab}_isofixed     = s:isofixed
     let w:gdbmgr{t:gdbmgrtab}_fixedocols   = s:fixedocols
     let w:gdbmgr{t:gdbmgrtab}_qtywildocols = s:qtywildocols
	 let w:gdbmgr{t:gdbmgrtab}_isifixed     = isifixed
	 let w:gdbmgr{t:gdbmgrtab}_fixedicols   = fixedcols
	 let w:gdbmgr{t:gdbmgrtab}_qtywildicols = wildcnt
     let w:gdbmgr{t:gdbmgrtab}_isrfixed     = isrfixed
     let w:gdbmgr{t:gdbmgrtab}_fixedrows    = fixedrows
     let w:gdbmgr{t:gdbmgrtab}_qtywildrows  = qtywildrows
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_isofixed     = ".w:gdbmgr{t:gdbmgrtab}_isofixed)
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_fixedocols   = ".w:gdbmgr{t:gdbmgrtab}_fixedocols)
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_qtywildocols = ".w:gdbmgr{t:gdbmgrtab}_qtywildocols)
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_isifixed     = ".w:gdbmgr{t:gdbmgrtab}_isifixed)
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_fixedicols   = ".w:gdbmgr{t:gdbmgrtab}_fixedicols)
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_qtywildicols = ".w:gdbmgr{t:gdbmgrtab}_qtywildicols)
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_isrfixed     = ".w:gdbmgr{t:gdbmgrtab}_isrfixed)
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_fixedrows    = ".w:gdbmgr{t:gdbmgrtab}_fixedrows)
"	 call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_qtywildrows  = ".w:gdbmgr{t:gdbmgrtab}_qtywildrows)
    endif
"    call Decho(" ---col sep---")
    sil wincmd l
   endfor

   " record parameters for s:GdbMgrResize() for the last window in the row
   let colspec= colspecs[-1]
   if colspec =~ '\a\+\d\+'
	let w:gdbmgr{t:gdbmgrtab}_isifixed     = 0+substitute(colspec,'\a\+\(\d\+\)','\1','')
	let w:gdbmgr{t:gdbmgrtab}_fixedicols   = 0
	let w:gdbmgr{t:gdbmgrtab}_qtywildicols = 0
   else
	let w:gdbmgr{t:gdbmgrtab}_isifixed     = 0
	let w:gdbmgr{t:gdbmgrtab}_fixedicols   = fixedcols
	let w:gdbmgr{t:gdbmgrtab}_qtywildicols = wildcnt
   endif
"   call Decho("record parameters for last window in row")
"   call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_isifixed     = ".w:gdbmgr{t:gdbmgrtab}_isifixed)
"   call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_fixedicols   = ".w:gdbmgr{t:gdbmgrtab}_fixedicols)
"   call Decho("record: w#".winnr().": w:gdbmgr".t:gdbmgrtab."_qtywildicols = ".w:gdbmgr{t:gdbmgrtab}_qtywildicols)

"   call Decho(" ---row sep---")
   sil wincmd j
  endfor

"  call Decho("after splitting each row into inner-column-based windows")
"  call Decho("winvar:     ofix ocol qwoc ifix icol qwic rfix rows qwrows")
"  windo call Decho("isplit: w#".winnr().
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isofixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isofixed)     : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedocols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedocols)   : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildocols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildocols) : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isifixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isifixed)     : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedicols")?   printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedicols)   : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildicols")? printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildicols) : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_isrfixed")?     printf("%3d",w:gdbmgr{t:gdbmgrtab}_isrfixed)     : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_fixedrows")?    printf("%3d",w:gdbmgr{t:gdbmgrtab}_fixedrows)    : '---').
      \ "  ".(exists("w:gdbmgr{t:gdbmgrtab}_qtywildrows")?  printf("%3d",w:gdbmgr{t:gdbmgrtab}_qtywildrows)  : '---').
	  \ "  ".expand("%:t"))

  " Build a dictionary assigning windows to each code
"  call Decho("building dictionary mapping codes to buffer numbers")
  if exists("s:codedict_{t:gdbmgrtab}")
   unlet s:codedict_{t:gdbmgrtab}
  endif
  let s:codedict_{t:gdbmgrtab}= {}
  exe firstwin."wincmd w"
"  call Decho("--- for rowspec in a:winctrl<".string(a:winctrl).">")
  for rowspec in a:winctrl
   let colspecs   = split(rowspec,',')
"   call Decho("    rowspec <".string(rowspec).">")
"   call Decho("    colspecs<".string(colspecs).">")
   let colspeccnt = 0
   for colspec in colspecs
	let codes= substitute(colspec,'^\(\a\+\)[-0-9]*$','\1','')
	if codes == 'r'
"	 call Decho("skipping codes<".codes.">")
	 continue
    endif
    if codes =~ 'S'
     " used by s:SourceInit()
	 sil! enew
	 file [Source]
	 setlocal nobuflisted ro nomod bt=nofile noswf
     let t:srcbuf= bufnr("%")
"     call Decho("    case codes=~'S': setting t:srcbuf=".t:srcbuf)
    endif
	let codeslen = strlen(codes)
	let i        = codeslen - 1
"	call Decho("    Register [codeslen=".codeslen."] codes<".codes.">")
	while i >= 0
	 let code= strpart(codes,i,1)
"	 call Decho("    --- i=".i." --- code<".code.">  win#".winnr())
"	 call Decho("    s:gdbmgr_registry_".t:gdbmgrtab."[".code."]".(exists("s:gdbmgr_registry_{t:gdbmgrtab}[code]")? "<".string(s:gdbmgr_registry_{t:gdbmgrtab}[code]).">" : " doesn't exist"))
	 if !exists("s:gdbmgr_registry_{t:gdbmgrtab}[code]")
	  " dynamic-loading for foreign window/buffer/code support
"	  call Decho("    dynamic-loading for foreign window/buffer/code support")
	  if s:RegisterForeignCode(code) < 0
	   echoerr "unable to autoload gdbmgr".code."#Init()"
	   let i= i - 1
	   continue
	  endif
	 endif
"	 call Decho("    calling s:gdbmgr_registry_".t:gdbmgrtab."[".code."].Init()")
	 " Init and Update set up in gdbmgr#Register()
	 " Init initializes the buffer to hold the desired code.
     call s:gdbmgr_registry_{t:gdbmgrtab}[code].Init()
     let  s:gdbmgr_registry_{t:gdbmgrtab}[code].bufnum     = bufnr("%")
     let  s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")]      = {}
     let  s:gdbmgr_registry_{t:gdbmgrtab}[bufnr("%")].code = code
	 let  s:gdbmgr_registry_{t:gdbmgrtab}[code].nxt        = strpart(codes,((i == codeslen-1)? 0            : (i+1)),1)
	 let  s:gdbmgr_registry_{t:gdbmgrtab}[code].prv        = strpart(codes,((i == 0)?          (codeslen-1) : (i-1)),1)
"	 call Decho("    set s:gdbmgr_registry_".t:gdbmgrtab."[".code."].bufnum=".bufnr("%")." nxt=".s:gdbmgr_registry_{t:gdbmgrtab}[code].nxt." prv=".s:gdbmgr_registry_{t:gdbmgrtab}[code].prv)
"	 call Decho("    set s:gdbmgr_registry_".t:gdbmgrtab."[".bufnr("%")."].code= ".code)
	 let i= i - 1
	endwhile
"	call Decho("    --- codes<".codes."> finished registering codes ---")
    sil wincmd l
    let colspeccnt= colspeccnt + 1
   endfor
   if colspeccnt > 1
    exe (colspeccnt-1)."wincmd h"
   endif
   sil wincmd j
  endfor

"  call Dret("s:WinCtrl")
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
