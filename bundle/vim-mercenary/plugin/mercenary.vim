" mercenary.vim - A mercurial wrapper so awesome, you should give it money
" Maintainer:   Jamie Wong <http://jamie-wong.com/>
" Version:      0.1

" TODO(jlfwong):
"   * Mappings in blame to open up :HGcat or :HGshow
"   * Syntax highlighting for :HGshow
"   * Powerline integration
"   * Better Autocompletion
"   * Error handling
"   * Make :HGcat {rev} % do something reasonable if you're already viewing
"     a file at a specifi revision

if exists('g:loaded_mercenary') || &cp
  finish
endif

let g:loaded_mercenary = 1
if !exists('g:mercenary_hg_executable')
  let g:mercenary_hg_executable = 'hg'
endif

" VimL Utilities {{{1

function! s:clsinit(properties, cls) abort
  let proto_ref = {}
  for name in keys(a:cls)
    let proto_ref[name] = a:cls[name]
  endfor
  return extend(a:properties, proto_ref, "keep")
endfunction

function! s:shellslash(path)
  if exists('+shellslash') && !&shellslash
    return s:gsub(a:path,'\\','/')
  else
    return a:path
  endif
endfunction

function! s:sub(str,pat,rep) abort
  return substitute(a:str,'\v\C'.a:pat,a:rep,'')
endfunction

function! s:gsub(str,pat,rep) abort
  return substitute(a:str,'\v\C'.a:pat,a:rep,'g')
endfunction

function! s:shellesc(arg) abort
  if a:arg =~ '^[A-Za-z0-9_/.-]\+$'
    return a:arg
  elseif &shell =~# 'cmd'
    return '"'.s:gsub(s:gsub(a:arg, '"', '""'), '\%', '"%"').'"'
  else
    return shellescape(a:arg)
  endif
endfunction

function! s:warn(str)
  echohl WarningMsg
  echomsg a:str
  echohl None
  let v:warningmsg = a:str
endfunction

" }}1
" Mercenary Utilities {{{1

let s:mercenary_commands = []
function! s:add_command(definition) abort
  let s:mercenary_commands += [a:definition]
endfunction

function! s:extract_hg_root_dir(path) abort
  " Return the absolute path to the root directory of the hg repository, or an
  " empty string if the path is not inside an hg directory.

  " Handle mercenary:// paths as special cases
  if s:shellslash(a:path) =~# '^mercenary://.*//'
    return matchstr(s:shellslash(a:path), '\C^mercenary://\zs.\{-\}\ze//')
  endif

  " Expand to absolute path and strip trailing slashes
  let root = s:shellslash(simplify(fnamemodify(a:path, ':p:s?[\/]$??')))
  let prev = ''

  while root !=# prev
    let dirpath = s:sub(root, '[\/]$', '') . '/.hg'
    let type = getftype(dirpath)
    if type != ''
      " File exists, stop here
      return root
    endif
    let prev = root

    " Move up a directory
    let root = fnamemodify(root, ':h')
  endwhile
  return ''
endfunction

function! s:gen_mercenary_path(method, ...) abort
  let merc_path = 'mercenary://' . s:repo().root_dir . '//' . a:method . ':'
  let merc_path .= join(a:000, '//')
  return merc_path
endfunction

" }}}1
" Repo {{{1

let s:repo_cache = {}
function! s:repo(...)
  " Retrieves a Repo instance. If an argument is passed, it is interpreted as
  " the root directory of the hg repo (i.e. what `hg root` would output if run
  " anywhere inside the repository. Otherwise, the repository containing the
  " file in the current buffer is used.
  if !a:0
    return s:buffer().repo()
  endif

  let root_dir = a:1
  if !has_key(s:repo_cache, root_dir)
    let s:repo_cache[root_dir] = s:Repo.new(root_dir)
  endif

  return s:repo_cache[root_dir]
endfunction

let s:Repo = {}
function! s:Repo.new(root_dir) dict abort
  let repo = {
    \"root_dir" : a:root_dir
  \}
  return s:clsinit(repo, self)
endfunction

function! s:Repo.hg_command(...) dict abort
  " Return a full hg command to be executed as a string.
  "
  " All arguments passed are translated into hg commandline arguments.
  let cmd = 'cd ' . self.root_dir
  " HGPLAIN is an environment variable that's supposed to override any settings
  " that will mess with the hg command
  let cmd .= ' && HGPLAIN=1 ' . g:mercenary_hg_executable
  let cmd .= ' ' . join(map(copy(a:000), 's:shellesc(v:val)'), ' ')
  return cmd
endfunction

" }}}1
" Buffer {{{1

