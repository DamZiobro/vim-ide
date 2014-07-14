function! GotoFileWithLineNumTag() 
    " filename under the cursor 
    let file_name = expand('<cfile>') 
    if !strlen(file_name) 
        echo 'NO FILE UNDER CURSOR' 
        return 
    endif 

    " look for a line number separated by a : 
    if search('\%#\f*:\zs[0-9]\+') 
        " change the 'iskeyword' option temporarily to pick up just numbers 
        let temp = &iskeyword 
        set iskeyword=48-57 
        let line_number = expand('<cword>') 
        exe 'set iskeyword=' . temp 
    endif 

    " edit the file 
    exe 'tag '.file_name 

    " if there is a line number, go to it 
    if exists('line_number') 
        exe line_number 
    endif 
endfunction  

"Register commands 
command! -bar -narg=0 GotoFileWithLineNumTag  call GotoFileWithLineNumTag()
