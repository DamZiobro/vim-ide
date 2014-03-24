" ============================================================================
" File:        protodef.vim
"
" Description: Vim global plugin that updates a CPP implementation file with 
"              concrete definitions of prototypes declared in a header file.
"
" Maintainer:  Derek Wyatt <derek at myfirstnamemylastname dot org>
"
" Last Change: Oct 12 2010
"
" License:     The VIM LICENSE applies to fswitch.vim, and fswitch.txt
" 	           (see |copyright|) except use "protodef" instead of "Vim".
" 	           No warranty, express or implied.
" 	           Use At-Your-Own-Risk!
"
" Version:     0.9.5
" ============================================================================

if exists("g:disable_protodef")
    finish
endif

if v:version < 700
  echoerr "Protodef requires Vim 7.0 or higher!"
  finish
endif

" =======================
" Configuration variables
" =======================

" The full path to the ctags executable
if !exists('g:protodefctagsexe')
    let g:protodefctagsexe = 'ctags'
endif

" The flags we're using for ctags.  I wouldn't change these if I were you - the
" code depends on the output of ctags and if you change these, the code's
" probably going to throw up all kinds of interesting errors.
let g:protodef_ctags_flags = '--language-force=c++ --c++-kinds=+p-cdefglmnstuvx --fields=nsm -o -'

" The path to the pullproto.pl script that's included as part of protodef
if !exists('g:protodefprotogetter')
    let g:protodefprotogetter = substitute($VIM, '\\', '/', 'g') . '/pullproto.pl'
endif

" This is a simple dictionary of default values that are set up for various data
" types.  It's not meant to be exhaustive or anything like that, but just a decent
" set of hints for return values.  Chances are it will never actually be "correct"
" for a real function - you'll always change the default to something else.
if !exists('g:protodefvaluedefaults')
    let g:protodefvaluedefaults = 
                \ {
                \     'int'                  : '0',
                \     'unsigned int'         : '0',
                \     'const int'            : '0',
                \     'const unsigned int'   : '0',
                \     'long'                 : '0',
                \     'unsigned long'        : '0',
                \     'const long'           : '0',
                \     'const unsigned long'  : '0',
                \     'short'                : '0',
                \     'unsigned short'       : '0',
                \     'const short'          : '0',
                \     'const unsigned short' : '0',
                \     'char'                 : "'a'",
                \     'unsigned char'        : "'a'",
                \     'const char'           : "'a'",
                \     'const unsigned char'  : "'a'",
                \     'bool'                 : 'true',
                \     'const bool'           : 'true'
                \ }
endif

"
" s:PrototypeSortCompare()
" 
" This is a basic stab at trying to order prototypes by putting ctors and
" dtors first, free functions at the bottom and all of the other stuff
" in the middle.
"
function! s:PrototypeSortCompare(i1, i2)
    let ret = -1
    if a:i1 == a:i2
        let ret = 0
    elseif a:i1 =~ '^\(.*\)::\1'
        let ret = -1
    elseif a:i1 =~ '^\(.*\)::\~\1'
        if a:i2 =~ '^\(.*\)::\1'
            let ret = 1
        else
            let ret = -1
        endif
    elseif a:i2 =~ '^\(.*\)::\1'
        let ret = 1
    elseif a:i2 =~ '^\(.*\)::\~\1'
        if a:i1 =~ '^\(.*\)::\1'
            let ret = -1
        else
            let ret = 1
        endif
    elseif a:i1 =~ '.*::.*' && a:i2 !~ '.*::.*'
        let ret = -1
    elseif a:i1 !~ '.*::.*' && a:i2 =~ '.*::.*'
        let ret = 1
    elseif a:i1 > a:i2
        let ret = 1
    endif

    return ret
endfunction

"
" s:GetFunctionPrototypesForCurrentBuffer()
"
" This function calls ctags to get the list of prototypes from the header file
" and then uses the pullproto.pl script to pull the full prototype values from
" the header file (as ctags doesn't actually have all the data we need).  The
" prototypes are then returned in an array in the same format as they appear
" in the header file.
" 
function! s:GetFunctionPrototypesForCurrentBuffer(opts)
    " FSReturnReadableCompanionFilename() is in the fswitch.vim plugin
    let companion = FSReturnReadableCompanionFilename('%')
    let includeNS = 1
    if has_key(a:opts, 'includeNS')
        let includeNS = a:opts['includeNS']
    endif
    if companion != ''
        " Get the data from ctags
        let ctagsoutput = system(g:protodefctagsexe . ' ' . g:protodef_ctags_flags . ' ' . companion)
        if ctagsoutput == ''
            return []
        endif
        let lines = split(ctagsoutput, "\n")
        let ret = []
        let commands = []
        for line in lines
            " Get rid of the regular expression that ctags has given us as
            " we don't need it and it merely causes problems if there is a
            " tab in the prototype at all
            let line = substitute(line, '/\^.\{-}\$/;', 'removed', '')
            let parts = split(line, "\t")
            let fname = parts[0]
            let linenum = matchstr(parts[3], ':\zs.*\ze')
            let class = ''
            let implementation = ''
            if len(parts) > 4
                let part4 = matchstr(parts[4], '\zs[^:]*\ze:')
                if part4 == 'class'
                    let class = matchstr(parts[4], 'class:\zs.*\ze')
                    if includeNS == 0
                        let class = substitute(class, '^.*::', '', '')
                    endif
                elseif part4 == 'implementation'
                    let implementation = matchstr(parts[4], 'implementation:\zs.*\ze')
                endif
            endif
            if len(parts) > 5
                let part5 = matchstr(parts[5], '\zs.*\ze:')
                if part5 == 'implementation'
                    let implementation = matchstr(parts[5], 'implementation:\zs.*\ze')
                endif
            endif
            if implementation !=# 'pure virtual'
                call add(commands, linenum . '|' . fname . '|' . class)
            endif
        endfor
        " Make the call to the pullproto.pl script to get the full prototype
        " from the header file
        let protos = system(g:protodefprotogetter . " " . companion, join(commands, "\n"))
        " pullproto.pl separates the prototypes by '==' on its own line so
        " we'll split by that
        let ret = split(protos, "==\n")
        " We need to get rid of the newlines at the end of the each of
        " the prototypes
        call map(ret, 'substitute(v:val, "\n$", "", "")')
        " Make a stab at sorting the prototypes a bit by trying to put the
        " constructors and destructors at the top with free functions at the
        " bottom - everything else goes in between these bits.
        if !exists('g:disable_protodef_sorting')
            let ret = sort(ret, "s:PrototypeSortCompare")
        endif
        return ret
    endif

    return []
