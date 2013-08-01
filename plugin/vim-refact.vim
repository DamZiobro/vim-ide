" Vim refactoring plugin
" Last change: 2010-11-17
" Version 0.0.7
" Maintainer: Eustaquio 'TaQ' Rangel
" License: GPL
" URL: git://github.com/taq/vim-refact.git
"

let b:outside_pattern = ""
let b:check_outside   = 0
let b:inside_pattern  = ""
let b:start_pattern   = ""
let b:end_pattern     = ""
let b:method_pattern  = ""
let b:method          = ""
let b:cls_pattern     = ""
let b:cls             = ""
let b:attr_prefix     = ""
let b:line_terminator = ""
let b:assigments      = ""

augroup vimrefact
   au!
   autocmd FileType ruby call s:VimRefactLoadRuby()
   autocmd FileType java call s:VimRefactLoadJava()
   autocmd FileType php  call s:VimRefactLoadPHP()
augroup END

function! s:VimRefactLoadRuby()
   let b:outside_pattern = '^\s*\%(def\|class\|module\) ' 
   let b:check_outside   = 1
   let b:inside_pattern  = '^\s*\%(def\|class\|module\|while\|for\|do\) ' 
   let b:start_pattern   = ''
   let b:end_pattern     = 'end'
   let b:method_pattern  = '^\s*def '
   let b:method          = 'def'
   let b:cls_pattern     = '^\s*\%(class\|def\|while\|for\)' 
   let b:cls             = 'class'
   let b:attr_prefix     = "@"
   let b:line_terminator = ""
   let b:assigments      = '+=\|-=\|*=\|/=\|=\~\|!=\|='
endfunction

function! s:VimRefactLoadJava()
   let b:outside_pattern = '{' 
   let b:inside_pattern  = '{' 
   let b:start_pattern   = '{'
   let b:end_pattern     = '}'
   let b:method_pattern  = '^\(.*class\)\@!.*$'
   let b:method          = 'public void'
   let b:cls_pattern     = 'class\s\+\w\+\s\?{\?'
   let b:cls             = 'class' 
   let b:attr_prefix     = 'this\.'
   let b:line_terminator = ";"
   let b:assigments      = '+=\|-=\|*=\|/=\|=\~\|!=\|++\|--\|='
endfunction

function! s:VimRefactLoadPHP()
   let b:outside_pattern = '{' 
   let b:inside_pattern  = '{' 
   let b:start_pattern   = '{'
   let b:end_pattern     = '}'
   let b:method_pattern  = 'function'
   let b:method          = 'function'
   let b:cls_pattern     = '^\s*\%(class\|function\|while\|foreach\)'
   let b:cls             = 'class' 
   let b:attr_prefix     = '$this->'
   let b:line_terminator = ";"
   let b:assigments      = '+=\|-=\|*=\|/=\|=\~\|!=\|++\|--\|='
endfunction

function! s:VimRefactGetScope()
   if strlen(b:outside_pattern)<1
      return
   endif
   let l:expr = b:check_outside ? 'getline(".") !~ b:outside_pattern' : 0
   let l:ppos = searchpairpos(b:inside_pattern,'',b:end_pattern,"bW",l:expr)
   let l:npos = searchpairpos(b:inside_pattern ,'',b:end_pattern,"W")
   if l:ppos[0]>0 && l:ppos[1]>0 && l:npos[0]>0 && l:npos[1]>0
      let l:type = substitute(matchlist(getbufline("%",l:ppos[0])[0],b:outside_pattern)[0]," ","","")
   else
      let l:type = -1 
   endif
   return [l:ppos,l:npos,l:type]
endfunction

function! s:VimRefactGetClassScope()
   let l:ppos = searchpairpos(b:cls_pattern,'',b:end_pattern,'Wb','getline(".") !~ "".b:cls.""')
   let l:npos = searchpairpos(b:cls_pattern,'',b:end_pattern,'W')
   return [l:ppos,l:npos]
endfunction

