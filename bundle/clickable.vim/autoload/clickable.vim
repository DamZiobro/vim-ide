" Make Things Clickable.

" vim:tw=78:fdm=marker:
" let b:is_loaded = exists("b:is_loaded") ? b:is_loaded : 0
" if b:is_loaded == 0
"     finish
"     let b:is_loaded = 1
" endif
let s:is_clickable = ''
let s:click_text = ''
let [s:hl_row, s:hl_bgn,s:hl_end] = [0, 0 , 0]

let s:link_mail = '<[[:alnum:]_-]+%(\.[[:alnum:]_-]+)*\@[[:alnum:]]%([[:alnum:]-]*[[:alnum:]]\.)+[[:alnum:]]%([[:alnum:]-]*[[:alnum:]])=>'
let s:link_url  = '<%(%(file|https=|ftp|gopher)://|%(mailto|news):)([^[:space:]''\"<>]+[[:alnum:]/])'
let s:link_www  = '<www[[:alnum:]_-]*\.[[:alnum:]_-]+\.[^[:space:]''\"<>]+[[:alnum:]/]'
"
" >>> echo matchstr('(fef.fef@efef.com)', '\v'.s:link_mail)
" >>> echo matchstr('(news://aefew.eaef.cc/)', '\v'.s:link_url)
" >>> echo matchstr('(www.test.cc/u/1?p=1&u=3)', '\v'.s:link_www)
" fef.fef@efef.com
" news://aefew.eaef.cc/
" www.test.cc/u/1?p=1&u=3
let s:link_uri  = '\v'.s:link_url .'|'. s:link_www .'|'.s:link_mail

let fname_bgn = '%(^|\s|[''"([{<,;!?])'
let fname_end = '%($|\s|[''")\]}>:.,;!?])'

fun! s:norm_list(list,...) "{{{
    " return list with words
    return filter(map(a:list,'matchstr(v:val,''\w\+'')'), ' v:val!=""')
endfun "}}}

let s:file_ext_lst = s:norm_list(split(g:clickable_extensions,','))

let s:file_ext_ptn = join(s:file_ext_lst,'|')

let file_name = '[[:alnum:]~./][[:alnum:]~:./\\_-]*[[:alnum:]/\\]'
let s:link_file  = '\v' . fname_bgn
            \. '@<=' . file_name
            \.'%(\.%('. s:file_ext_ptn .')|/)\ze'
            \.fname_end 
" >>> echo 'ajewfioaej.tta' =~ s:ext_file_link
" >>> echo '~/test/ajewfioaej.txt' =~ s:ext_file_link
" >>> echo 'd:/test/ajewfioaej.txt' =~ s:ext_file_link
" >>> echo 'd:\test\ajewfioaej.txt' =~ s:ext_file_link
" >>> echo '/tes00-t/ajewf~oaej.txt' =~ s:ext_file_link
" 0
" 1
" 1
" 1
" 1


fun! s:is_fold_closed() "{{{
    return foldclosed('.') != -1
endfun "}}}
fun! s:is_fold_firstline() "{{{
    return &fdm == 'marker' && getline('.') =~ split(&foldmarker,',')[0]
endfun "}}}
fun! s:open_fold() "{{{
    exe "norm! zv"
endfun "}}}
fun! s:close_fold() "{{{
    exe "norm! zc"
endfun "}}}

fun! s:auto_mkdir(path) "{{{
    if !isdirectory(fnamemodify(a:path,':h'))
        call mkdir(fnamemodify(a:path,':h'),'p')
    endif
endfun "}}}
fun! s:open_link(link) "{{{
    call s:system(g:clickable_browser." ".a:link)
endfun "}}}
fun! s:system(expr) abort "{{{
    if exists("*vimproc#system")
        call vimproc#system(a:expr)
    else
        call system(a:expr)
    endif
endfun "}}}


fun! s:open_file(file) "{{{
    exe "edit" a:file
endfun "}}}
fun! s:in_hl_region(row, col) "{{{
    return !&modified && a:row == s:hl_row && a:col >= s:hl_bgn && a:col <= s:hl_end
endfun "}}}

fun! clickable#get_WORD_bgn(line, col) "{{{
    " Get Current WORD's idx
    "
    " @param 
    " line: a string, usually is a line
    " col: the cursor's colnum position
    "
    " col num start from 1 
    " hello world
    " 123456789
    "
    " @return 
    " the match index (byte offset), start from 0
    "
    " >>> echo clickable#get_WORD_bgn("hello world", 2)
    " 0
    
    let ptn = printf('\%%%dc.', a:col)
    if matchstr(a:line, ptn)=~'\S'
        return match(a:line, '\S*'.ptn)
    else
        return -1
    endif
endfun "}}}

fun! s:match_object(str,ptn,...) "{{{
    " return a python like match object
    " @param: string, pattern,  [start]
    " @return object { start,end, groups, str}

    let start = a:0 ? a:1 : 0
    let s = {}

    let idx = match(a:str,a:ptn,start)
    if idx == -1
        return s
    endif

    let s.start  = idx
    let s.groups = matchlist(a:str,a:ptn,start)
    let s.str    = s.groups[0]
    let s.end    = s.start + len(s.str)
    return s
endfun "}}}

" Decide if one thing is clickable and highlight it
" when moving our cursor (Cursormoved)
" And will execute when relevent action triggered (Click)


