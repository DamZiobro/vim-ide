" ------------------------------------------------------------------------------
"
" Vim filetype plugin file
"
"   Language :  C++
"     Plugin :  c.vim 
" Maintainer :  Fritz Mehner <mehner.fritz@fh-swf.de>
"
" ------------------------------------------------------------------------------
"
" Only do this when not done yet for this buffer
" 
if exists("b:did_CPP_ftplugin")
  finish
endif
let b:did_CPP_ftplugin = 1
"
"-------------------------------------------------------------------------------
" additional mapping : C++ I/O
"-------------------------------------------------------------------------------
"
inoremap	<buffer>	>> <Space>>><Space>
inoremap	<buffer>	<< <Space><<<Space>
inoremap	<buffer>	<<" <Space><< ""<Space><Left><Left>
inoremap	<buffer>	<<; <Space><< "\n";<Left><Left><Left><Left>
"