function! s:VimRefactExtractMethod(...) range
   let l:mode = visualmode()
   if l:mode != "V"
      return
   endif

   " get some info
   let l:scope = s:VimRefactGetScope()
   if  l:scope[2]==-1
      return
   end
   let l:size  = l:scope[1][0]-l:scope[0][0]
   let l:argx  = ""
   let l:imeth = getbufline("%",l:scope[0][0])[0] =~ b:method_pattern
   let l:mname = ""

   " lets check if there are arguments
   if(a:[0]>1)
      let l:argl = []
      for l:argi in range(a:[0]-1)
         call add(l:argl,a:000[l:argi+1])
      endfor         
      let l:argx  = "(".join(l:argl,",").")"
      let l:mname = a:1
   else
      let l:mname = s:VimRefactPrompt("Type the new method name")
      if strlen(l:mname)<1
         return
      endif
      let l:tokens = split(l:mname)
      let l:mname  = l:tokens[0]
      if len(l:tokens)>1
         let l:argx = "(".join(l:tokens[1:],",").")"
      endif
   endif

   " yank and create a new method
   silent execute a:firstline.",".a:lastline."y"
   call append(l:scope[1][0]+(l:imeth ? 0 : -2),b:method." ".l:mname.l:argx." ".b:start_pattern)
   call append(l:scope[1][0]+(l:imeth ? 1 : -2),b:end_pattern)

   " put the yanked content
   silent execute l:scope[1][0]+(l:imeth ? 1 : 0)."put"

   " delete the selection and call the new method there, if needed
   silent execute a:firstline.",".a:lastline."d"
   if(l:imeth)
      call append(a:firstline-1,l:mname.l:argx.b:line_terminator)
   endif      

   " indent the block
   silent execute ":".l:scope[0][0]
   call feedkeys("\<S-v>")
   call feedkeys(((l:size*2)-1)."j")
   call feedkeys("=","t")
endfunction

function! s:VimRefactPrompt(prompt)
   if &term =~ 'gui'
      return inputdialog(a:prompt)
   else
      call inputsave()
      let l:rtn = input(a:prompt." (or return to cancel): ")
      call inputrestore()
      return l:rtn
   endif
endfunction

function! s:VimRefactAskForNewVarName()
   let l:oname = expand("<cword>")
   let l:nname = s:VimRefactPrompt("Type the new variable name")
   if strlen(l:nname)<1
      return
   endif
   call s:VimRefactRenameVariable(l:oname,l:nname)
endfunction

function! s:VimRefactRenameVariable(...)
   let l:scope = s:VimRefactGetScope()
   execute l:scope[0][0].",".l:scope[1][0]."s/\\<".a:[1]."\\>/".a:[2]."/g"
endfunction

function! s:VimRefactAskForNewAttrName()
   let l:oname = expand("<cword>")
   let l:nname = s:VimRefactPrompt("Type the new attribute name")
   if strlen(l:nname)<1
      return
   endif
   call s:VimRefactRenameAttribute(l:oname,l:nname)
endfunction

function! s:VimRefactRenameAttribute(...)
   let l:scope = s:VimRefactGetClassScope()
   execute l:scope[0][0].",".l:scope[1][0]."s/".b:attr_prefix.a:[1]."/".b:attr_prefix.a:[2]."/g"
endfunction

function! s:VimRefactAlignAssigments() range
   let l:max   = 0
   let l:maxo  = 0
   let l:linc  = ""
   for l:line in range(a:firstline,a:lastline)
      let l:linc  = getbufline("%",l:line)[0]
      let l:rst   = match   (l:linc,'\%('.b:assigments.'\)')
      let l:rstl  = matchstr(l:linc,'\%('.b:assigments.'\)')
      if l:rst<0
         continue
      endif
      let l:max   = max([l:max ,strlen(substitute(strpart(l:linc,0,l:rst),'\s*$','',''))+1])
      let l:maxo  = max([l:maxo,strlen(l:rstl)])
   endfor
   let l:formatter= '\=printf("%-'.l:max.'s%-'.l:maxo.'s%s",submatch(1),submatch(2),submatch(3))'
   let l:expr     = '^\(.\{-}\)\s*\('.b:assigments.'\)\(.*\)'
   for l:line in range(a:firstline,a:lastline)
      let l:oldline = getbufline("%",l:line)[0]
      let l:newline = substitute(l:oldline,l:expr,l:formatter,"")
      call setline(l:line,l:newline)
   endfor
endfunction

command! -range -nargs=+ Rem :<line1>,<line2>call <SID>VimRefactExtractMethod(<f-args>)
command! -nargs=+ Rrv :call <SID>VimRefactRenameVariable(<f-args>)
command! -nargs=+ Rra :call <SID>VimRefactRenameAttribute(<f-args>)

vnoremap rem :call <SID>VimRefactExtractMethod()<CR>
nnoremap rrv :call <SID>VimRefactAskForNewVarName()<CR>
vnoremap rrv :call <SID>VimRefactAskForNewVarName()<CR>
nnoremap rra :call <SID>VimRefactAskForNewAttrName()<CR>
vnoremap rra :call <SID>VimRefactAskForNewAttrName()<CR>
vnoremap raa :call <SID>VimRefactAlignAssigments()<CR>