let s:buffer_cache = {}
function! s:buffer(...)
  " Retrieves a Buffer instance. If an argument is passed, it is interpreted as
  " the buffer number. Otherwise the buffer number of the active buffer is used.
  let bufnr = a:0 ? a:1 : bufnr('%')

  if !has_key(s:buffer_cache, bufnr)
    let s:buffer_cache[bufnr] = s:Buffer.new(bufnr)
  endif

  return s:buffer_cache[bufnr]
endfunction

let s:Buffer = {}
function! s:Buffer.new(number) dict abort
  let buffer = {
    \"_number" : a:number
  \}
  return s:clsinit(buffer, self)
endfunction

function! s:Buffer.path() dict abort
  return fnamemodify(bufname(self.bufnr()), ":p")
endfunction

function! s:Buffer.relpath() dict abort
  return fnamemodify(self.path(), ':.')
endfunction

function! s:Buffer.bufnr() dict abort
  return self["_number"]
endfunction

function! s:Buffer.enable_mercenary_commands() dict abort
  " TODO(jlfwong): This is horribly wrong if the buffer isn't active
  for command in s:mercenary_commands
    exe 'command! -buffer '.command
  endfor
endfunction

" XXX(jlfwong) unused
function! s:Buffer.getvar(var) dict abort
  return getbufvar(self.bufnr(), a:var)
endfunction

" XXX(jlfwong) unused
function! s:Buffer.setvar(var, value) dict abort
  return setbufvar(self.bufnr(), a:var, a:value)
endfunction

function! s:Buffer.repo() dict abort
  return s:repo(s:extract_hg_root_dir(self.path()))
endfunction

function! s:Buffer.onwinleave(cmd) dict abort
  call setwinvar(bufwinnr(self.bufnr()), 'mercenary_bufwinleave', a:cmd)
endfunction

function! s:Buffer_winleave(bufnr) abort
  execute getwinvar(bufwinnr(a:bufnr), 'mercenary_bufwinleave')
endfunction

augroup mercenary_buffer
  autocmd!
  autocmd BufWinLeave * call s:Buffer_winleave(expand('<abuf>'))
augroup END

" }}}1
" :HGblame {{{1

function! s:Blame() abort
  " TODO(jlfwong): hg blame doesn't list uncommitted changes, which can result
  " in misalignment if the file has been modified. Figure out a way to fix this.
  "
  " TODO(jlfwong): Considering switching this to use mercenary://blame

  let hg_args = ['blame', '--changeset', '--number', '--user', '--date', '-q']
  let hg_args += ['--', s:buffer().path()]
  let hg_blame_command = call(s:repo().hg_command, hg_args, s:repo())

  let temppath = resolve(tempname())
  let outfile = temppath . '.mercenaryblame'
  let errfile = temppath . '.err'

  " Write the blame output to a .mercenaryblame file in a temp folder somewhere
  silent! execute '!' . hg_blame_command . ' > ' . outfile . ' 2> ' . errfile

  " Remember the bufnr that :HGblame was invoked in
  let source_bufnr = s:buffer().bufnr()

  " Save the settings in the main buffer to be overridden so they can be
  " restored when the buffer is closed
  let restore = 'call setwinvar(bufwinnr(' . source_bufnr . '), "&scrollbind", 0)'
  if &l:wrap
    let restore .= '|call setwinvar(bufwinnr(' . source_bufnr . '), "&wrap", 1)'
  endif
  if &l:foldenable
    let restore .= '|call setwinvar(bufwinnr(' . source_bufnr . '), "&foldenable", 1)'
  endif

  " Line number of the first visible line in the window + &scrolloff
  let top = line('w0') + &scrolloff
  " Line number of the cursor
  let current = line('.')

  setlocal scrollbind nowrap nofoldenable
  exe 'keepalt leftabove vsplit ' . outfile
  setlocal nomodified nomodifiable nonumber scrollbind nowrap foldcolumn=0 nofoldenable filetype=mercenaryblame

  " When the current buffer containing the blame leaves the window, restore the
  " settings on the source window.
  call s:buffer().onwinleave(restore)

  " Synchronize the window position and cursor position between the blame buffer
  " and the code buffer.
  " Execute the line number as a command, focusing on that line (e.g. :23) to
  " synchronize the buffer scroll positions.
  execute top
  normal! zt
  " Synchronize the cursor position.
  execute current
  syncbind

  " Resize the window so we show all of the blame information, but none of the
  " code (the code is shown in the editing buffer :HGblame was invoked in).
  let blame_column_count = strlen(matchstr(getline('.'), '[^:]*:')) - 1
  execute "vertical resize " . blame_column_count

  " TODO(jlfwong): Maybe use winfixwidth to stop resizing of the blame window
endfunction

call s:add_command("HGblame call s:Blame()")

