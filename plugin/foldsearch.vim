" Name: foldsearch.vim
" Version: $Id: foldsearch.vim 2213 2008-07-20 10:39:03Z mbr $
" Author: Markus Braun
" Summary: Vim plugin to fold away lines that don't match a search pattern
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt
" Section: Documentation {{{1
"
" Description:
"
"   This plugin provides commands that fold away lines that don't match
"   a specific search pattern.  This pattern can be the word under the cursor,
"   the last search pattern, a regular expression or spelling errors. There
"   are also commands to change the context of the shown lines.
"
" Installation:
"
"   Copy the foldsearch.vim file to the $HOME/.vim/plugin directory.
"   Refer to ':help add-plugin', ':help add-global-plugin' and ':help
"   runtimepath' for more details about Vim plugins.
"
" Commands:
"
"   :Fw [context*] show lines which contain the word under the cursor. Default
"                  [context] is 0.
"  
"   :Fs [context*] show lines which contain previous search pattern. Default
"                  [context] is 0.
"  
"   :Fp pattern    show the lines that contain the regular expression. Context
"                  is 0.
"  
"   :Fl            fold again with the last used pattern
"
"   :FS            show the lines that contain spelling errors.
"
"   :Fc [context*] show context lines.
"  
"   :Fi            increment context by one line.
"  
"   :Fd            decrement context by one line.
"  
"   :Fe            set modified fold options to their previous value
"
"   * context can consist of one or two numbers. A 'unsigned' number defines
"     the context before and after the pattern. If a number has a '-' prefix,
"     it defines only the context before the pattern. If it has a '+' prefix,
"     it defines only the context after a pattern.
"
" Mappings:
"
"   <Leader>fs     FoldSearch()
"   <Leader>fw     FoldCword()
"   <Leader>fS     FoldSpell()
"   <Leader>fl     FoldLast()
"   <Leader>fi     FoldContextAdd(+1)
"   <Leader>fd     FoldContextAdd(-1)
"   <Leader>fe     FoldSearchEnd()
"
" Section: Plugin header {{{1

if (exists("g:loaded_foldsearch") || &cp)
  finish
endi
let g:loaded_foldsearch = "$Revision: 2213 $"

" Section: Functions {{{1

" Function: s:FoldCword(...) {{{2
"
" Search and fold the word under the curser. Accept a optional context argument.
"
function! s:FoldCword(...)
  " define the search pattern
  let b:foldsearch_pattern = '\<'.expand("<cword>").'\>'

  " determine the number of context lines
  if (a:0 ==  0)
    call s:FoldSearchDo()
  elseif (a:0 == 1)
    call s:FoldSearchContext(a:1)
  elseif (a:0 == 2)
    call s:FoldSearchContext(a:1, a:2)
  endif

endfunction

" Function: s:FoldSearch(...) {{{2
"
" Search and fold the last search pattern. Accept a optional context argument.
"
function! s:FoldSearch(...)
  " define the search pattern
  let b:foldsearch_pattern = @/

  " determine the number of context lines
  if (a:0 == 0)
    call s:FoldSearchDo()
  elseif (a:0 == 1)
    call s:FoldSearchContext(a:1)
  elseif (a:0 == 2)
    call s:FoldSearchContext(a:1, a:2)
  endif

endfunction

" Function: s:FoldPattern(pattern) {{{2
"
" Search and fold the given regular expression.
"
function! s:FoldPattern(pattern)
  " define the search pattern
  let b:foldsearch_pattern = a:pattern

  " call the folding function
  call s:FoldSearchDo()
endfunction