" {fold_closed: {
"   action:  Fn(),
"   highlight: Fn(),
"   fallback: Fn(),
"   trigger_ptn: Fn(),
"   trigger_env: Fn(),
" }
" }
fun! s:hi_nop()
   2match none
endfun

let s:src = {
        \ 'fold_closed': {
        \   'action': function("s:open_fold"),
        \   'highlight': function("s:hi_nop"),
        \   'check': function("s:is_fold_closed")
        \   },
        \ }

let s:map ={
        \ '<C-CR>': { 
        \ 'default': 'kJ',
        \  },
        \ }

fun! clickable#hi_cursor() "{{{
    " Check if current pos is clickable.
    " Highlight it and make it clickable.
    
    let [row,col] = getpos('.')[1:2]
    let line = getline(row)

    if s:src.fold_closed.check()
        let s:is_clickable = 'fold_closed'
        call s:src.fold_closed.highlight()
        return
    endif

    if s:is_fold_firstline()
        let s:is_clickable = 'fold_firstline'
        2match none
        return
    endif

    " if cursor is still in prev hl region , skip
    if s:in_hl_region(row, col) | return | endif

    let [s:hl_row, s:hl_bgn,s:hl_end] = [row, 0 , 0]
    
    " >>> let line = " this is a test of file://www.2342323.com"
    " >>> let col = 15
    " >>> let idx = clickable#get_WORD_bgn(line, col)
    " >>> let obj = s:match_object(line, s:link_uri, idx)
    " >>> echo obj.start obj.end
    " 19 41
    let idx = clickable#get_WORD_bgn(line, col)
    let obj = s:match_object(line, s:link_uri, idx)

    if !empty(obj) && obj.start < col && col <= obj.end + 1
        let s:is_clickable = 'link'
        let s:click_text = obj.str

        let bgn = obj.start + 1
        let end = obj.end
        let [s:hl_row, s:hl_bgn, s:hl_end] = [row, bgn, end]


        execute '2match' "IncSearch".' /\%'.(row)
                    \.'l\%>'.(bgn-1) .'c\%<'.(end+1).'c/'
        return
    endif

    " >>> let line = " this is a test file ~/tet/test.txt) joifej"
    " >>> let col = 15
    " >>> let idx = clickable#get_WORD_bgn(line, col)
    " >>> let obj = s:match_object(line, s:link_file, idx)
    " >>> echo obj.start obj.end
    " 21 35
    let obj = s:match_object(line, s:link_file, idx)
    if !empty(obj) && obj.start < col && col <= obj.end + 1
        let bgn = obj.start + 1
        let end = obj.end
        let [s:hl_row, s:hl_bgn, s:hl_end] = [row, bgn, end]
        let s:click_text = expand(obj.str)

        if isdirectory(s:click_text) || filereadable(s:click_text) 
            let s:is_clickable = 'file_exists'
            execute '2match' "IncSearch".' /\%'.(row)
                        \.'l\%>'.(bgn-1) .'c\%<'.(end+1).'c/'
        else
            let s:is_clickable = 'file_nonexists'
            execute '2match' "ErrorMsg".' /\%'.(row)
                        \.'l\%>'.(bgn-1) .'c\%<'.(end+1).'c/'
        endif
        return
    endif

    let s:is_clickable = ''
    2match none
endfun "}}}

fun! clickable#do(action) "{{{

    " open folding if in a folded line
    if s:is_clickable == 'fold_closed'
        call s:src.fold_closed.action()
        return
    endif

    " close fold if on the marker line
    if s:is_clickable == 'fold_firstline'
        call s:close_fold() | return
    endif

    " open link if it's a link!
    if s:is_clickable == 'link'
        if s:click_text =~ '\v'.s:link_mail
            let s:click_text = 'mailto:' . s:click_text
        endif
        call s:open_link(s:click_text) | return
    endif

    " Open file or Open with Ctrl
    if s:is_clickable == 'file_exists' || ( s:is_clickable == 'file_nonexists' && a:action =~? '<c-\|-c-\|Ctrl')
        " Split with Shift
        if a:action =~? '<s-\|-s-\|Shift' | split | endif
        call s:open_file(s:click_text) | return
    elseif s:is_clickable == 'file_nonexists' && g:clickable_confirm_creation == 1
        if input("'".s:click_text."' is not exists, create it? (yes/no):") == "yes"
            call s:auto_mkdir(s:click_text)
            call s:open_file(s:click_text) 
        endif
        return
    endif 

    " Nothing Clickable  Do origin Action
    " NOTE: 
    " Combine string to get string constant like "\<CR>"
    " Must use double quoting.  ~/bin/
    " >>> echo  substitute('[efe]', '\[\([-0-9a-zA-Z]\+\)\]','<\1>','g')
    " <efe>
    let m_action = substitute(a:action, '\[\([-0-9a-zA-Z]\+\)\]','<\1>','g')
    if has_key(s:map, m_action) && has_key(s:map[m_action], 'default')
        let default_act = s:map[m_action]['default']
        if type(default_act) == 2
            call default_act()
            return
        endif
        let action = default_act
    else
        let action = a:action
    endif
    let action = substitute(action, '\[\([-0-9a-zA-Z]\+\)\]','\\<\1>','g')
    exe 'exe "norm! '.action.'"'

endfun "}}}

