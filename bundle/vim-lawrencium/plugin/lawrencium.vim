" lawrencium.vim - A Mercurial wrapper
" Maintainer:   Ludovic Chabant <http://ludovic.chabant.com>
" Version:      0.3.1

" Globals {{{

if !exists('g:lawrencium_debug')
    let g:lawrencium_debug = 0
endif

if (exists('g:loaded_lawrencium') || &cp) && !g:lawrencium_debug
    finish
endif
if (exists('g:loaded_lawrencium') && g:lawrencium_debug)
    echom "Reloaded Lawrencium."
endif
let g:loaded_lawrencium = 1

if !exists('g:lawrencium_hg_executable')
    let g:lawrencium_hg_executable = 'hg'
endif

if !exists('g:lawrencium_auto_cd')
    let g:lawrencium_auto_cd = 1
endif

if !exists('g:lawrencium_trace')
    let g:lawrencium_trace = 0
endif

if !exists('g:lawrencium_define_mappings')
    let g:lawrencium_define_mappings = 1
endif

if !exists('g:lawrencium_auto_close_buffers')
    let g:lawrencium_auto_close_buffers = 1
endif

if !exists('g:lawrencium_annotate_width_offset')
    let g:lawrencium_annotate_width_offset = 0
endif

if !exists('g:lawrencium_status_win_split_above')
    let g:lawrencium_status_win_split_above = 0
endif

if !exists('g:lawrencium_status_win_split_even')
    let g:lawrencium_status_win_split_even = 0
endif

if !exists('g:lawrencium_record_start_in_working_buffer')
    let g:lawrencium_record_start_in_working_buffer = 0
endif

" }}}

" Utility {{{

" Strips the ending slash in a path.
function! s:stripslash(path)
    return fnamemodify(a:path, ':s?[/\\]$??')
endfunction

" Surrounds the given string with double quotes.
function! s:addquotes(str)
    return '"' . a:str . '"'
endfunction

" Returns whether a path is absolute.
function! s:isabspath(path)
    return a:path =~# '\v^(\w\:)?[/\\]'
endfunction

" Normalizes the slashes in a path.
function! s:normalizepath(path)
    if exists('+shellslash') && &shellslash
        return substitute(a:path, '\v/', '\\', 'g')
    elseif has('win32')
        return substitute(a:path, '\v/', '\\', 'g')
    else
        return a:path
    endif
endfunction

" Shell-slashes the path (opposite of `normalizepath`).
function! s:shellslash(path)
  if exists('+shellslash') && !&shellslash
    return substitute(a:path, '\v\\', '/', 'g')
  else
    return a:path
  endif
endfunction

" Like tempname() but with some control over the filename.
function! s:tempname(name, ...)
    let l:path = tempname()
    let l:result = fnamemodify(l:path, ':h') . '/' . a:name . fnamemodify(l:path, ':t')
    if a:0 > 0
        let l:result = l:result . a:1
    endif
    return l:result
endfunction

" Delete a temporary file if it exists.
function! s:clean_tempfile(path)
    if filewritable(a:path)
        call s:trace("Cleaning up temporary file: " . a:path)
        call delete(a:path)
    endif
endfunction

" Prints a message if debug tracing is enabled.
function! s:trace(message, ...)
   if g:lawrencium_trace || (a:0 && a:1)
       let l:message = "lawrencium: " . a:message
       echom l:message
   endif
endfunction

" Prints an error message with 'lawrencium error' prefixed to it.
function! s:error(message)
    echom "lawrencium error: " . a:message
endfunction

" Throw a Lawrencium exception message.
function! s:throw(message)
    let v:errmsg = "lawrencium: " . a:message
    throw v:errmsg
endfunction

" Finds the repository root given a path inside that repository.
" Throw an error if not repository is found.
function! s:find_repo_root(path)
    let l:path = s:stripslash(a:path)
    let l:previous_path = ""
    while l:path != l:previous_path
        if isdirectory(l:path . '/.hg/store')
            return s:normalizepath(simplify(fnamemodify(l:path, ':p')))
        endif
        let l:previous_path = l:path
        let l:path = fnamemodify(l:path, ':h')
    endwhile
    call s:throw("No Mercurial repository found above: " . a:path)
endfunction

" Given a Lawrencium path (e.g: 'lawrencium:///repo/root_dir//foo/bar/file.py//rev=34'), extract
" the repository root, relative file path and revision number/changeset ID.
"
" If a second argument exists, it must be:
" - `relative`: to make the file path relative to the repository root.
" - `absolute`: to make the file path absolute.
"
function! s:parse_lawrencium_path(lawrencium_path, ...)
    let l:repo_path = s:shellslash(a:lawrencium_path)
    let l:repo_path = substitute(l:repo_path, '\\ ', ' ', 'g')
    if l:repo_path =~? '\v^lawrencium://'
        let l:repo_path = strpart(l:repo_path, strlen('lawrencium://'))
    endif

    let l:root_dir = ''
    let l:at_idx = stridx(l:repo_path, '//')
    if l:at_idx >= 0
        let l:root_dir = strpart(l:repo_path, 0, l:at_idx)
        let l:repo_path = strpart(l:repo_path, l:at_idx + 2)
    endif

    let l:value = ''
    let l:action = ''
    let l:actionidx = stridx(l:repo_path, '//')
    if l:actionidx >= 0
        let l:action = strpart(l:repo_path, l:actionidx + 2)
        let l:repo_path = strpart(l:repo_path, 0, l:actionidx)

        let l:equalidx = stridx(l:action, '=')
        if l:equalidx >= 0
            let l:value = strpart(l:action, l:equalidx + 1)
            let l:action = strpart(l:action, 0, l:equalidx)
        endif
    endif

    if a:0 > 0
        execute 'cd! ' . l:root_dir
        if a:1 == 'relative'
            let l:repo_path = fnamemodify(l:repo_path, ':.')
        elseif a:1 == 'absolute'
            let l:repo_path = fnamemodify(l:repo_path, ':p')
        endif
        execute 'cd! -'
    endif
    
    let l:result = { 'root': l:root_dir, 'path': l:repo_path, 'action': l:action, 'value': l:value }
    return l:result
endfunction

" Finds a window whose displayed buffer has a given variable
" set to the given value.
function! s:find_buffer_window(varname, varvalue) abort
    for wnr in range(1, winnr('$'))
        let l:bnr = winbufnr(wnr)
        if getbufvar(l:bnr, a:varname) == a:varvalue
            return l:wnr
        endif
    endfor
    return -1
endfunction

" Opens a buffer in a way that makes it easy to delete it later:
" - if the about-to-be previous buffer doesn't have a given variable,
"   just open the new buffer.
" - if the about-to-be previous buffer has a given variable, open the
"   new buffer with the `keepalt` option to make it so that the
"   actual previous buffer (returned by things like `bufname('#')`)
"   is the original buffer that was there before the first deletable
"   buffer was opened.
function! s:edit_deletable_buffer(varname, varvalue, path) abort
    let l:edit_cmd = 'edit '
    if getbufvar('%', a:varname) != ''
        let l:edit_cmd = 'keepalt edit '
    endif
    execute l:edit_cmd . fnameescape(a:path)
    call setbufvar('%', a:varname, a:varvalue)
endfunction

" Deletes all buffers that have a given variable set to a given value.
" For each buffer, if it is not shown in any window, it will be just deleted.
" If it is shown in a window, that window will be switched to the alternate
" buffer before the buffer is deleted, unless the `lawrencium_quit_on_delete`
" variable is set to `1`, in which case the window is closed too.
function! s:delete_dependency_buffers(varname, varvalue) abort
    let l:cur_winnr = winnr()
    for bnr in range(1, bufnr('$'))
        if getbufvar(bnr, a:varname) == a:varvalue
            " Delete this buffer if it is not shown in any window.
            " Otherwise, display the alternate buffer before deleting
            " it so the window is not closed.
            let l:bwnr = bufwinnr(bnr)
            if l:bwnr < 0 || getbufvar(bnr, 'lawrencium_quit_on_delete') == 1
                if bufloaded(l:bnr)
                    call s:trace("Deleting dependency buffer " . bnr)
                    execute "bdelete! " . bnr
                else
                    call s:trace("Dependency buffer " . bnr . " is already unladed.")
                endif
            else
                execute l:bwnr . "wincmd w"
                " TODO: better handle case where there's no previous/alternate buffer?
                let l:prev_bnr = bufnr('#')
                if l:prev_bnr > 0 && bufloaded(l:prev_bnr)
                    execute "buffer " . l:prev_bnr
                    if bufloaded(l:bnr)
                        call s:trace("Deleting dependency buffer " . bnr . " after switching to " . l:prev_bnr . " in window " . l:bwnr)
                        execute "bdelete! " . bnr
                    else
                        call s:trace("Dependency buffer " . bnr . " is unladed after switching to " . l:prev_bnr)
                    endif
                else
                    call s:trace("Deleting dependency buffer " . bnr . " and window.")
                    bdelete!
                endif
            endif
        endif
    endfor
    if l:cur_winnr != winnr()
        call s:trace("Returning to window " . l:cur_winnr)
        execute l:cur_winnr . "wincmd w"
    endif
endfunction

" Clean up all the 'HG:' lines from a commit message, and see if there's
" any message left (Mercurial does this automatically, usually, but
" apparently not when you feed it a log file...).
function! s:clean_commit_file(log_file) abort
    let l:lines = readfile(a:log_file)
    call filter(l:lines, "v:val !~# '\\v^HG:'")
    if len(filter(copy(l:lines), "v:val !~# '\\v^\\s*$'")) == 0
        return 0
    endif
    call writefile(l:lines, a:log_file)
    return 1
endfunction

" }}}

" Mercurial Repository Object {{{

" Let's define a Mercurial repo 'class' using prototype-based object-oriented
" programming.
"
" The prototype dictionary.
let s:HgRepo = {}

" Constructor.
function! s:HgRepo.New(path) abort
    let l:newRepo = copy(self)
    let l:newRepo.root_dir = s:find_repo_root(a:path)
    call s:trace("Built new Mercurial repository object at : " . l:newRepo.root_dir)
    return l:newRepo
endfunction

" Gets a full path given a repo-relative path.
function! s:HgRepo.GetFullPath(path) abort
    let l:root_dir = self.root_dir
    if s:isabspath(a:path)
        call s:throw("Expected relative path, got absolute path: " . a:path)
    endif
    return s:normalizepath(l:root_dir . a:path)
endfunction

" Gets a repo-relative path given any path.
function! s:HgRepo.GetRelativePath(path) abort
    execute 'lcd! ' . self.root_dir
    let l:relative_path = fnamemodify(a:path, ':.')
    execute 'lcd! -'
    return l:relative_path
endfunction

" Gets, and optionally creates, a temp folder for some operation in the `.hg`
" directory.
function! s:HgRepo.GetTempDir(path, ...) abort
    let l:tmp_dir = self.GetFullPath('.hg/lawrencium/' . a:path)
    if !isdirectory(l:tmp_dir)
        if a:0 > 0 && !a:1
            return ''
        endif
        call mkdir(l:tmp_dir, 'p')
    endif
    return l:tmp_dir
endfunction