augroup mercenary_blame
  autocmd!
  autocmd BufReadPost *.mercenaryblame setfiletype mercenaryblame
augroup END

" }}}1
" Initialization and Routing {{{1

let s:method_handlers = {}

function! s:route(path) abort
  let hg_root_dir = s:extract_hg_root_dir(a:path)
  if hg_root_dir == ''
    return
  endif

  let mercenary_spec = matchstr(s:shellslash(a:path), '\C^mercenary://.\{-\}//\zs.*')

  if mercenary_spec != ''
    " Route the mercenary:// path
    let method = matchstr(mercenary_spec, '\C.\{-\}\ze:')

    " Arguments to the mercenary:// methods are delimited by //
    let args = split(matchstr(mercenary_spec, '\C:\zs.*'), '//')

    try
      if has_key(s:method_handlers, method)
        call call(s:method_handlers[method], args, s:method_handlers)
      else
        call s:warn('mercenary: unknown mercenary:// method ' . method)
      endif
    catch /^Vim\%((\a\+)\)\=:E118/
      call s:warn("mercenary: Too many arguments to mercenary://" . method)
    catch /^Vim\%((\a\+)\)\=:E119/
      call s:warn("mercenary: Not enough argument to mercenary://" . method)
    endtry
  end

  call s:buffer().enable_mercenary_commands()
endfunction

augroup mercenary
  autocmd!
  autocmd BufNewFile,BufReadPost * call s:route(expand('<amatch>:p'))
augroup END

" }}}1
" :HGcat {{{1

function! s:Cat(rev, path) abort
  execute 'edit ' . s:gen_mercenary_path('cat', a:rev, a:path)
endfunction

call s:add_command("-nargs=+ -complete=file HGcat call s:Cat(<f-args>)")

" }}}1
" mercenary://root_dir//cat:rev//filepath {{{1

function! s:method_handlers.cat(rev, filepath) dict abort
  " TODO(jlfwong): Error handling - (file not found, rev not fond)

  let args = ['cat', '--rev', a:rev, a:filepath]
  let hg_cat_command = call(s:repo().hg_command, args, s:repo())

  let temppath = resolve(tempname())
  let outfile = temppath . '.out'
  let errfile = temppath . '.err'

  silent! execute '!' . hg_cat_command . ' > ' . outfile . ' 2> ' . errfile

  silent! execute 'read ' . outfile
  " :read dumps the output below the current line - so delete the first line
  " (which will be empty)
  0d

  setlocal nomodified nomodifiable readonly

  if &bufhidden ==# ''
    " Delete the buffer when it becomes hidden
    setlocal bufhidden=delete
  endif
endfunction

" }}}1
" :HGshow {{{1

function! s:Show(rev) abort
  execute 'edit ' . s:gen_mercenary_path('show', a:rev)
endfunction

call s:add_command("-nargs=1 HGshow call s:Show(<f-args>)")


" }}}1
" mercenary://root_dir//show:rev {{{1

function! s:method_handlers.show(rev) dict abort
  " TODO(jlfwong): DRY this up w/ method_handlers.cat

  let args = ['log', '--stat', '-vpr', a:rev]
  let hg_log_command = call(s:repo().hg_command, args, s:repo())

  let temppath = resolve(tempname())
  let outfile = temppath . '.out'
  let errfile = temppath . '.err'

  silent! execute '!' . hg_log_command . ' > ' . outfile . ' 2> ' . errfile

  silent! execute 'read ' . outfile
  0d

  setlocal nomodified nomodifiable readonly
  setlocal filetype=diff

  if &bufhidden ==# ''
    " Delete the buffer when it becomes hidden
    setlocal bufhidden=delete
  endif
endfunction

" }}}1
" :HGdiff {{{1

function! s:Diff(...) abort
  if a:0 == 0
    let merc_p1_path = s:gen_mercenary_path('cat', 'p1()', s:buffer().relpath())

    silent! execute 'keepalt leftabove vsplit ' . merc_p1_path
    diffthis
    wincmd p

    let hg_parent_check_log_cmd = s:repo().hg_command('log', '--rev', 'p2()')

    if system(hg_parent_check_log_cmd) != ''
      let merc_p2_path = s:gen_mercenary_path('cat', 'p2()', s:buffer().relpath())
      silent! execute 'keepalt rightbelow vsplit ' . merc_p2_path
      diffthis
      wincmd p
    endif

    diffthis
  elseif a:0 == 1
    let rev = a:1

    let merc_path = s:gen_mercenary_path('cat', rev, s:buffer().relpath())

    silent! execute 'keepalt leftabove vsplit ' . merc_path
    diffthis
    wincmd p

    diffthis
  endif
endfunction

call s:add_command("-nargs=? HGdiff call s:Diff(<f-args>)")

" }}}1
