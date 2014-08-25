" vim:tw=78:fdm=marker:
let s:save_cpo = &cpo
set cpo&vim

function! s:default(option,value) "{{{
    if !exists(a:option)
        let {a:option} = a:value
        return 0
    endif
    return 1
endfunction "}}}

fun! s:load() "{{{
    aug CLICKABLE_BUFFER
        au! CursorMoved <buffer>  call clickable#hi_cursor()
        au! WinLeave,BufWinLeave <buffer>  2match none
    aug END
    for map in split(g:clickable_maps, ',')
        " NOTE: we must substitute for special map '<xxx>' to '[xxx]' to avoid 
        " comsuming while mapping.
        " >>> echo  substitute('<efe>', '<\([-0-9a-zA-Z]\+\)>','[\1]','g')
        " [efe]
        let map2 = substitute(map, '<\([-0-9a-zA-Z]\+\)>','[\1]','g')
        exe "nnore <silent><buffer> ".map." :call clickable#do('".map2."')<CR>"
    endfor
endfun "}}}

fun! s:init()

    let opt_list = [
        \ ["g:clickable_filetypes", 'txt,javascript,css,html,py,vim,java,jade,c,cpp'],
        \ ["g:clickable_extensions", 'txt,js,css,html,py,vim,java,jade,c,cpp'],
        \ ["g:clickable_maps","<2-leftmouse>,<CR>,<S-CR>,<C-CR>,<C-2-leftmouse>,<s-2-leftmouse>,gn"],
        \ ["g:clickable_confirm_creation", 1],
        \ ["g:clickable_browser", 'firefox'],
        \]

    for [opt, val] in opt_list
        call s:default(opt, val)
    endfor

    let filetypes = split(g:clickable_filetypes ,',')
    aug CLICKABLE_FT
        for ft in filetypes
            exe "au! FileType ".ft. " call s:load()"
        endfor
    aug END
endfun


call s:init()

let &cpo = s:save_cpo
unlet s:save_cpo