" Gets a list of files matching a root-relative pattern.
" If a flag is passed and is TRUE, a slash will be appended to all
" directories.
function! s:HgRepo.Glob(pattern, ...) abort
    let l:root_dir = self.root_dir
    if (a:pattern =~# '\v^[/\\]')
        let l:root_dir = s:stripslash(l:root_dir)
    endif
    let l:matches = split(glob(l:root_dir . a:pattern), '\n')
    if a:0 && a:1
        for l:idx in range(len(l:matches))
            if !filereadable(l:matches[l:idx])
                let l:matches[l:idx] = l:matches[l:idx] . '/'
            endif
        endfor
    endif
    let l:strip_len = len(l:root_dir)
    call map(l:matches, 'v:val[l:strip_len : -1]')
    return l:matches
endfunction

" Gets a full Mercurial command.
function! s:HgRepo.GetCommand(command, ...) abort
    " If there's only one argument, and it's a list, then use that as the
    " argument list.
    let l:arg_list = a:000
    if a:0 == 1 && type(a:1) == type([])
        let l:arg_list = a:1
    endif
    let l:hg_command = g:lawrencium_hg_executable . ' --repository ' . shellescape(s:stripslash(self.root_dir))
    let l:hg_command = l:hg_command . ' ' . a:command
    for l:arg in l:arg_list
        if stridx(l:arg, ' ') >= 0
            let l:hg_command = l:hg_command . ' "' . l:arg . '"'
        else
            let l:hg_command = l:hg_command . ' ' . l:arg
        endif
    endfor
    return l:hg_command
endfunction

" Runs a Mercurial command in the repo.
function! s:HgRepo.RunCommand(command, ...) abort
    let l:all_args = [a:command] + a:000
    let l:hg_command = call(self['GetCommand'], l:all_args, self)
    call s:trace("Running Mercurial command: " . l:hg_command)
    return system(l:hg_command)
endfunction

" Runs a Mercurial command in the repo and reads its output into the current
" buffer.
function! s:HgRepo.ReadCommandOutput(command, ...) abort
    function! s:PutOutputIntoBuffer(command_line)
        let l:was_buffer_empty = (line('$') == 1 && getline(1) == '')
        execute '0read!' . escape(a:command_line, '%#\')
        if l:was_buffer_empty  " (Always true?)
            " '0read' inserts before the cursor, leaving a blank line which
            " needs to be deleted... but if there are folds in this thing, we
            " must open them all first otherwise we could delete the whole
            " contents of the last fold (since Vim may close them all by
            " default).
            normal! zRGdd
        endif
    endfunction

    let l:all_args = [a:command] + a:000
    let l:hg_command = call(self['GetCommand'], l:all_args, self)
    call s:trace("Running Mercurial command: " . l:hg_command)
    call s:PutOutputIntoBuffer(l:hg_command)
endfunction

" Build a Lawrencium path for the given file and action.
" By default, the given path will be made relative to the repository root,
" unless '0' is passed as the 4th argument.
function! s:HgRepo.GetLawrenciumPath(path, action, value, ...) abort
    let l:path = a:path
    if a:0 == 0 || !a:1
        let l:path = self.GetRelativePath(a:path)
    endif
    let l:path = fnameescape(l:path)
    let l:result = 'lawrencium://' . s:stripslash(self.root_dir) . '//' . l:path
    if a:action !=? ''
        let l:result  = l:result . '//' . a:action
        if a:value !=? ''
            let l:result = l:result . '=' . a:value
        endif
    endif
    return l:result
endfunction

" Repo cache map.
let s:buffer_repos = {}

" Get a cached repo.
function! s:hg_repo(...) abort
    " Use the given path, or the mercurial directory of the current buffer.
    if a:0 == 0
        if exists('b:mercurial_dir')
            let l:path = b:mercurial_dir
        else
            let l:path = s:find_repo_root(expand('%:p'))
        endif
    else
        let l:path = a:1
    endif
    " Find a cache repo instance, or make a new one.
    if has_key(s:buffer_repos, l:path)
        return get(s:buffer_repos, l:path)
    else
        let l:repo = s:HgRepo.New(l:path)
        let s:buffer_repos[l:path] = l:repo
        return l:repo
    endif
endfunction

" Sets up the current buffer with Lawrencium commands if it contains a file from a Mercurial repo.
" If the file is not in a Mercurial repo, just exit silently.
function! s:setup_buffer_commands() abort
    call s:trace("Scanning buffer '" . bufname('%') . "' for Lawrencium setup...")
    let l:do_setup = 1
    if exists('b:mercurial_dir')
        if b:mercurial_dir =~# '\v^\s*$'
            unlet b:mercurial_dir
        else
            let l:do_setup = 0
        endif
    endif
    try
        let l:repo = s:hg_repo()
    catch /^lawrencium\:/
        return
    endtry
    let b:mercurial_dir = l:repo.root_dir
    if exists('b:mercurial_dir') && l:do_setup
        call s:trace("Setting Mercurial commands for buffer '" . bufname('%'))
        call s:trace("  with repo : " . expand(b:mercurial_dir))
        silent doautocmd User Lawrencium
    endif
endfunction

augroup lawrencium_detect
    autocmd!
    autocmd BufNewFile,BufReadPost *     call s:setup_buffer_commands()
    autocmd VimEnter               *     if expand('<amatch>')==''|call s:setup_buffer_commands()|endif
augroup end

" }}}

" Buffer Object {{{

" The prototype dictionary.
let s:Buffer = {}

" Constructor.
function! s:Buffer.New(number) dict abort
    let l:newBuffer = copy(self)
    let l:newBuffer.nr = a:number
    let l:newBuffer.var_backup = {}
    let l:newBuffer.cmd_names = {}
    let l:newBuffer.on_delete = []
    let l:newBuffer.on_winleave = []
    let l:newBuffer.on_unload = []
    execute 'augroup lawrencium_buffer_' . a:number
    execute '  autocmd!'
    execute '  autocmd BufDelete <buffer=' . a:number . '> call s:buffer_on_delete(' . a:number . ')'
    execute 'augroup end'
    call s:trace("Built new buffer object for buffer: " . a:number)
    return l:newBuffer
endfunction

function! s:Buffer.GetName(...) dict abort
    let l:name = bufname(self.nr)
    if a:0 > 0
        let l:name = fnamemodify(l:name, a:1)
    endif
    return l:name
endfunction

function! s:Buffer.GetVar(var) dict abort
    return getbufvar(self.nr, a:var)
endfunction

function! s:Buffer.SetVar(var, value) dict abort
    if !has_key(self.var_backup, a:var)
        let self.var_backup[a:var] = getbufvar(self.nr, a:var)
    endif
    return setbufvar(self.nr, a:var, a:value)
endfunction

function! s:Buffer.RestoreVars() dict abort
    for key in keys(self.var_backup)
        setbufvar(self.nr, key, self.var_backup[key])
    endfor
endfunction

function! s:Buffer.DefineCommand(name, ...) dict abort
    if a:0 == 0
        call s:throw("Not enough parameters for s:Buffer.DefineCommands()")
    endif
    if a:0 == 1
        let l:flags = ''
        let l:cmd = a:1
    else
        let l:flags = a:1
        let l:cmd = a:2
    endif
    if has_key(self.cmd_names, a:name)
        call s:throw("Command '".a:name."' is already defined in buffer ".self.nr)
    endif
    if bufnr('%') != self.nr
        call s:throw("You must move to buffer ".self.nr."first before defining local commands")
    endif
    let self.cmd_names[a:name] = 1
    let l:real_flags = ''
    if type(l:flags) == type('')
        let l:real_flags = l:flags
    endif
    execute 'command -buffer '.l:real_flags.' '.a:name.' '.l:cmd
endfunction

function! s:Buffer.DeleteCommand(name) dict abort
    if !has_key(self.cmd_names, a:name)
        call s:throw("Command '".a:name."' has not been defined in buffer ".self.nr)
    endif
    if bufnr('%') != self.nr
        call s:throw("You must move to buffer ".self.nr."first before deleting local commands")
    endif
    execute 'delcommand '.a:name
    call remove(self.cmd_names, a:name)
endfunction

function! s:Buffer.DeleteCommands() dict abort
    if bufnr('%') != self.nr
        call s:throw("You must move to buffer ".self.nr."first before deleting local commands")
    endif
    for name in keys(self.cmd_names)
        execute 'delcommand '.name
    endfor
    let self.cmd_names = {}
endfunction

function! s:Buffer.MoveToFirstWindow() dict abort
    let l:win_nr = bufwinnr(self.nr)
    if l:win_nr < 0
        if a:0 > 0 && a:1 == 0
            return 0
        endif
        call s:throw("No windows currently showing buffer ".self.nr)
    endif
    execute l:win_nr.'wincmd w'
    return 1
endfunction

function! s:Buffer.OnDelete(cmd) dict abort
    call s:trace("Adding BufDelete callback for buffer " . self.nr . ": " . a:cmd)
    call add(self.on_delete, a:cmd)
endfunction

function! s:Buffer.OnWinLeave(cmd) dict abort
    if len(self.on_winleave) == 0
        call s:trace("Adding BufWinLeave auto-command on buffer " . self.nr)
        execute 'augroup lawrencium_buffer_' . self.nr . '_winleave'
        execute '  autocmd!'
        execute '  autocmd BufWinLeave <buffer=' . self.nr . '> call s:buffer_on_winleave(' . self.nr .')'
        execute 'augroup end'
    endif
    call s:trace("Adding BufWinLeave callback for buffer " . self.nr . ": " . a:cmd)
    call add(self.on_winleave, a:cmd)
endfunction

function! s:Buffer.OnUnload(cmd) dict abort
    if len(self.on_unload) == 0
        call s:trace("Adding BufUnload auto-command on buffer " . self.nr)
        execute 'augroup lawrencium_buffer_' . self.nr . '_unload'
        execute '  autocmd!'
        execute '  autocmd BufUnload <buffer=' . self.nr . '> call s:buffer_on_unload(' . self.nr . ')'
        execute 'augroup end'
    endif
    call s:trace("Adding BufUnload callback for buffer " . self.nr . ": " . a:cmd)
    call add(self.on_unload, a:cmd)
endfunction

let s:buffer_objects = {}

" Get a buffer instance for the specified buffer number, or the
" current buffer if nothing is specified.
function! s:buffer_obj(...) abort
    let l:bufnr = a:0 ? a:1 : bufnr('%')
    if !has_key(s:buffer_objects, l:bufnr)
        let s:buffer_objects[l:bufnr] = s:Buffer.New(l:bufnr)
    endif
    return s:buffer_objects[l:bufnr]
endfunction

" Execute all the "on delete" callbacks.
function! s:buffer_on_delete(number) abort
    let l:bufobj = s:buffer_objects[a:number]
    call s:trace("Calling BufDelete callbacks on buffer " . l:bufobj.nr)
    for cmd in l:bufobj.on_delete
        call s:trace(" [" . cmd . "]")
        execute cmd
    endfor
    call s:trace("Deleted buffer object " . l:bufobj.nr)
    call remove(s:buffer_objects, l:bufobj.nr)
    execute 'augroup lawrencium_buffer_' . l:bufobj.nr
    execute '  autocmd!'
    execute 'augroup end'
endfunction

" Execute all the "on winleave" callbacks.
function! s:buffer_on_winleave(number) abort
    let l:bufobj = s:buffer_objects[a:number]
    call s:trace("Calling BufWinLeave callbacks on buffer " . l:bufobj.nr)
    for cmd in l:bufobj.on_winleave
        call s:trace(" [" . cmd . "]")
        execute cmd
    endfor
    execute 'augroup lawrencium_buffer_' . l:bufobj.nr . '_winleave'
    execute '  autocmd!'
    execute 'augroup end'
endfunction

" Execute all the "on unload" callbacks.
function! s:buffer_on_unload(number) abort
    let l:bufobj = s:buffer_objects[a:number]
    call s:trace("Calling BufUnload callbacks on buffer " . l:bufobj.nr)
    for cmd in l:bufobj.on_unload
        call s:trace(" [" . cmd . "]")
        execute cmd
    endfor
    execute 'augroup lawrencium_buffer_' . l:bufobj.nr . '_unload'
    execute '  autocmd!'
    execute 'augroup end'
endfunction

" }}}

" Lawrencium Files {{{

" Read revision (`hg cat`)
function! s:read_lawrencium_rev(repo, path_parts, full_path) abort
    let l:rev = a:path_parts['value']
    if l:rev == ''
        call a:repo.ReadCommandOutput('cat', a:full_path)
    else
        call a:repo.ReadCommandOutput('cat', '-r', s:addquotes(l:rev), a:full_path)
    endif
endfunction

" Status (`hg status`)
function! s:read_lawrencium_status(repo, path_parts, full_path) abort
    if a:path_parts['path'] == ''
        call a:repo.ReadCommandOutput('status')
    else
        call a:repo.ReadCommandOutput('status', a:full_path)
    endif
    setlocal nomodified
    setlocal filetype=hgstatus
    setlocal bufhidden=delete
    setlocal buftype=nofile
endfunction

" Log (`hg log`)
let s:log_style_file = expand("<sfile>:h:h") . "/resources/hg_log.style"

function! s:read_lawrencium_log(repo, path_parts, full_path) abort
    let l:log_opts = join(split(a:path_parts['value'], ','))
    let l:log_cmd = "log " . l:log_opts

    if a:path_parts['path'] == ''
        call a:repo.ReadCommandOutput(l:log_cmd, '--style', shellescape(s:log_style_file))
    else
        call a:repo.ReadCommandOutput(l:log_cmd, '--style', shellescape(s:log_style_file), a:full_path)
    endif
    setlocal filetype=hglog
endfunction

" Diff revisions (`hg diff`)
function! s:read_lawrencium_diff(repo, path_parts, full_path) abort
    let l:diffargs = []
    let l:commaidx = stridx(a:path_parts['value'], ',')
    if l:commaidx > 0
        let l:rev1 = strpart(a:path_parts['value'], 0, l:commaidx)
        let l:rev2 = strpart(a:path_parts['value'], l:commaidx + 1)
        if l:rev1 == '-'
            let l:diffargs = [ '-r', s:addquotes(l:rev2) ]
        elseif l:rev2 == '-'
            let l:diffargs = [ '-r', s:addquotes(l:rev1) ]
        else
            let l:diffargs = [ '-r', s:addquotes(l:rev1), '-r', s:addquotes(l:rev2) ]
        endif
    elseif a:path_parts['value'] != ''
        let l:diffargs = [ '-c', a:path_parts['value'] ]
    else
        let l:diffargs = []
    endif
    if a:path_parts['path'] != '' && a:path_parts['path'] != '.'
        call add(l:diffargs, a:full_path)
    endif
    call a:repo.ReadCommandOutput('diff', l:diffargs)
    setlocal filetype=diff
    setlocal nofoldenable
endfunction

" Annotate file
function! s:read_lawrencium_annotate(repo, path_parts, full_path) abort
    let l:cmd_args = ['-c', '-n', '-u', '-d', '-q']
    if a:path_parts['value'] == 'v=1'
        call insert(l:cmd_args, '-v', 0)
    endif
    call add(l:cmd_args, a:full_path)
    call a:repo.ReadCommandOutput('annotate', l:cmd_args)
endfunction

" MQ series
function! s:read_lawrencium_qseries(repo, path_parts, full_path) abort
    let l:names = split(a:repo.RunCommand('qseries'), '\n')
    let l:head = split(a:repo.RunCommand('qapplied', '-s'), '\n')
    let l:tail = split(a:repo.RunCommand('qunapplied', '-s'), '\n')

    let l:idx = 0
    let l:curbuffer = bufname('%')
    for line in l:head
        call setbufvar(l:curbuffer, 'lawrencium_patchname_' . (l:idx + 1), l:names[l:idx])
        call append(l:idx, "*" . line)
        let l:idx = l:idx + 1
    endfor
    for line in l:tail
        call setbufvar(l:curbuffer, 'lawrencium_patchname_' . (l:idx + 1), l:names[l:idx])
        call append(l:idx, line)
        let l:idx = l:idx + 1
    endfor
    call setbufvar(l:curbuffer, 'lawrencium_patchname_top', l:names[len(l:head) - 1])
    set filetype=hgqseries
endfunction

" Generic read
let s:lawrencium_file_readers = {
            \'rev': function('s:read_lawrencium_rev'),
            \'log': function('s:read_lawrencium_log'),
            \'diff': function('s:read_lawrencium_diff'),
            \'status': function('s:read_lawrencium_status'),
            \'annotate': function('s:read_lawrencium_annotate'),
            \'qseries': function('s:read_lawrencium_qseries')
            \}
let s:lawrencium_file_customoptions = {
            \'status': 1
            \}

function! s:ReadLawrenciumFile(path) abort
    call s:trace("Reading Lawrencium file: " . a:path)
    let l:path_parts = s:parse_lawrencium_path(a:path)
    if l:path_parts['root'] == ''
        call s:throw("Can't get repository root from: " . a:path)
    endif
    if !has_key(s:lawrencium_file_readers, l:path_parts['action'])
        call s:throw("No registered reader for action: " . l:path_parts['action'])
    endif

    " Call the registered reader.
    let l:repo = s:hg_repo(l:path_parts['root'])
    let l:full_path = l:repo.root_dir . l:path_parts['path']
    let LawrenciumFileReader = s:lawrencium_file_readers[l:path_parts['action']]
    call LawrenciumFileReader(l:repo, l:path_parts, l:full_path)

    " Setup the new buffer.
    if !has_key(s:lawrencium_file_customoptions, l:path_parts['action'])
        setlocal readonly
        setlocal nomodified
        setlocal bufhidden=delete
        setlocal buftype=nofile
    endif
    goto

    " Remember the real Lawrencium path, because Vim can fuck up the slashes
    " on Windows.
    let b:lawrencium_path = a:path

    " Remember the repo it belongs to and make
    " the Lawrencium commands available.
    let b:mercurial_dir = l:repo.root_dir
    call s:DefineMainCommands()

    return ''
endfunction

function! s:WriteLawrenciumFile(path) abort
    call s:trace("Writing Lawrencium file: " . a:path)
endfunction

augroup lawrencium_files
  autocmd!
  autocmd BufReadCmd  lawrencium://**//**//* exe s:ReadLawrenciumFile(expand('<amatch>'))
  autocmd BufWriteCmd lawrencium://**//**//* exe s:WriteLawrenciumFile(expand('<amatch>'))
augroup END

" }}}

" Buffer Commands Management {{{

" Store the commands for Lawrencium-enabled buffers so that we can add them in
" batch when we need to.
let s:main_commands = []

function! s:AddMainCommand(command) abort
    let s:main_commands += [a:command]
endfunction

function! s:DefineMainCommands()
    for l:command in s:main_commands
        execute 'command! -buffer ' . l:command
    endfor
endfunction

augroup lawrencium_main
    autocmd!
    autocmd User Lawrencium call s:DefineMainCommands()
augroup end

" }}}

" Commands Auto-Complete {{{

" Auto-complete function for commands that take repo-relative file paths.
function! s:ListRepoFiles(ArgLead, CmdLine, CursorPos) abort
    let l:matches = s:hg_repo().Glob(a:ArgLead . '*', 1)
    call map(l:matches, 's:normalizepath(v:val)')
    return l:matches
endfunction

" Auto-complete function for commands that take repo-relative directory paths.
function! s:ListRepoDirs(ArgLead, CmdLine, CursorPos) abort
    let l:matches = s:hg_repo().Glob(a:ArgLead . '*/')
    call map(l:matches, 's:normalizepath(v:val)')
    return l:matches
endfunction

" }}}

" Hg {{{

function! s:Hg(bang, ...) abort
    let l:repo = s:hg_repo()
    if g:lawrencium_auto_cd
        " Temporary set the current directory to the root of the repo
        " to make auto-completed paths work magically.
        execute 'cd! ' . l:repo.root_dir
    endif
    let l:output = call(l:repo.RunCommand, a:000, l:repo)
    if g:lawrencium_auto_cd
        execute 'cd! -'
    endif
    if a:bang
        " Open the output of the command in a temp file.
        let l:temp_file = s:tempname('hg-output-', '.txt')
        split
        execute 'edit ' . l:temp_file
        call append(0, split(l:output, '\n'))
        call cursor(1, 1)

        " Make it a temp buffer
        setlocal bufhidden=delete
        setlocal buftype=nofile

        " Try to find a nice syntax to set given the current command.
        let l:command_name = s:GetHgCommandName(a:000)
        if l:command_name != '' && exists('g:lawrencium_hg_commands_file_types')
            let l:file_type = get(g:lawrencium_hg_commands_file_types, l:command_name, '')
            if l:file_type != ''
                execute 'setlocal ft=' . l:file_type
            endif
        endif
    else
        " Just print out the output of the command.
        echo l:output
    endif
endfunction

" Include the generated HG usage file.
let s:usage_file = expand("<sfile>:h:h") . "/resources/hg_usage.vim"
if filereadable(s:usage_file)
    execute "source " . fnameescape(s:usage_file)
else
    call s:error("Can't find the Mercurial usage file. Auto-completion will be disabled in Lawrencium.")
endif

" Include the command file type mappings.
let s:file_type_mappings = expand("<sfile>:h:h") . '/resources/hg_command_file_types.vim'
if filereadable(s:file_type_mappings)
    execute "source " . fnameescape(s:file_type_mappings)
endif

function! s:CompleteHg(ArgLead, CmdLine, CursorPos)
    " Don't do anything if the usage file was not sourced.
    if !exists('g:lawrencium_hg_commands') || !exists('g:lawrencium_hg_options')
        return []
    endif

    " a:ArgLead seems to be the number 0 when completing a minus '-'.
    " Gotta find out why...
    let l:arglead = a:ArgLead
    if type(a:ArgLead) == type(0)
        let l:arglead = '-'
    endif

    " Try completing a global option, before any command name.
    if a:CmdLine =~# '\v^Hg(\s+\-[a-zA-Z0-9\-_]*)+$'
        return filter(copy(g:lawrencium_hg_options), "v:val[0:strlen(l:arglead)-1] ==# l:arglead")
    endif

    " Try completing a command (note that there could be global options before
    " the command name).
    if a:CmdLine =~# '\v^Hg\s+(\-[a-zA-Z0-9\-_]+\s+)*[a-zA-Z]+$'
        return filter(keys(g:lawrencium_hg_commands), "v:val[0:strlen(l:arglead)-1] ==# l:arglead")
    endif
    
    " Try completing a command's options.
    let l:cmd = matchstr(a:CmdLine, '\v(^Hg\s+(\-[a-zA-Z0-9\-_]+\s+)*)@<=[a-zA-Z]+')
    if strlen(l:cmd) > 0 && l:arglead[0] ==# '-'
        if has_key(g:lawrencium_hg_commands, l:cmd)
            " Return both command options and global options together.
            let l:copts = filter(copy(g:lawrencium_hg_commands[l:cmd]), "v:val[0:strlen(l:arglead)-1] ==# l:arglead")
            let l:gopts = filter(copy(g:lawrencium_hg_options), "v:val[0:strlen(l:arglead)-1] ==# l:arglead")
            return l:copts + l:gopts
        endif
    endif
    
    " Just auto-complete with filenames unless it's an option.
    if l:arglead[0] ==# '-'
        return []
    else
        return s:ListRepoFiles(a:ArgLead, a:CmdLine, a:CursorPos)
endfunction

function! s:GetHgCommandName(args) abort
    for l:a in a:args
        if stridx(l:a, '-') != 0
            return l:a
        endif
    endfor
    return ''
endfunction

call s:AddMainCommand("-bang -complete=customlist,s:CompleteHg -nargs=* Hg :call s:Hg(<bang>0, <f-args>)")

" }}}

" Hgstatus {{{

function! s:HgStatus() abort
    " Get the repo and the Lawrencium path for `hg status`.
    let l:repo = s:hg_repo()
    let l:status_path = l:repo.GetLawrenciumPath('', 'status', '')

    " Open the Lawrencium buffer in a new split window of the right size.
    if g:lawrencium_status_win_split_above
      execute "keepalt leftabove split " . l:status_path
    else
      execute "keepalt rightbelow split " . l:status_path
    endif
    
    if (line('$') == 1 && getline(1) == '')
        " Buffer is empty, which means there are not changes...
        " Quit and display a message.
        " TODO: figure out why the first `echom` doesn't show when alone.
        bdelete
        echom "Nothing was modified."
        echom ""
        return
    endif

    execute "setlocal winfixheight"
    if !g:lawrencium_status_win_split_even
      execute "setlocal winheight=" . (line('$') + 1)
      execute "resize " . (line('$') + 1)
    endif

    " Add some nice commands.
    command! -buffer          Hgstatusedit          :call s:HgStatus_FileEdit(0)
    command! -buffer          Hgstatusdiff          :call s:HgStatus_Diff(0)
    command! -buffer          Hgstatusvdiff         :call s:HgStatus_Diff(1)
    command! -buffer          Hgstatustabdiff       :call s:HgStatus_Diff(2)
    command! -buffer          Hgstatusdiffsum       :call s:HgStatus_DiffSummary(1)
    command! -buffer          Hgstatusvdiffsum      :call s:HgStatus_DiffSummary(2)
    command! -buffer          Hgstatustabdiffsum    :call s:HgStatus_DiffSummary(3)
    command! -buffer          Hgstatusrefresh       :call s:HgStatus_Refresh()
    command! -buffer -range   Hgstatusaddremove     :call s:HgStatus_AddRemove(<line1>, <line2>)
    command! -buffer -range=% -bang Hgstatuscommit  :call s:HgStatus_Commit(<line1>, <line2>, <bang>0, 0)
    command! -buffer -range=% -bang Hgstatusvcommit :call s:HgStatus_Commit(<line1>, <line2>, <bang>0, 1)
    command! -buffer -range=% -nargs=+ Hgstatusqnew :call s:HgStatus_QNew(<line1>, <line2>, <f-args>)
    command! -buffer -range=% Hgstatusqrefresh      :call s:HgStatus_QRefresh(<line1>, <line2>)

    " Add some handy mappings.
    if g:lawrencium_define_mappings
        nnoremap <buffer> <silent> <cr>  :Hgstatusedit<cr>
        nnoremap <buffer> <silent> <C-N> :call search('^[MARC\!\?I ]\s.', 'We')<cr>
        nnoremap <buffer> <silent> <C-P> :call search('^[MARC\!\?I ]\s.', 'Wbe')<cr>
        nnoremap <buffer> <silent> <C-D> :Hgstatustabdiff<cr>
        nnoremap <buffer> <silent> <C-V> :Hgstatusvdiff<cr>
        nnoremap <buffer> <silent> <C-U> :Hgstatusdiffsum<cr>
        nnoremap <buffer> <silent> <C-H> :Hgstatusvdiffsum<cr>
        nnoremap <buffer> <silent> <C-A> :Hgstatusaddremove<cr>
        nnoremap <buffer> <silent> <C-S> :Hgstatuscommit<cr>
        nnoremap <buffer> <silent> <C-R> :Hgstatusrefresh<cr>
        nnoremap <buffer> <silent> q     :bdelete!<cr>

        vnoremap <buffer> <silent> <C-A> :Hgstatusaddremove<cr>
        vnoremap <buffer> <silent> <C-S> :Hgstatuscommit<cr>
    endif
endfunction

function! s:HgStatus_Refresh(...) abort
    if a:0 > 0
        let l:win_nr = bufwinnr(a:1)
        call s:trace("Switching back to status window ".l:win_nr)
        if l:win_nr < 0
            call s:throw("Can't find the status window anymore!")
        endif
        execute l:win_nr . 'wincmd w'
        " Delete everything in the buffer, and re-read the status into it.
        " TODO: In theory I would only have to do `edit` like below when we're
        " already in the window, but for some reason Vim just goes bonkers and
        " weird shit happens. I have no idea why, hence the work-around here
        " to bypass the whole `BufReadCmd` auto-command altogether, and just
        " edit the buffer in place.
        normal! ggVGd
        call s:ReadLawrenciumFile(b:lawrencium_path)
        return
    endif

    " Just re-edit the buffer, it will reload the contents by calling
    " the matching Mercurial command.
    edit
endfunction

function! s:HgStatus_FileEdit(newtab) abort
    " Get the path of the file the cursor is on.
    let l:filename = s:HgStatus_GetSelectedFile()

    let l:cleanupbufnr = -1
    if a:newtab == 0
        " If the file is already open in a window, jump to that window.
        " Otherwise, jump to the previous window and open it there.
        for nr in range(1, winnr('$'))
            let l:br = winbufnr(nr)
            let l:bpath = fnamemodify(bufname(l:br), ':p')
            if l:bpath ==# l:filename
                execute nr . 'wincmd w'
                return
            endif
        endfor
        wincmd p
    else
        " Just open a new tab so we can edit the file there.
        " We don't use `tabedit` because it messes up the current window
        " if it happens to be the same file.
        " We'll just have to clean up the default empty buffer created.
        tabnew
        let l:cleanupbufnr = bufnr('%')
    endif
    execute 'edit ' . escape(l:filename, ' \')
    if l:cleanupbufnr >= 0
        execute 'bdelete ' . l:cleanupbufnr
    endif
endfunction

function! s:HgStatus_AddRemove(linestart, lineend) abort
    " Get the selected filenames.
    let l:filenames = s:HgStatus_GetSelectedFiles(a:linestart, a:lineend, ['!', '?'])
    if len(l:filenames) == 0
        call s:error("No files to add or remove in selection or current line.")
        return
    endif

    " Run `addremove` on those paths.
    let l:repo = s:hg_repo()
    call l:repo.RunCommand('addremove', l:filenames)

    " Refresh the status window.
    call s:HgStatus_Refresh()
endfunction

function! s:HgStatus_Commit(linestart, lineend, bang, vertical) abort
    " Get the selected filenames.
    let l:filenames = s:HgStatus_GetSelectedFiles(a:linestart, a:lineend, ['M', 'A', 'R'])
    if len(l:filenames) == 0
        call s:error("No files to commit in selection or file.")
        return
    endif

    " Run `Hgcommit` on those paths.
    let l:buf_nr = bufnr('%')
    let l:callback = 'call s:HgStatus_Refresh('.l:buf_nr.')'
    call s:HgCommit(a:bang, a:vertical, l:callback, l:filenames)
endfunction

function! s:HgStatus_Diff(split) abort
    " Open the file and run `Hgdiff` on it.
    " We also need to translate the split mode for it... if we already
    " opened the file in a new tab, `HgDiff` only needs to do a vertical
    " split (i.e. split=1).
    let l:newtab = 0
    let l:hgdiffsplit = a:split
    if a:split == 2
        let l:newtab = 1
        let l:hgdiffsplit = 1
    endif
    call s:HgStatus_FileEdit(l:newtab)
    call s:HgDiff('%:p', l:hgdiffsplit)
endfunction

function! s:HgStatus_DiffSummary(split) abort
    " Get the path of the file the cursor is on.
    let l:path = s:HgStatus_GetSelectedFile()
    " Reuse the same diff summary window
    let l:reuse_id = 'lawrencium_diffsum_for_' . bufnr('%')
    let l:split_prev_win = (a:split < 3)
    let l:args = {'reuse_id': l:reuse_id, 'use_prev_win': l:split_prev_win,
                \'split_mode': a:split}
    call s:HgDiffSummary(l:path, l:args)
endfunction

function! s:HgStatus_QNew(linestart, lineend, patchname, ...) abort
    " Get the selected filenames.
    let l:filenames = s:HgStatus_GetSelectedFiles(a:linestart, a:lineend, ['M', 'A', 'R'])
    if len(l:filenames) == 0
        call s:error("No files in selection or file to create patch.")
        return
    endif

    " Run `Hg qnew` on those paths.
    let l:repo = s:hg_repo()
    call insert(l:filenames, a:patchname, 0)
    if a:0 > 0
        call insert(l:filenames, '-m', 0)
        let l:message = '"' . join(a:000, ' ') . '"'
        call insert(l:filenames, l:message, 1)
    endif
    call l:repo.RunCommand('qnew', l:filenames)

    " Refresh the status window.
    call s:HgStatus_Refresh()
endfunction

function! s:HgStatus_QRefresh(linestart, lineend) abort
    " Get the selected filenames.
    let l:filenames = s:HgStatus_GetSelectedFiles(a:linestart, a:lineend, ['M', 'A', 'R'])
    if len(l:filenames) == 0
        call s:error("No files in selection or file to refresh the patch.")
        return
    endif

    " Run `Hg qrefresh` on those paths.
    let l:repo = s:hg_repo()
    call insert(l:filenames, '-s', 0)
    call l:repo.RunCommand('qrefresh', l:filenames)

    " Refresh the status window.
    call s:HgStatus_Refresh()
endfunction


function! s:HgStatus_GetSelectedFile() abort
    let l:filenames = s:HgStatus_GetSelectedFiles()
    return l:filenames[0]
endfunction

function! s:HgStatus_GetSelectedFiles(...) abort
    if a:0 >= 2
        let l:lines = getline(a:1, a:2)
    else
        let l:lines = []
        call add(l:lines, getline('.'))
    endif
    let l:filenames = []
    let l:repo = s:hg_repo()
    for line in l:lines
        if a:0 >= 3
            let l:status = s:HgStatus_GetFileStatus(line)
            if index(a:3, l:status) < 0
                continue
            endif
        endif
        " Yay, awesome, Vim's regex syntax is fucked up like shit, especially for
        " look-aheads and look-behinds. See for yourself:
        let l:filename = matchstr(l:line, '\v(^[MARC\!\?I ]\s)@<=.*')
        let l:filename = l:repo.GetFullPath(l:filename)
        call add(l:filenames, l:filename)
    endfor
    return l:filenames
endfunction

function! s:HgStatus_GetFileStatus(...) abort
    let l:line = a:0 ? a:1 : getline('.')
    return matchstr(l:line, '\v^[MARC\!\?I ]')
endfunction

call s:AddMainCommand("Hgstatus :call s:HgStatus()")

" }}}

" Hgcd, Hglcd {{{

call s:AddMainCommand("-bang -nargs=? -complete=customlist,s:ListRepoDirs Hgcd :cd<bang> `=s:hg_repo().GetFullPath(<q-args>)`")
call s:AddMainCommand("-bang -nargs=? -complete=customlist,s:ListRepoDirs Hglcd :lcd<bang> `=s:hg_repo().GetFullPath(<q-args>)`")

" }}}

" Hgedit {{{

function! s:HgEdit(bang, filename) abort
    let l:full_path = s:hg_repo().GetFullPath(a:filename)
    if a:bang
        execute "edit! " . l:full_path
    else
        execute "edit " . l:full_path
    endif
endfunction

call s:AddMainCommand("-bang -nargs=1 -complete=customlist,s:ListRepoFiles Hgedit :call s:HgEdit(<bang>0, <f-args>)")

" }}}

" Hgvimgrep {{{

function! s:HgVimGrep(bang, pattern, ...) abort
    let l:repo = s:hg_repo()
    let l:file_paths = []
    if a:0 > 0
        for ff in a:000
            let l:full_ff = l:repo.GetFullPath(ff)
            call add(l:file_paths, l:full_ff)
        endfor
    else
        call add(l:file_paths, l:repo.root_dir . "**")
    endif
    if a:bang
        execute "vimgrep! " . a:pattern . " " . join(l:file_paths, " ")
    else
        execute "vimgrep " . a:pattern . " " . join(l:file_paths, " ")
    endif
endfunction

call s:AddMainCommand("-bang -nargs=+ -complete=customlist,s:ListRepoFiles Hgvimgrep :call s:HgVimGrep(<bang>0, <f-args>)")

" }}}

" Hgdiff, Hgvdiff, Hgtabdiff {{{

function! s:HgDiff(filename, split, ...) abort
    " Default revisions to diff: the working directory (null string) 
    " and the parent of the working directory (using Mercurial's revsets syntax).
    " Otherwise, use the 1 or 2 revisions specified as extra parameters.
    let l:rev1 = 'p1()'
    let l:rev2 = ''
    if a:0 == 1
        if type(a:1) == type([])
            if len(a:1) >= 2
                let l:rev1 = a:1[0]
                let l:rev2 = a:1[1]
            elseif len(a:1) == 1
                let l:rev1 = a:1[0]
            endif
        else
            let l:rev1 = a:1
        endif
    elseif a:0 == 2
        let l:rev1 = a:1
        let l:rev2 = a:2
    endif

    " Get the current repo, and expand the given filename in case it contains
    " fancy filename modifiers.
    let l:repo = s:hg_repo()
    let l:path = expand(a:filename)
    let l:diff_id = localtime()
    call s:trace("Diff'ing '".l:rev1."' and '".l:rev2."' on file: ".l:path)

    " Get the first file and open it.
    let l:cleanupbufnr = -1
    if l:rev1 == ''
        if a:split == 2
            " Don't use `tabedit` here because if `l:path` is the same as
            " the current path, it will also reload the buffer in the current
            " tab/window for some reason, which causes all state to be lost
            " (all folds get collapsed again, cursor is moved to start, etc.)
            tabnew
            let l:cleanupbufnr = bufnr('%')
            execute 'edit ' . fnameescape(l:path)
        else
            if bufexists(l:path)
                execute 'buffer ' . fnameescape(l:path)
            else
                execute 'edit ' . fnameescape(l:path)
            endif
        endif
        " Make it part of the diff group.
        call s:HgDiff_DiffThis(l:diff_id)
    else
        let l:rev_path = l:repo.GetLawrenciumPath(l:path, 'rev', l:rev1)
        if a:split == 2
            " See comments above about avoiding `tabedit`.
            tabnew
            let l:cleanupbufnr = bufnr('%')
        endif
        execute 'edit ' . fnameescape(l:rev_path)
        " Make it part of the diff group.
        call s:HgDiff_DiffThis(l:diff_id)
    endif
    if l:cleanupbufnr >= 0 && bufloaded(l:cleanupbufnr)
        execute 'bdelete ' . l:cleanupbufnr
    endif

    " Get the second file and open it too.
    " Don't use `diffsplit` because it will set `&diff` before we get a chance
    " to save a bunch of local settings that we will want to restore later.
    let l:diffsplit = 'split'
    if a:split >= 1
        let l:diffsplit = 'vsplit'
    endif
    if l:rev2 == ''
        execute l:diffsplit . ' ' . fnameescape(l:path)
    else
        let l:rev_path = l:repo.GetLawrenciumPath(l:path, 'rev', l:rev2)
        execute l:diffsplit . ' ' . fnameescape(l:rev_path)
    endif
    call s:HgDiff_DiffThis(l:diff_id)
endfunction

function! s:HgDiff_DiffThis(diff_id) abort
    " Store some commands to run when we exit diff mode.
    " It's needed because `diffoff` reverts those settings to their default
    " values, instead of their previous ones.
    if &diff
        call s:throw("Calling diffthis too late on a buffer!")
        return
    endif
    call s:trace('Enabling diff mode on ' . bufname('%'))
    let w:lawrencium_diffoff = {}
    let w:lawrencium_diffoff['&diff'] = 0
    let w:lawrencium_diffoff['&wrap'] = &l:wrap
    let w:lawrencium_diffoff['&scrollopt'] = &l:scrollopt
    let w:lawrencium_diffoff['&scrollbind'] = &l:scrollbind
    let w:lawrencium_diffoff['&cursorbind'] = &l:cursorbind
    let w:lawrencium_diffoff['&foldmethod'] = &l:foldmethod
    let w:lawrencium_diffoff['&foldcolumn'] = &l:foldcolumn
    let w:lawrencium_diff_id = a:diff_id
    diffthis
    autocmd BufWinLeave <buffer> call s:HgDiff_CleanUp()
endfunction

function! s:HgDiff_DiffOff(...) abort
    " Get the window name (given as a paramter, or current window).
    let l:nr = a:0 ? a:1 : winnr()

    " Run the commands we saved in `HgDiff_DiffThis`, or just run `diffoff`.
    let l:backup = getwinvar(l:nr, 'lawrencium_diffoff')
    if type(l:backup) == type({}) && len(l:backup) > 0
        call s:trace('Disabling diff mode on ' . l:nr)
        for key in keys(l:backup)
            call setwinvar(l:nr, key, l:backup[key])
        endfor
        call setwinvar(l:nr, 'lawrencium_diffoff', {})
    else
        call s:trace('Disabling diff mode on ' . l:nr . ' (but no true restore)')
        diffoff
    endif
endfunction

function! s:HgDiff_GetDiffWindows(diff_id) abort
    let l:result = []
    for nr in range(1, winnr('$'))
        if getwinvar(nr, '&diff') && getwinvar(nr, 'lawrencium_diff_id') == a:diff_id
            call add(l:result, nr)
        endif
    endfor
    return l:result
endfunction

function! s:HgDiff_CleanUp() abort
    " If we're not leaving one of our diff window, do nothing.
    if !&diff || !exists('w:lawrencium_diff_id')
        return
    endif

    " If there will be only one diff window left (plus the one we're leaving),
    " turn off diff in it and restore its local settings.
    let l:nrs = s:HgDiff_GetDiffWindows(w:lawrencium_diff_id)
    if len(l:nrs) <= 2
        call s:trace('Disabling diff mode in ' . len(l:nrs) . ' windows.')
        for nr in l:nrs
            if getwinvar(nr, '&diff')
                call s:HgDiff_DiffOff(nr)
            endif
        endfor
    else
        call s:trace('Still ' . len(l:nrs) . ' diff windows open.')
    endif
endfunction

call s:AddMainCommand("-nargs=* Hgdiff :call s:HgDiff('%:p', 0, <f-args>)")
call s:AddMainCommand("-nargs=* Hgvdiff :call s:HgDiff('%:p', 1, <f-args>)")
call s:AddMainCommand("-nargs=* Hgtabdiff :call s:HgDiff('%:p', 2, <f-args>)")

" }}}

" Hgdiffsum, Hgdiffsumsplit, Hgvdiffsumsplit, Hgtabdiffsum {{{

function! s:HgDiffSummary(filename, present_args, ...) abort
    " Default revisions to diff: the working directory (null string) 
    " and the parent of the working directory (using Mercurial's revsets syntax).
    " Otherwise, use the 1 or 2 revisions specified as extra parameters.
    let l:revs = ''
    if a:0 == 1
        if type(a:1) == type([])
            if len(a:1) >= 2
                let l:revs = a:1[0] . ',' . a:1[1]
            elseif len(a:1) == 1
                let l:revs = a:1[0]
            endif
        else
            let l:revs = a:1
        endif
    elseif a:0 >= 2
        let l:revs = a:1 . ',' . a:2
    endif

    " Get the current repo, and expand the given filename in case it contains
    " fancy filename modifiers.
    let l:repo = s:hg_repo()
    let l:path = expand(a:filename)
    call s:trace("Diff'ing revisions: '".l:revs."' on file: ".l:path)
    let l:special = l:repo.GetLawrenciumPath(l:path, 'diff', l:revs)

    " Build the correct edit command, and switch to the correct window, based
    " on the presentation arguments we got.
    if type(a:present_args) == type(0)
        " Just got a split mode.
        let l:valid_args = {'split_mode': a:present_args}
    else
        " Got complex args.
        let l:valid_args = a:present_args
    endif

    " First, see if we should reuse an existing window based on some buffer
    " variable.
    let l:target_winnr = -1
    let l:split = get(l:valid_args, 'split_mode', 0)
    let l:reuse_id = get(l:valid_args, 'reuse_id', '')
    if l:reuse_id != ''
        let l:target_winnr = s:find_buffer_window(l:reuse_id, 1)
        if l:target_winnr > 0 && l:split != 3
            " Unless we'll be opening in a new tab, don't split anymore, since
            " we found the exact window we wanted.
            let l:split = 0
        endif
        call s:trace("Looking for window with '".l:reuse_id."', found: ".l:target_winnr)
    endif
    " If we didn't find anything, see if we should use the current or previous
    " window.
    if l:target_winnr < 0
        let l:use_prev_win = get(l:valid_args, 'use_prev_win', 0)
        if l:use_prev_win
            let l:target_winnr = winnr('#')
            call s:trace("Will use previous window: ".l:target_winnr)
        endif
    endif
    " Now let's see what kind of split we want to use, if any.
    let l:cmd = 'edit '
    if l:split == 1
        let l:cmd = 'rightbelow split '
    elseif l:split == 2
        let l:cmd = 'rightbelow vsplit '
    elseif l:split == 3
        let l:cmd = 'tabedit '
    endif
    
    " All good now, proceed.
    if l:target_winnr > 0
        execute l:target_winnr . "wincmd w"
    endif
    execute 'keepalt ' . l:cmd . l:special

    " Set the reuse ID if we had one.
    if l:reuse_id != ''
        call s:trace("Setting reuse ID '".l:reuse_id."' on buffer: ".bufnr('%'))
        call setbufvar('%', l:reuse_id, 1)
    endif
endfunction

call s:AddMainCommand("-nargs=* Hgdiffsum       :call s:HgDiffSummary('%:p', 0, <f-args>)")
call s:AddMainCommand("-nargs=* Hgdiffsumsplit  :call s:HgDiffSummary('%:p', 1, <f-args>)")
call s:AddMainCommand("-nargs=* Hgvdiffsumsplit :call s:HgDiffSummary('%:p', 2, <f-args>)")
call s:AddMainCommand("-nargs=* Hgtabdiffsum    :call s:HgDiffSummary('%:p', 3, <f-args>)")

" }}}

" Hgcommit {{{

function! s:HgCommit(bang, vertical, callback, ...) abort
    " Get the repo we'll be committing into.
    let l:repo = s:hg_repo()

    " Get the list of files to commit.
    " It can either be several files passed as extra parameters, or an
    " actual list passed as the first extra parameter.
    let l:filenames = []
    if a:0
        let l:filenames = a:000
        if a:0 == 1 && type(a:1) == type([])
            let l:filenames = a:1
        endif
    endif

    " Open a commit message file.
    let l:commit_path = s:tempname('hg-editor-', '.txt')
    let l:split = a:vertical ? 'vsplit' : 'split'
    execute l:split . ' ' . l:commit_path
    call append(0, ['', ''])
    call append(2, split(s:HgCommit_GenerateMessage(l:repo, l:filenames), '\n'))
    call cursor(1, 1)

    " Setup the auto-command that will actually commit on write/exit,
    " and make the buffer delete itself on exit.
    let b:mercurial_dir = l:repo.root_dir
    let b:lawrencium_commit_files = l:filenames
    if type(a:callback) == type([])
        let b:lawrencium_commit_pre_callback = a:callback[0]
        let b:lawrencium_commit_post_callback = a:callback[1]
        let b:lawrencium_commit_abort_callback = a:callback[2]
    else
        let b:lawrencium_commit_pre_callback = 0
        let b:lawrencium_commit_post_callback = a:callback
        let b:lawrencium_commit_abort_callback = 0
    endif
    setlocal bufhidden=delete
    setlocal filetype=hgcommit
    if a:bang
        autocmd BufDelete <buffer> call s:HgCommit_Execute(expand('<afile>:p'), 0)
    else
        autocmd BufDelete <buffer> call s:HgCommit_Execute(expand('<afile>:p'), 1)
    endif
    " Make commands available.
    call s:DefineMainCommands()
endfunction

let s:hg_status_messages = { 
    \'M': 'modified',
    \'A': 'added',
    \'R': 'removed',
    \'C': 'clean',
    \'!': 'missing',
    \'?': 'not tracked',
    \'I': 'ignored',
    \' ': '',
    \}

function! s:HgCommit_GenerateMessage(repo, filenames) abort
    let l:msg  = "HG: Enter commit message. Lines beginning with 'HG:' are removed.\n"
    let l:msg .= "HG: Leave message empty to abort commit.\n"
    let l:msg .= "HG: Write and quit buffer to proceed.\n"
    let l:msg .= "HG: --\n"
    let l:msg .= "HG: user: " . split(a:repo.RunCommand('showconfig ui.username'), '\n')[0] . "\n"
    let l:msg .= "HG: branch '" . split(a:repo.RunCommand('branch'), '\n')[0] . "'\n"

    execute 'lcd ' . a:repo.root_dir
    if len(a:filenames)
        let l:status_lines = split(a:repo.RunCommand('status', a:filenames), "\n")
    else
        let l:status_lines = split(a:repo.RunCommand('status'), "\n")
    endif
    for l:line in l:status_lines
        if l:line ==# ''
            continue
        endif
        let l:type = matchstr(l:line, '\v^[MARC\!\?I ]')
        let l:path = l:line[2:]
        let l:msg .= "HG: " . s:hg_status_messages[l:type] . ' ' . l:path . "\n"
    endfor

    return l:msg
endfunction

function! s:HgCommit_Execute(log_file, show_output) abort
    " Check if the user actually saved a commit message.
    if !filereadable(a:log_file)
        call s:error("abort: Commit message not saved")
        if exists('b:lawrencium_commit_abort_callback') &&
                    \type(b:lawrencium_commit_abort_callback) == type("") &&
                    \b:lawrencium_commit_abort_callback != ''
            call s:trace("Executing abort callback: ".b:lawrencium_commit_abort_callback)
            execute b:lawrencium_commit_abort_callback
        endif
        return
    endif

    " Execute a pre-callback if there is one.
    if exists('b:lawrencium_commit_pre_callback') &&
                \type(b:lawrencium_commit_pre_callback) == type("") &&
                \b:lawrencium_commit_pre_callback != ''
        call s:trace("Executing pre callback: ".b:lawrencium_commit_pre_callback)
        execute b:lawrencium_commit_pre_callback
    endif

    call s:trace("Committing with log file: " . a:log_file)

    " Clean all the 'HG: ' lines.
    let l:is_valid = s:clean_commit_file(a:log_file)
    if !l:is_valid
        call s:error("abort: Empty commit message")
        return
    endif

    " Get the repo and commit with the given message.
    let l:repo = s:hg_repo()
    let l:hg_args = ['-l', a:log_file]
    call extend(l:hg_args, b:lawrencium_commit_files)
    let l:output = l:repo.RunCommand('commit', l:hg_args)
    if a:show_output && l:output !~# '\v%^\s*%$'
        call s:trace("Output from hg commit:", 1)
        for l:output_line in split(l:output, '\n')
            echom l:output_line
        endfor
    endif

    " Execute a post-callback if there is one.
    if exists('b:lawrencium_commit_post_callback') &&
                \type(b:lawrencium_commit_post_callback) == type("") &&
                \b:lawrencium_commit_post_callback != ''
        call s:trace("Executing post callback: ".b:lawrencium_commit_post_callback)
        execute b:lawrencium_commit_post_callback
    endif
endfunction

call s:AddMainCommand("-bang -nargs=* -complete=customlist,s:ListRepoFiles Hgcommit :call s:HgCommit(<bang>0, 0, 0, <f-args>)")
call s:AddMainCommand("-bang -nargs=* -complete=customlist,s:ListRepoFiles Hgvcommit :call s:HgCommit(<bang>0, 1, 0, <f-args>)")

" }}}

" Hgrevert {{{

function! s:HgRevert(bang, ...) abort
    " Get the files to revert.
    let l:filenames = a:000
    if a:0 == 0
        let l:filenames = [ expand('%:p') ]
    endif
    if a:bang
        call insert(l:filenames, '--no-backup', 0)
    endif

    " Get the repo and run the command.
    let l:repo = s:hg_repo()
    call l:repo.RunCommand('revert', l:filenames)

    " Re-edit the file to see the change.
    edit
endfunction

call s:AddMainCommand("-bang -nargs=* -complete=customlist,s:ListRepoFiles Hgrevert :call s:HgRevert(<bang>0, <f-args>)")

" }}}

" Hglog, Hglogthis {{{

function! s:HgLog(vertical, ...) abort
    " Get the file or directory to get the log from.
    " (empty string is for the whole repository)
    let l:repo = s:hg_repo()
    if a:0 > 0 && matchstr(a:1, '\v-*') == ""
        let l:path = l:repo.GetRelativePath(expand(a:1))
    else
        let l:path = ''
    endif

    " Get the Lawrencium path for this `hg log`,
    " open it in a preview window and jump to it.
    if a:0 > 0 && l:path != ""
      let l:log_opts = join(a:000[1:-1], ',')
    else
      let l:log_opts = join(a:000, ',')
    endif

    let l:log_path = l:repo.GetLawrenciumPath(l:path, 'log', l:log_opts)
    if a:vertical
        execute 'vertical pedit ' . l:log_path
    else
        execute 'pedit ' . l:log_path
    endif
    wincmd P

    " Add some other nice commands and mappings.
    let l:is_file = (l:path != '' && filereadable(l:repo.GetFullPath(l:path)))
    command! -buffer -nargs=* Hglogdiffsum    :call s:HgLog_DiffSummary(1, <f-args>)
    command! -buffer -nargs=* Hglogvdiffsum   :call s:HgLog_DiffSummary(2, <f-args>)
    command! -buffer -nargs=* Hglogtabdiffsum :call s:HgLog_DiffSummary(3, <f-args>)
    command! -buffer -nargs=+ -complete=file Hglogexport :call s:HgLog_ExportPatch(<f-args>)
    if l:is_file
        command! -buffer Hglogrevedit          :call s:HgLog_FileRevEdit()
        command! -buffer -nargs=* Hglogdiff    :call s:HgLog_Diff(0, <f-args>)
        command! -buffer -nargs=* Hglogvdiff   :call s:HgLog_Diff(1, <f-args>)
        command! -buffer -nargs=* Hglogtabdiff :call s:HgLog_Diff(2, <f-args>)
    endif

    if g:lawrencium_define_mappings
        nnoremap <buffer> <silent> <C-U> :Hglogdiffsum<cr>
        nnoremap <buffer> <silent> <C-H> :Hglogvdiffsum<cr>
        nnoremap <buffer> <silent> <cr>  :Hglogvdiffsum<cr>
        nnoremap <buffer> <silent> q     :bdelete!<cr>
        if l:is_file
            nnoremap <buffer> <silent> <C-E>  :Hglogrevedit<cr>
            nnoremap <buffer> <silent> <C-D>  :Hglogtabdiff<cr>
            nnoremap <buffer> <silent> <C-V>  :Hglogvdiff<cr>
        endif
    endif

    " Clean up when the log buffer is deleted.
    let l:bufobj = s:buffer_obj()
    call l:bufobj.OnDelete('call s:HgLog_Delete(' . l:bufobj.nr . ')')
endfunction

function! s:HgLog_Delete(bufnr)
    if g:lawrencium_auto_close_buffers
        call s:delete_dependency_buffers('lawrencium_diff_for', a:bufnr)
        call s:delete_dependency_buffers('lawrencium_rev_for', a:bufnr)
    endif
endfunction

function! s:HgLog_FileRevEdit()
    let l:repo = s:hg_repo()
    let l:bufobj = s:buffer_obj()
    let l:rev = s:HgLog_GetSelectedRev()
    let l:log_path = s:parse_lawrencium_path(l:bufobj.GetName())
    let l:path = l:repo.GetLawrenciumPath(l:log_path['path'], 'rev', l:rev)

    " Go to the window we were in before going in the log window,
    " and open the revision there.
    wincmd p
    call s:edit_deletable_buffer('lawrencium_rev_for', l:bufobj.nr, l:path)
endfunction

function! s:HgLog_Diff(split, ...) abort
    let l:revs = []
    if a:0 >= 2
        let l:revs = [a:1, a:2]
    elseif a:0 == 1
        let l:revs = ['p1('.a:1.')', a:1]
    else
        let l:sel = s:HgLog_GetSelectedRev()
        let l:revs = ['p1('.l:sel.')', l:sel]
    endif

    let l:repo = s:hg_repo()
    let l:bufobj = s:buffer_obj()
    let l:log_path = s:parse_lawrencium_path(l:bufobj.GetName())
    let l:path = l:repo.GetFullPath(l:log_path['path'])

    " Go to the window we were in before going to the log window,
    " and open the split diff there.
    if a:split < 2
        wincmd p
    endif
    call s:HgDiff(l:path, a:split, l:revs)
endfunction

function! s:HgLog_DiffSummary(split, ...) abort
    let l:revs = []
    if a:0 >= 2
        let l:revs = [a:1, a:2]
    elseif a:0 == 1
        let l:revs = [a:1]
    else
        let l:revs = [s:HgLog_GetSelectedRev()]
    endif

    let l:repo = s:hg_repo()
    let l:bufobj = s:buffer_obj()
    let l:log_path = s:parse_lawrencium_path(l:bufobj.GetName())
    let l:path = l:repo.GetFullPath(l:log_path['path'])

    " Go to the window we were in before going in the log window,
    " and split for the diff summary from there.
    let l:reuse_id = 'lawrencium_diffsum_for_' . bufnr('%')
    let l:split_prev_win = (a:split < 3)
    let l:args = {'reuse_id': l:reuse_id, 'use_prev_win': l:split_prev_win,
                \'split_mode': a:split}
    call s:HgDiffSummary(l:path, l:args, l:revs)
endfunction

function! s:HgLog_GetSelectedRev(...) abort
    if a:0 == 1
        let l:line = getline(a:1)
    else
        let l:line = getline('.')
    endif
    " Behold, Vim's look-ahead regex syntax again! WTF.
    let l:rev = matchstr(l:line, '\v^(\d+)(\:)@=')
    if l:rev == ''
        call s:throw("Can't parse revision number from line: " . l:line)
    endif
    return l:rev
endfunction

function! s:HgLog_ExportPatch(...) abort
    let l:patch_name = a:1
    if !empty($HG_EXPORT_PATCH_DIR)
        " Use the patch dir only if user has specified a relative path
        if has('win32')
            let l:is_patch_relative = (matchstr(l:patch_name, '\v^([a-zA-Z]:)?\\') == "")
        else
            let l:is_patch_relative = (matchstr(l:patch_name, '\v^/') == "")
        endif
        if l:is_patch_relative
            let l:patch_name = s:normalizepath(
                s:stripslash($HG_EXPORT_PATCH_DIR) . "/" . l:patch_name)
        endif
    endif

    if a:0 == 2
        let l:rev = a:2
    else
        let l:rev = s:HgLog_GetSelectedRev()
    endif

    let l:repo = s:hg_repo()
    let l:export_args = ['-o', l:patch_name, '-r', l:rev]

    call l:repo.RunCommand('export', l:export_args)

    echom "Created patch: " . l:patch_name
endfunction

call s:AddMainCommand("Hglogthis  :call s:HgLog(0, '%:p')")
call s:AddMainCommand("Hgvlogthis :call s:HgLog(1, '%:p')")
call s:AddMainCommand("-nargs=* -complete=customlist,s:ListRepoFiles Hglog  :call s:HgLog(0, <f-args>)")
call s:AddMainCommand("-nargs=* -complete=customlist,s:ListRepoFiles Hgvlog  :call s:HgLog(1, <f-args>)")

" }}}

" Hgannotate, Hgwannotate {{{

function! s:HgAnnotate(bang, verbose, ...) abort
    " Open the file to annotate if needed.
    if a:0 > 0
        call s:HgEdit(a:bang, a:1)
    endif

    " Get the Lawrencium path for the annotated file.
    let l:path = expand('%:p')
    let l:bufnr = bufnr('%')
    let l:repo = s:hg_repo()
    let l:value = a:verbose ? 'v=1' : ''
    let l:annotation_path = l:repo.GetLawrenciumPath(l:path, 'annotate', l:value)
    
    " Check if we're trying to annotate something with local changes.
    let l:has_local_edits = 0
    let l:path_status = l:repo.RunCommand('status', l:path)
    if l:path_status != ''
        call s:trace("Found local edits for '" . l:path . "'. Will annotate parent revision.")
        let l:has_local_edits = 1
    endif
    
    if l:has_local_edits
        " Just open the output of the command.
        echom "Local edits found, will show the annotations for the parent revision."
        execute 'edit ' . l:annotation_path
        setlocal nowrap nofoldenable
        setlocal filetype=hgannotate
    else
        " Store some info about the current buffer.
        let l:cur_topline = line('w0') + &scrolloff
        let l:cur_line = line('.')
        let l:cur_wrap = &wrap
        let l:cur_foldenable = &foldenable

        " Open the annotated file in a split buffer on the left, after
        " having disabled wrapping and folds on the current file.
        " Make both windows scroll-bound.
        setlocal scrollbind nowrap nofoldenable
        execute 'keepalt leftabove vsplit ' . l:annotation_path
        setlocal nonumber
        setlocal scrollbind nowrap nofoldenable foldcolumn=0
        setlocal filetype=hgannotate

        " When the annotated buffer is deleted, restore the settings we
        " changed on the current buffer, and go back to that buffer.
        let l:annotate_buffer = s:buffer_obj()
        call l:annotate_buffer.OnDelete('execute bufwinnr(' . l:bufnr . ') . "wincmd w"')
        call l:annotate_buffer.OnDelete('setlocal noscrollbind')
        if l:cur_wrap
            call l:annotate_buffer.OnDelete('setlocal wrap')
        endif
        if l:cur_foldenable
            call l:annotate_buffer.OnDelete('setlocal foldenable')
        endif

        " Go to the line we were at in the source buffer when we
        " opened the annotation window.
        execute l:cur_topline
        normal! zt
        execute l:cur_line
        syncbind

        " Set the correct window width for the annotations.
        if a:verbose
            let l:last_token = match(getline('.'), '\v\d{4}:\s')
            let l:token_end = 5
        else
            let l:last_token = match(getline('.'), '\v\d{2}:\s')
            let l:token_end = 3
        endif
        if l:last_token < 0
            echoerr "Can't find the end of the annotation columns."
        else
            let l:column_count = l:last_token + l:token_end + g:lawrencium_annotate_width_offset
            execute "vertical resize " . l:column_count
            setlocal winfixwidth
        endif
    endif

    " Make the annotate buffer a Lawrencium buffer.
    let b:mercurial_dir = l:repo.root_dir
    let b:lawrencium_annotated_path = l:path
    let b:lawrencium_annotated_bufnr = l:bufnr
    call s:DefineMainCommands()

    " Add some other nice commands and mappings.
    command! -buffer Hgannotatediffsum :call s:HgAnnotate_DiffSummary()
    if g:lawrencium_define_mappings
        nnoremap <buffer> <silent> <cr> :Hgannotatediffsum<cr>
    endif

    " Clean up when the annotate buffer is deleted.
    let l:bufobj = s:buffer_obj()
    call l:bufobj.OnDelete('call s:HgAnnotate_Delete(' . l:bufobj.nr . ')')
endfunction

function! s:HgAnnotate_Delete(bufnr) abort
    if g:lawrencium_auto_close_buffers
        call s:delete_dependency_buffers('lawrencium_diff_for', a:bufnr)
    endif
endfunction

function! s:HgAnnotate_DiffSummary() abort
    " Get the path for the diff of the revision specified under the cursor.
    let l:line = getline('.')
    let l:rev_hash = matchstr(l:line, '\v[a-f0-9]{12}')

    " Get the Lawrencium path for the diff, and the buffer object for the
    " annotation.
    let l:repo = s:hg_repo()
    let l:path = l:repo.GetLawrenciumPath(b:lawrencium_annotated_path, 'diff', l:rev_hash)
    let l:annotate_buffer = s:buffer_obj()

    " Find a window already displaying diffs for this annotation.
    let l:diff_winnr = s:find_buffer_window('lawrencium_diff_for', l:annotate_buffer.nr)
    if l:diff_winnr == -1
        " Not found... go back to the main source buffer and open a bottom 
        " split with the diff for the specified revision.
        execute bufwinnr(b:lawrencium_annotated_bufnr) . 'wincmd w'
        execute 'rightbelow split ' . fnameescape(l:path)
        let b:lawrencium_diff_for = l:annotate_buffer.nr
        let b:lawrencium_quit_on_delete = 1
    else
        " Found! Use that window to open the diff.
        execute l:diff_winnr . 'wincmd w'
        execute 'edit ' . fnameescape(l:path)
        let b:lawrencium_diff_for = l:annotate_buffer.nr
    endif
endfunction

call s:AddMainCommand("-bang -nargs=? -complete=customlist,s:ListRepoFiles Hgannotate :call s:HgAnnotate(<bang>0, 0, <f-args>)")
call s:AddMainCommand("-bang -nargs=? -complete=customlist,s:ListRepoFiles Hgwannotate :call s:HgAnnotate(<bang>0, 1, <f-args>)")

" }}}

" Hgqseries {{{

function! s:HgQSeries() abort
    " Open the MQ series in the preview window and jump to it.
    let l:repo = s:hg_repo()
    let l:path = l:repo.GetLawrenciumPath('', 'qseries', '')
    execute 'pedit ' . l:path
    wincmd P

    " Make the series buffer a Lawrencium buffer.
    let b:mercurial_dir = l:repo.root_dir
    call s:DefineMainCommands()

    " Add some commands and mappings.
    command! -buffer Hgqseriesgoto                  :call s:HgQSeries_Goto()
    command! -buffer Hgqserieseditmessage           :call s:HgQSeries_EditMessage()
    command! -buffer -nargs=+ Hgqseriesrename       :call s:HgQSeries_Rename(<f-args>)
    if g:lawrencium_define_mappings
        nnoremap <buffer> <silent> <C-g> :Hgqseriesgoto<cr>
        nnoremap <buffer> <silent> <C-e> :Hgqserieseditmessage<cr>
        nnoremap <buffer> <silent> q     :bdelete!<cr>
    endif
endfunction

function! s:HgQSeries_GetCurrentPatchName() abort
    let l:pos = getpos('.')
    return getbufvar('%', 'lawrencium_patchname_' . l:pos[1])
endfunction

function! s:HgQSeries_Goto() abort
    let l:repo = s:hg_repo()
    let l:patchname = s:HgQSeries_GetCurrentPatchName()
    if len(l:patchname) == 0
        call s:error("No patch to go to here.")
        return
    endif
    call l:repo.RunCommand('qgoto', l:patchname)
    edit
endfunction

function! s:HgQSeries_Rename(...) abort
    let l:repo = s:hg_repo()
    let l:current_name = s:HgQSeries_GetCurrentPatchName()
    if len(l:current_name) == 0
        call s:error("No patch to rename here.")
        return
    endif
    let l:new_name = '"' . join(a:000, ' ') . '"'
    call l:repo.RunCommand('qrename', l:current_name, l:new_name)
    edit
endfunction

function! s:HgQSeries_EditMessage() abort
    let l:repo = s:hg_repo()
    let l:patchname = getbufvar('%', 'lawrencium_patchname_top')
    if len(l:patchname) == 0
        call s:error("No patch to edit here.")
        return
    endif
    let l:current = split(l:repo.RunCommand('qheader', l:patchname), '\n')

    " Open a temp file to write the commit message.
    let l:temp_file = s:tempname('hg-qrefedit-', '.txt')
    split
    execute 'edit ' . l:temp_file
    call append(0, 'HG: Enter the new commit message for patch "' . l:patchname . '" here.\n')
    call append(0, '')
    call append(0, l:current)
    call cursor(1, 1)

    " Make it a temp buffer that will actually change the commit message
    " when it is saved and closed.
    let b:mercurial_dir = l:repo.root_dir
    let b:lawrencium_patchname = l:patchname
    setlocal bufhidden=delete
    setlocal filetype=hgcommit
    autocmd BufDelete <buffer> call s:HgQSeries_EditMessage_Execute(expand('<afile>:p'))

    call s:DefineMainCommands()
endfunction

function! s:HgQSeries_EditMessage_Execute(log_file) abort
    if !filereadable(a:log_file)
        call s:error("abort: Commit message not saved")
        return
    endif

    " Clean all the 'HG:' lines.
    let l:is_valid = s:clean_commit_file(a:log_file)
    if !l:is_valid
        call s:error("abort: Empty commit message")
        return
    endif

    " Get the repo and edit the given patch.
    let l:repo = s:hg_repo()
    let l:hg_args = ['-s', '-l', a:log_file]
    call l:repo.RunCommand('qref', l:hg_args)
endfunction

call s:AddMainCommand("Hgqseries call s:HgQSeries()")

" }}}

" Hgrecord {{{

function! s:HgRecord(split) abort
    let l:repo = s:hg_repo()
    let l:orig_buf = s:buffer_obj()
    let l:tmp_path = l:orig_buf.GetName(':p') . '~record'
    let l:diff_id = localtime()

    " Start diffing on the current file, enable some commands.
    call l:orig_buf.DefineCommand('Hgrecordabort', ':call s:HgRecord_Abort()')
    call l:orig_buf.DefineCommand('Hgrecordcommit', ':call s:HgRecord_Execute()')
    call s:HgDiff_DiffThis(l:diff_id)
    setlocal foldmethod=marker

    " Split the window and open the parent revision in the right or bottom
    " window. Keep the current buffer in the left or top window... we're going
    " to 'move' those changes into the parent revision.
    let l:cmd = 'keepalt rightbelow split '
    if a:split == 1
        let l:cmd = 'keepalt rightbelow vsplit '
    endif
    let l:rev_path = l:repo.GetLawrenciumPath(expand('%'), 'rev', '')
    execute l:cmd . fnameescape(l:rev_path)

    " This new buffer with the parent revision is set as a Lawrencium buffer.
    " Let's save it to an actual file and reopen it like that (somehow we
    " could probably do it with `:saveas` instead but we'd need to reset a
    " bunch of other buffer settings, and Vim weirdly creates another backup
    " buffer when you do that).
    execute 'keepalt write! ' . fnameescape(l:tmp_path)
    execute 'keepalt edit! ' . fnameescape(l:tmp_path)
    setlocal bufhidden=delete
    let b:mercurial_dir = l:repo.root_dir
    let b:lawrencium_record_for = l:orig_buf.GetName(':p')
    let b:lawrencium_record_other_nr = l:orig_buf.nr
    let b:lawrencium_record_commit_split = !a:split
    call setbufvar(l:orig_buf.nr, 'lawrencium_record_for', '%')
    call setbufvar(l:orig_buf.nr, 'lawrencium_record_other_nr', bufnr('%'))

    " Hookup the commit and abort commands.
    let l:rec_buf = s:buffer_obj()
    call l:rec_buf.OnDelete('call s:HgRecord_Execute()')
    call l:rec_buf.DefineCommand('Hgrecordcommit', ':quit')
    call l:rec_buf.DefineCommand('Hgrecordabort', ':call s:HgRecord_Abort()')
    call s:DefineMainCommands()

    " Make it the other part of the diff.
    call s:HgDiff_DiffThis(l:diff_id)
    setlocal foldmethod=marker
    call l:rec_buf.SetVar('&filetype', l:orig_buf.GetVar('&filetype'))

    if g:lawrencium_record_start_in_working_buffer
        wincmd p
    endif
endfunction

function! s:HgRecord_Execute() abort
    if exists('b:lawrencium_record_abort')
        " Abort flag is set, let's just cleanup.
        let l:buf_nr = b:lawrencium_record_for == '%' ? bufnr('%') :
                    \b:lawrencium_record_other_nr
        call s:HgRecord_CleanUp(l:buf_nr)
        call s:error("abort: User requested aborting the record operation.")
        return
    endif

    if !exists('b:lawrencium_record_for')
        call s:throw("This doesn't seem like a record buffer, something's wrong!")
    endif
    if b:lawrencium_record_for == '%'
        " Switch to the 'recording' buffer's window.
        let l:buf_obj = s:buffer_obj(b:lawrencium_record_other_nr)
        call l:buf_obj.MoveToFirstWindow()
    endif

    " Setup the commit operation.
    let l:split = b:lawrencium_record_commit_split
    let l:working_bufnr = b:lawrencium_record_other_nr
    let l:working_path = fnameescape(b:lawrencium_record_for)
    let l:record_path = fnameescape(expand('%:p'))
    let l:callbacks = [
                \'call s:HgRecord_PostExecutePre('.l:working_bufnr.', "'.
                    \escape(l:working_path, '\').'", "'.
                    \escape(l:record_path, '\').'")',
                \'call s:HgRecord_PostExecutePost('.l:working_bufnr.', "'.
                    \escape(l:working_path, '\').'")',
                \'call s:HgRecord_PostExecuteAbort('.l:working_bufnr.', "'.
                    \escape(l:record_path, '\').'")'
                \]
    call s:trace("Starting commit flow with callbacks: ".string(l:callbacks))
    call s:HgCommit(0, l:split, l:callbacks, b:lawrencium_record_for)
endfunction

function! s:HgRecord_PostExecutePre(working_bufnr, working_path, record_path) abort
    " Just before committing, we switch the original file with the record
    " file... we'll restore things in the post-callback below.
    " We also switch on 'autoread' temporarily on the working buffer so that
    " we don't have an annoying popup in gVim.
    if has('dialog_gui')
        call setbufvar(a:working_bufnr, '&autoread', 1)
    endif
    call s:trace("Backuping original file: ".a:working_path)
    silent call rename(a:working_path, a:working_path.'~working')
    call s:trace("Committing recorded changes using: ".a:record_path)
    silent call rename(a:record_path, a:working_path)
    sleep 200m
endfunction

function! s:HgRecord_PostExecutePost(working_bufnr, working_path) abort
    " Recover the back-up file from underneath the buffer.
    call s:trace("Recovering original file: ".a:working_path)
    silent call rename(a:working_path.'~working', a:working_path)

    " Clean up!
    call s:HgRecord_CleanUp(a:working_bufnr)

    " Restore default 'autoread'.
    if has('dialog_gui')
        set autoread<
    endif
endfunction

function! s:HgRecord_PostExecuteAbort(working_bufnr, record_path) abort
    call s:HgRecord_CleanUp(a:working_bufnr)
    call s:trace("Delete discarded record file: ".a:record_path)
    silent call delete(a:record_path)
endfunction

function! s:HgRecord_Abort() abort
    if b:lawrencium_record_for == '%'
        " We're in the working directory buffer. Switch to the 'recording'
        " buffer and quit.
        let l:buf_obj = s:buffer_obj(b:lawrencium_record_other_nr)
        call l:buf_obj.MoveToFirstWindow()
    endif
    " We're now in the 'recording' buffer... set the abort flag and quit,
    " which will run the execution (it will early out and clean things up).
    let b:lawrencium_record_abort = 1
    quit!
endfunction

function! s:HgRecord_CleanUp(buf_nr) abort
    " Get in the original buffer and clean the local commands/variables.
    let l:buf_obj = s:buffer_obj(a:buf_nr)
    call l:buf_obj.MoveToFirstWindow()
    if !exists('b:lawrencium_record_for') || b:lawrencium_record_for != '%'
        call s:throw("Cleaning up something else than the original buffer ".
                \"for a record operation. That's suspiciously incorrect! ".
                \"Aborting.")
    endif
    call l:buf_obj.DeleteCommand('Hgrecordabort')
    call l:buf_obj.DeleteCommand('Hgrecordcommit')
    unlet b:lawrencium_record_for
    unlet b:lawrencium_record_other_nr
endfunction

call s:AddMainCommand("Hgrecord call s:HgRecord(0)")
call s:AddMainCommand("Hgvrecord call s:HgRecord(1)")

" }}}

" Autoload Functions {{{

" Prints a summary of the current repo (if any) that's appropriate for
" displaying on the status line.
function! lawrencium#statusline(...)
    if !exists('b:mercurial_dir')
        return ''
    endif
    let l:repo = s:hg_repo()
    let l:prefix = (a:0 > 0 ? a:1 : '')
    let l:suffix = (a:0 > 1 ? a:2 : '')
    let l:branch = 'default'
    let l:branch_file = l:repo.GetFullPath('.hg/branch')
    if filereadable(l:branch_file)
        let l:branch = readfile(l:branch_file)[0]
    endif
    let l:bookmarks = ''
    let l:bookmarks_file = l:repo.GetFullPath('.hg/bookmarks.current')
    if filereadable(l:bookmarks_file)
        let l:bookmarks = join(readfile(l:bookmarks_file), ', ')
    endif
    let l:line = l:prefix . l:branch
    if strlen(l:bookmarks) > 0
        let l:line = l:line . ' - ' . l:bookmarks
    endif
    let l:line = l:line . l:suffix
    return l:line
endfunction

" Rescans the current buffer for setting up Mercurial commands.
" Passing '1' as the parameter enables debug traces temporarily.
function! lawrencium#rescan(...)
    if exists('b:mercurial_dir')
        unlet b:mercurial_dir
    endif
    if a:0 && a:1
        let l:trace_backup = g:lawrencium_trace
        let g:lawrencium_trace = 1
    endif
    call s:setup_buffer_commands()
    if a:0 && a:1
        let g:lawrencium_trace = l:trace_backup
    endif
endfunction

" Enables/disables the debug trace.
function! lawrencium#debugtrace(...)
    let g:lawrencium_trace = (a:0 == 0 || (a:0 && a:1))
    echom "Lawrencium debug trace is now " . (g:lawrencium_trace ? "enabled." : "disabled.")
endfunction

" }}}

