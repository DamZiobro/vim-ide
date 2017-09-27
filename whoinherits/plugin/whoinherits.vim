" WhoInherits - it shows subclasses of current class - it uses cscope
" as dependency 
"
" It works in Java only for now
"
" Key Shortcut: <C-\>o :WhoInherits 
"
" Author: Damian Ziobro <demian@xmementoit.com>
"
if !has('python')
    finish
endif

let g:pyscript = resolve(expand('<sfile>:p:h:h')) . '/plugin/whoinherits.py'

function! WhoInheritsFunc(cls, list)
    execute 'pyfile '. g:pyscript
endfunction

function! PreWhoInheritsFunc()
    "fulfill quickfix window
    let l:word = expand("<cword>")
    execute "scs find s " . l:word
    q
    " move to the buffer on the left
    let l:qflist = getqflist()
    call WhoInheritsFunc(l:word, l:qflist)
endfunction

command! WhoInherits call PreWhoInheritsFunc()

" mapping key <C-\>u to command WhoInherits
nmap <C-\>o :WhoInherits<cr>
