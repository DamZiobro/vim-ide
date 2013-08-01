" cmake.vim - Vim plugin to make working with CMake a little nicer
" Maintainer:   Dirk Van Haerenborgh <http://vhdirk.github.com/>
" Version:      0.1

let s:cmake_plugin_version = '0.1'

if exists("loaded_cmake_plugin")
  finish
endif
let loaded_cmake_plugin = 1

" Utility function
" Thanks to tpope/vim-fugitive
function! s:fnameescape(file) abort
  if exists('*fnameescape')
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction


" Public Interface:
command! -nargs=? CMake call s:cmake(<f-args>)

function! s:cmake(...)

  let s:build_dir = finddir('build', '.;')
  let &makeprg='make --directory=' . s:build_dir

  exec 'cd' s:fnameescape(s:build_dir)
  
  let s:cmd = 'cmake '. join(a:000) .' .. '
  echo s:cmd
  let s:res = system(s:cmd)
  echo s:res

  exec 'cd - '

endfunction