" Function: s:FoldSpell(...)  {{{2
"
" do the search and folding based on spellchecker
"
function! s:FoldSpell(...)
  " if foldsearch_pattern is not defined, then exit
  if (!&spell)
    echo "Spell checking not enabled, ending Foldsearch"
    return
  endif

  let b:foldsearch_pattern = ""

  " do the search
  let lnum = 1
  while lnum <= line("$")
    let bad_word = spellbadword(getline(lnum))[0]
    if bad_word != ''
      if empty(b:foldsearch_pattern)
        let b:foldsearch_pattern = bad_word
      else
        let b:foldsearch_pattern = b:foldsearch_pattern . "\\|" . bad_word
      endif
    endif
    let lnum = lnum + 1
  endwhile

  " report if pattern not found and thus no fold created
  if (empty(b:foldsearch_pattern))
    echo "No spelling errors found!"
  else
    " determine the number of context lines
    if (a:0 == 0)
      call s:FoldSearchDo()
    elseif (a:0 == 1)
      call s:FoldSearchContext(a:1)
    elseif (a:0 == 2)
      call s:FoldSearchContext(a:1, a:2)
    endif
  endif

endfunction

" Function: s:FoldLast(...) {{{2
"
" Search and fold the last pattern
"
function! s:FoldLast()
  if (!exists("b:foldsearch_context_pre") || !exists("b:foldsearch_context_post") || !exists("b:foldsearch_pattern"))
    return
  endif

  " call the folding function
  call s:FoldSearchDo()
endfunction

" Function: s:FoldSearchContext(context) {{{2
"
" Set the context of the folds to the given value
"
function! s:FoldSearchContext(...)
  " force context to be defined
  if (!exists("b:foldsearch_context_pre"))
    let b:foldsearch_context_pre = 0
  endif
  if (!exists("b:foldsearch_context_post"))
    let b:foldsearch_context_post = 0
  endif

  if (a:0 == 0)
    " if no new context is given display current and exit
    echo "Foldsearch context: pre=".b:foldsearch_context_pre." post=".b:foldsearch_context_post
    return
  else
    let number=1
    let b:foldsearch_context_pre = 0
    let b:foldsearch_context_post = 0
    while number <= a:0
      execute "let argument = a:" . number . ""
      if (strpart(argument, 0, 1) == "-")
	let b:foldsearch_context_pre = strpart(argument, 1)
      elseif (strpart(argument, 0, 1) == "+")
	let b:foldsearch_context_post = strpart(argument, 1)
      else
	let b:foldsearch_context_pre = argument
	let b:foldsearch_context_post = argument
      endif
      let number = number + 1
    endwhile
  endif

  if (b:foldsearch_context_pre < 0)
    let b:foldsearch_context_pre = 0
  endif
  if (b:foldsearch_context_post < 0)
    let b:foldsearch_context_post = 0
  endif

  " call the folding function
  call s:FoldSearchDo()
endfunction

" Function: s:FoldContextAdd(change) {{{2
"
" Change the context of the folds by the given value.
"
function! s:FoldContextAdd(change)
  " force context to be defined
  if (!exists("b:foldsearch_context_pre"))
    let b:foldsearch_context_pre = 0
  endif
  if (!exists("b:foldsearch_context_post"))
    let b:foldsearch_context_post = 0
  endif

  let b:foldsearch_context_pre = b:foldsearch_context_pre + a:change
  let b:foldsearch_context_post = b:foldsearch_context_post + a:change

  if (b:foldsearch_context_pre < 0)
    let b:foldsearch_context_pre = 0
  endif
  if (b:foldsearch_context_post < 0)
    let b:foldsearch_context_post = 0
  endif

  " call the folding function
  call s:FoldSearchDo()
endfunction

" Function: s:FoldSearchInit() {{{2
"
" initialize fold searching for current buffer
"
function! s:FoldSearchInit()
  " force context to be defined
  if (!exists("b:foldsearch_context_pre"))
    let b:foldsearch_context_pre = 0
  endif
  if (!exists("b:foldsearch_context_post"))
    let b:foldsearch_context_post = 0
  endif
  if (!exists("b:foldsearch_foldsave"))
    let b:foldsearch_foldsave = 0
  endif

  " save state if needed
  if (b:foldsearch_foldsave == 0)
    let b:foldsearch_foldsave = 1
    
    " make a view of the current file for later restore of manual folds
    let b:foldsearch_viewoptions = &viewoptions
    let &viewoptions = "folds,options"
    let b:foldsearch_viewfile = tempname()
    execute "mkview " . b:foldsearch_viewfile
  endif

  let &foldtext = ""
  let &foldmethod = "manual"
  let &foldenable = 1
  let &foldminlines = 0

  " erase all folds to begin with
  normal zE