endfunction

"
" protodef#ReturnSkeletonsFromPrototypesForCurrentBuffer()
"
" This is the real "public" function that can be used to return a string that
" contains all of the prototypes turned into "real" functions.
"
function! protodef#ReturnSkeletonsFromPrototypesForCurrentBuffer(opts)
    " Get the prototypes from the header file
    let protos = s:GetFunctionPrototypesForCurrentBuffer(a:opts)
    let full = []
	let companion = FSReturnReadableCompanionFilename('%')
	let header_contents = ''
	for line in readfile(companion)
		let header_contents .= line
	endfor
    for proto in protos
        " Clean out the default arguments as these don't belong in the implementation file
        let proto = substitute(proto, '\n', '', 'g') " remove space at the beginning
        let functionName = matchstr(proto, '::[A-za-z]*(') " get name of class 
        let functionName = substitute(functionName,'^::','','')
        let functionName = substitute(functionName,'($','','')
        let className = matchstr(proto, '\s[A-za-z]*::') " get name of Function 
        let className = substitute(className,'::$','','')
        let params = matchstr(proto, '(\_.*$')
        let params = substitute(params, '^(', '', '') " XXX batz added to strip the leading (
        let tail   = matchstr(params, ')[^)]*$') " XXX bats added to strip the trail )...
        let params = substitute(params, ')[^)]*$', '', '')
        let params = substitute(params, '\s*=\s*[^,]\+', '', 'g') " XXX batz deleted the reliance on ) in the char class
        let params = escape(params, '~*&\\')
        let proto = substitute(proto, '(\_.*$', '(' . params . tail, '') " XXX batz changed to replace the parens/tail stripped off
        " Set up the search expression so that we can check to see if what we're going to
        " put into the buffer is already there or not
        let protosearch = escape(proto, '~*')
        " put optional spaces around word boundaries
        let protosearch = substitute(protosearch, '\<\(.\{-}\)\>', '\\_s*\1\\_s*', 'g')
        " convert explicit whitspace to optional whitespace
        let protosearch = substitute(protosearch, '\_s', '\\_s*', 'g')
        " there are probably tons of repeated \_s* directives in the regex, which is going
        " to kill the VIM regex engine so we'll squeeze these together
        let protosearch = substitute(protosearch, '\%\(\\_s\*\)\+', '\\_s*', 'g')
        " Now let's do the check to see if the prototype is already in the buffer
        if search(protosearch, 'nw') == 0 && match(header_contents, protosearch) == -1
            " it's not so start creating the entry
            call add(full, "\/* ======= Function ==================================================")
            call add(full, " *   Name:".className."::".functionName)
            call add(full, " *   Description:")
            call add(full, " * ===================================================================")
            call add(full, " *\/")
            call add(full, proto)
            call add(full, "{")
            " Does this prototype have a return type?
            if proto =~ '^\S\+\_s\+.*('
                " Play a bit of a dodgy game to try and put something
                " reasonable in for the return value
                let rettype = matchstr(proto, '^.\{-}\ze\s\+\S\+(')
                if has_key(g:protodefvaluedefaults, rettype)
                    call add(full, "    return " . g:protodefvaluedefaults[rettype] . ';')
                elseif rettype =~ '\*'
                    call add(full, "    return 0; // null")
                elseif rettype =~ '&'
                    let type = matchstr(rettype, '\(\S\+\)\ze\s*&')
                    call add(full, "    return " . type . '();')
                elseif rettype != 'void'
                    call add(full, "    return /* something */;")
                endif
            endif
            " finish it off
            call add(full, "}")
            call add(full, "")
        endif
    endfor
    " Join up the result into a single string
    return join(full, "\n")
endfunction

"
" s:MakeMapping()
"
" Simply maps the appropriate key to run the
" ReturnSkeletonsFromPrototypesForCurrentBuffer() function.
"
function! protodef#MakeMapping()
    if !exists('g:disable_protodef_mapping')
        nmap <buffer> <silent> <leader>PP :set paste<cr>i<c-r>=protodef#ReturnSkeletonsFromPrototypesForCurrentBuffer({})<cr><esc>='[:set nopaste<cr>
        nmap <buffer> <silent> <leader>PN :set paste<cr>i<c-r>=protodef#ReturnSkeletonsFromPrototypesForCurrentBuffer({'includeNS' : 0})<cr><esc>='[:set nopaste<cr>
    endif
endfunction

augroup protodef_cpp_mapping
    au! BufEnter *.cpp,*.C,*.cxx,*.cc,*.CC call protodef#MakeMapping()
augroup END