endfunction

" Function: s:FoldSearchDo()  {{{2
"
" do the search and folding based on b:foldsearch_pattern and
" b:foldsearch_context
"
function! s:FoldSearchDo()
  " if foldsearch_pattern is not defined, then exit
  if (!exists("b:foldsearch_pattern"))
    echo "No search pattern defined, ending fold search"
    return
  endif

  " initialize fold search for this buffer
  call s:FoldSearchInit()

  " save cursor position
  let cursor_position = line(".") . "normal!" . virtcol(".") . "|"

  " move to the end of the file 
  normal $G
  let pattern_found = 0      " flag to set when search pattern found
  let fold_created = 0       " flag to set when a fold is found
  let flags = "w"            " allow wrapping in the search
  let line1 =  0             " set marker for beginning of fold

  " do the search
  while search(b:foldsearch_pattern, flags) > 0
    let pattern_found = 1
    let line2 = line(".") - b:foldsearch_context_pre
    if (line2 - 1 >= line1 && line2 - 1 != 0)
      execute ":" . line1 . "," . (line2 - 1) . "fold"
      let fold_created = 1       " at least one fold has been found
    endif
    let line1 = line2 + 1 + b:foldsearch_context_pre + b:foldsearch_context_post " update marker
    let flags = "W"              " turn off wrapping
  endwhile

  " now create the last fold which goes to the end of the file.
  normal $G
  let  line2 = line(".")
  if (line2  >= line1 && pattern_found == 1)
    execute ":". line1 . "," . line2 . "fold"
  endif

  " report if pattern not found and thus no fold created
  if (pattern_found == 0)
    echo "Pattern not found!"
  elseif (fold_created == 0)
    echo "No folds created"
  else
    echo "Foldsearch done"
  endif

  " restore position before folding
  execute cursor_position

  " make this position the vertical center
  normal zz

endfunction

" Function: s:FoldSearchEnd() {{{2
"
" End the fold search and restore the saved settings
"
function! s:FoldSearchEnd()
  " save cursor position
  let cursor_position = line(".") . "normal!" . virtcol(".") . "|"

  if (!exists('b:foldsearch_foldsave'))
    let b:foldsearch_foldsave = 0
  endif
  if (b:foldsearch_foldsave == 1)
    let b:foldsearch_foldsave = 0

    " restore the folds before foldsearch
    execute "silent! source " . b:foldsearch_viewfile
    call delete(b:foldsearch_viewfile)
    let &viewoptions = b:foldsearch_viewoptions

  endif

  " give a message to the user
  echo "Foldsearch ended"

  " open all folds for the current cursor position
  silent! execute "normal " . foldlevel(line(".")) . "zo"

  " restore position before folding
  execute cursor_position

  " make this position the vertical center
  normal zz

endfunction
" Section: Commands {{{1
command! -nargs=* -complete=command Fs call s:FoldSearch(<f-args>)
command! -nargs=* -complete=command Fw call s:FoldCword(<f-args>)
command! -nargs=1 Fp call s:FoldPattern(<q-args>)
command! -nargs=* -complete=command FS call s:FoldSpell(<f-args>)
command! -nargs=0 Fl call s:FoldLast()
command! -nargs=* Fc call s:FoldSearchContext(<f-args>)
command! -nargs=0 Fi call s:FoldContextAdd(+1)
command! -nargs=0 Fd call s:FoldContextAdd(-1)
command! -nargs=0 Fe call s:FoldSearchEnd()
" Section: Mappings {{{1
map <Leader>fs :call <SID>FoldSearch()<CR>
map <Leader>fw :call <SID>FoldCword()<CR>
map <Leader>fS :call <SID>FoldSpell()<CR>
map <Leader>fl :call <SID>FoldLast()<CR>
map <Leader>fi :call <SID>FoldContextAdd(+1)<CR>
map <Leader>fd :call <SID>FoldContextAdd(-1)<CR>
map <Leader>fe :call <SID>FoldSearchEnd()<CR>
" vim600:fdm=marker:commentstring="\ %s:
