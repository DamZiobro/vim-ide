" Vim filetype plugin file
"
"   Language :  bash
"     Plugin :  bash-support.vim
" Maintainer :  Fritz Mehner <mehner@fh-swf.de>
"   Revision :  $Id: sh.vim,v 1.49 2013/01/01 12:57:32 mehner Exp $
"
" -----------------------------------------------------------------
"
" Only do this when not done yet for this buffer
" 
if exists("b:did_BASH_ftplugin")
  finish
endif
let b:did_BASH_ftplugin = 1
"
"------------------------------------------------------------------------------
"  Avoid a wrong syntax highlighting for $(..) and $((..))
"------------------------------------------------------------------------------
let b:is_bash           = 1
"
" ---------- Do we have a mapleader other than '\' ? ------------
"
if exists("g:BASH_MapLeader")
  let maplocalleader  = g:BASH_MapLeader
endif    
"
let s:MSWIN =   has("win16") || has("win32") || has("win64") || has("win95")
"
" ---------- BASH dictionary -----------------------------------
"
" This will enable keyword completion for bash
" using Vim's dictionary feature |i_CTRL-X_CTRL-K|.
" 
if exists("g:BASH_Dictionary_File")
  let save=&dictionary
  silent! exe 'setlocal dictionary='.g:BASH_Dictionary_File
  silent! exe 'setlocal dictionary+='.save
endif    
"
command! -nargs=* -complete=file                                BashCmdlineArgs     call BASH_ScriptCmdLineArguments(<q-args>)
command! -nargs=1 -complete=customlist,BASH_KeywordCommentList  BashKeywordComment  call BASH_KeywordCommentListInsert(<f-args>)
command! -nargs=1 -complete=customlist,BASH_ScriptSectionList   BashScriptSection   call BASH_ScriptSectionListInsert(<f-args>)
command! -nargs=1 -complete=customlist,BASH_StyleList   				BashStyle   		    call BASH_Style(<f-args>)
"
" ---------- hot keys ------------------------------------------
"
"   Alt-F9   run syntax check
"  Ctrl-F9   update file and run script
" Shift-F9   command line arguments
"
if has("gui_running")
  "
   map  <buffer>  <silent>  <S-F1>        :call BASH_HelpBASHsupport()<CR>
  imap  <buffer>  <silent>  <S-F1>   <C-C>:call BASH_HelpBASHsupport()<CR>
  "
   map  <buffer>  <silent>  <A-F9>        :call BASH_SyntaxCheck()<CR>
  imap  <buffer>  <silent>  <A-F9>   <C-C>:call BASH_SyntaxCheck()<CR>
  "
   map  <buffer>  <silent>  <C-F9>        :call BASH_Run("n")<CR>
  imap  <buffer>  <silent>  <C-F9>   <C-C>:call BASH_Run("n")<CR>
  if !s:MSWIN
    vmap  <buffer>  <silent>  <C-F9>   <C-C>:call BASH_Run("v")<CR>
  endif
  "
  map   <buffer>            <S-F9>        :BashCmdlineArgs<Space>
  imap  <buffer>            <S-F9>   <C-C>:BashCmdlineArgs<Space>
endif
"
if !s:MSWIN
   map  <buffer>  <silent>    <F9>        :call BASH_Debugger()<CR>
  imap  <buffer>  <silent>    <F9>   <C-C>:call BASH_Debugger()<CR>
endif
"
"
" ---------- help ----------------------------------------------------
"
 noremap  <buffer>  <silent>  <LocalLeader>hb            :call BASH_help('bash')<CR>
inoremap  <buffer>  <silent>  <LocalLeader>hb       <Esc>:call BASH_help('bash')<CR>
"
 noremap  <buffer>  <silent>  <LocalLeader>hh            :call BASH_help('help')<CR>
inoremap  <buffer>  <silent>  <LocalLeader>hh       <Esc>:call BASH_help('help')<CR>
"
 noremap  <buffer>  <silent>  <LocalLeader>hm            :call BASH_help('man')<CR>
inoremap  <buffer>  <silent>  <LocalLeader>hm       <Esc>:call BASH_help('man')<CR>
"
 noremap  <buffer>  <silent>  <LocalLeader>hbs          :call BASH_HelpBASHsupport()<CR>
inoremap  <buffer>  <silent>  <LocalLeader>hbs     <Esc>:call BASH_HelpBASHsupport()<CR>
"
" ---------- comment menu ----------------------------------------------------
"
 noremap  <buffer>  <silent>  <LocalLeader>cl           :call BASH_EndOfLineComment()<CR>
inoremap  <buffer>  <silent>  <LocalLeader>cl      <Esc>:call BASH_EndOfLineComment()<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>cl      <Esc>:call BASH_MultiLineEndComments()<CR>A

 noremap  <buffer>  <silent>  <LocalLeader>cj           :call BASH_AdjustLineEndComm()<CR>
inoremap  <buffer>  <silent>  <LocalLeader>cj      <Esc>:call BASH_AdjustLineEndComm()<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>cj           :call BASH_AdjustLineEndComm()<CR>

 noremap  <buffer>  <silent>  <LocalLeader>cs           :call BASH_GetLineEndCommCol()<CR>
inoremap  <buffer>  <silent>  <LocalLeader>cs      <Esc>:call BASH_GetLineEndCommCol()<CR>

 noremap  <buffer>  <silent>  <LocalLeader>cfr          :call BASH_InsertTemplate("comment.frame")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>cfr     <Esc>:call BASH_InsertTemplate("comment.frame")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>cfu          :call BASH_InsertTemplate("comment.function")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>cfu     <Esc>:call BASH_InsertTemplate("comment.function")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>ch           :call BASH_InsertTemplate("comment.file-description")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>ch      <Esc>:call BASH_InsertTemplate("comment.file-description")<CR>

 noremap    <buffer>  <silent>  <LocalLeader>cc         :call BASH_CommentToggle()<CR>j
inoremap    <buffer>  <silent>  <LocalLeader>cc    <Esc>:call BASH_CommentToggle()<CR>j
vnoremap    <buffer>  <silent>  <LocalLeader>cc         :call BASH_CommentToggle()<CR>j

 noremap  <buffer>  <silent>  <LocalLeader>cd           :call BASH_InsertDateAndTime('d')<CR>
inoremap  <buffer>  <silent>  <LocalLeader>cd      <Esc>:call BASH_InsertDateAndTime('d')<CR>a
vnoremap  <buffer>  <silent>  <LocalLeader>cd     s<Esc>:call BASH_InsertDateAndTime('d')<CR>

 noremap  <buffer>  <silent>  <LocalLeader>ct           :call BASH_InsertDateAndTime('dt')<CR>
inoremap  <buffer>  <silent>  <LocalLeader>ct      <Esc>:call BASH_InsertDateAndTime('dt')<CR>a
vnoremap  <buffer>  <silent>  <LocalLeader>ct     s<Esc>:call BASH_InsertDateAndTime('dt')<CR>

 noremap  <buffer>  <silent>  <LocalLeader>ckb     $:call BASH_InsertTemplate("comment.keyword-bug")       <CR>
 noremap  <buffer>  <silent>  <LocalLeader>ckt     $:call BASH_InsertTemplate("comment.keyword-todo")      <CR>
 noremap  <buffer>  <silent>  <LocalLeader>ckr     $:call BASH_InsertTemplate("comment.keyword-tricky")    <CR>
 noremap  <buffer>  <silent>  <LocalLeader>ckw     $:call BASH_InsertTemplate("comment.keyword-warning")   <CR>
 noremap  <buffer>  <silent>  <LocalLeader>cko     $:call BASH_InsertTemplate("comment.keyword-workaround")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>ckn     $:call BASH_InsertTemplate("comment.keyword-keyword")   <CR>

inoremap  <buffer>  <silent>  <LocalLeader>ckb     <C-C>$:call BASH_InsertTemplate("comment.keyword-bug")       <CR>
inoremap  <buffer>  <silent>  <LocalLeader>ckt     <C-C>$:call BASH_InsertTemplate("comment.keyword-todo")      <CR>
inoremap  <buffer>  <silent>  <LocalLeader>ckr     <C-C>$:call BASH_InsertTemplate("comment.keyword-tricky")    <CR>
inoremap  <buffer>  <silent>  <LocalLeader>ckw     <C-C>$:call BASH_InsertTemplate("comment.keyword-warning")   <CR>
inoremap  <buffer>  <silent>  <LocalLeader>cko     <C-C>$:call BASH_InsertTemplate("comment.keyword-workaround")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>ckn     <C-C>$:call BASH_InsertTemplate("comment.keyword-keyword")   <CR>

 noremap  <buffer>  <silent>  <LocalLeader>ce           :call BASH_echo_comment()<CR>j'
inoremap  <buffer>  <silent>  <LocalLeader>ce      <C-C>:call BASH_echo_comment()<CR>j'
 noremap  <buffer>  <silent>  <LocalLeader>cr           :call BASH_remove_echo()<CR>j'
inoremap  <buffer>  <silent>  <LocalLeader>cr      <C-C>:call BASH_remove_echo()<CR>j'
 noremap  <buffer>  <silent>  <LocalLeader>cv           :call BASH_CommentVimModeline()<CR>
inoremap  <buffer>  <silent>  <LocalLeader>cv      <C-C>:call BASH_CommentVimModeline()<CR>
"
 noremap    <buffer>            <LocalLeader>css   <Esc>:ScriptSection<Space>
inoremap    <buffer>            <LocalLeader>css   <Esc>:ScriptSection<Space>
 noremap    <buffer>            <LocalLeader>ckc   <Esc>:KeywordComment<Space>
inoremap    <buffer>            <LocalLeader>ckc   <Esc>:KeywordComment<Space>
"
" ---------- statement menu ----------------------------------------------------
"
 noremap  <buffer>  <silent>  <LocalLeader>sc           :call BASH_InsertTemplate("statements.case")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>sei          :call BASH_InsertTemplate("statements.elif")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>sf           :call BASH_InsertTemplate("statements.for-in")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>sfo          :call BASH_InsertTemplate("statements.for")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>si           :call BASH_InsertTemplate("statements.if")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>sie          :call BASH_InsertTemplate("statements.if-else")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>ss           :call BASH_InsertTemplate("statements.select")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>su           :call BASH_InsertTemplate("statements.until")<CR>
 noremap  <buffer>  <silent>  <LocalLeader>sw           :call BASH_InsertTemplate("statements.while")<CR>

inoremap  <buffer>  <silent>  <LocalLeader>sc      <Esc>:call BASH_InsertTemplate("statements.case")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>sei     <Esc>:call BASH_InsertTemplate("statements.elif")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>sf      <Esc>:call BASH_InsertTemplate("statements.for-in")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>sfo     <Esc>:call BASH_InsertTemplate("statements.for")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>si      <Esc>:call BASH_InsertTemplate("statements.if")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>sie     <Esc>:call BASH_InsertTemplate("statements.if-else")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>ss      <Esc>:call BASH_InsertTemplate("statements.select")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>su      <Esc>:call BASH_InsertTemplate("statements.until")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>sw      <Esc>:call BASH_InsertTemplate("statements.while")<CR>

vnoremap  <buffer>  <silent>  <LocalLeader>sf      <Esc>:call BASH_InsertTemplate("statements.for-in", "v")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>sfo     <Esc>:call BASH_InsertTemplate("statements.for", "v")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>si      <Esc>:call BASH_InsertTemplate("statements.if", "v")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>sie     <Esc>:call BASH_InsertTemplate("statements.if-else", "v")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>ss      <Esc>:call BASH_InsertTemplate("statements.select", "v")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>su      <Esc>:call BASH_InsertTemplate("statements.until", "v")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>sw      <Esc>:call BASH_InsertTemplate("statements.while", "v")<CR>

 noremap  <buffer>  <silent>  <LocalLeader>sfu          :call BASH_InsertTemplate("statements.function")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>sfu     <Esc>:call BASH_InsertTemplate("statements.function")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>sfu     <Esc>:call BASH_InsertTemplate("statements.function", "v")<CR>

 noremap  <buffer>  <silent>  <LocalLeader>sp           :call BASH_InsertTemplate("statements.printf")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>sp      <Esc>:call BASH_InsertTemplate("statements.printf")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>sp      <Esc>:call BASH_InsertTemplate("statements.printf", "v")<CR>
                                                                                                                 
 noremap  <buffer>  <silent>  <LocalLeader>se           :call BASH_InsertTemplate("statements.echo")<CR>
inoremap  <buffer>  <silent>  <LocalLeader>se      <Esc>:call BASH_InsertTemplate("statements.echo")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>se      <Esc>:call BASH_InsertTemplate("statements.echo", "v")<CR>

 noremap  <buffer>  <silent>  <LocalLeader>sa      a${[]}<Left><Left><Left>
inoremap  <buffer>  <silent>  <LocalLeader>sa       ${[]}<Left><Left><Left>
vnoremap  <buffer>  <silent>  <LocalLeader>sa      s${[]}<Left><Left><Esc>P

 noremap  <buffer>  <silent>  <LocalLeader>saa     a${[@]}<Left><Left><Left><Left>
inoremap  <buffer>  <silent>  <LocalLeader>saa      ${[@]}<Left><Left><Left><Left>
vnoremap  <buffer>  <silent>  <LocalLeader>saa     s${[@]}<Left><Left><Left><Esc>P

 noremap  <buffer>  <silent>  <LocalLeader>sa1     a${[*]}<Left><Left><Left><Left>
inoremap  <buffer>  <silent>  <LocalLeader>sa1      ${[*]}<Left><Left><Left><Left>
vnoremap  <buffer>  <silent>  <LocalLeader>sa1     s${[*]}<Left><Left><Left><Esc>P

 noremap  <buffer>  <silent>  <LocalLeader>ssa     a${[@]::}<Left><Left><Left><Left><Left><Left>
inoremap  <buffer>  <silent>  <LocalLeader>ssa      ${[@]::}<Left><Left><Left><Left><Left><Left>
vnoremap  <buffer>  <silent>  <LocalLeader>ssa     s${[@]::}<Left><Left><Left><Left><Left><Esc>P

 noremap  <buffer>  <silent>  <LocalLeader>san     a${#[@]}<Left><Left><Left><Left>
inoremap  <buffer>  <silent>  <LocalLeader>san      ${#[@]}<Left><Left><Left><Left>
vnoremap  <buffer>  <silent>  <LocalLeader>san     s${#[@]}<Left><Left><Left><Esc>P

 noremap  <buffer>  <silent>  <LocalLeader>sai     a${![*]}<Left><Left><Left><Left>
inoremap  <buffer>  <silent>  <LocalLeader>sai      ${![*]}<Left><Left><Left><Left>
vnoremap  <buffer>  <silent>  <LocalLeader>sai     s${![*]}<Left><Left><Left><Esc>P
  "
  " ----------------------------------------------------------------------------
  " POSIX character classes
  " ----------------------------------------------------------------------------
  "
nnoremap  <buffer>  <silent>  <LocalLeader>xm   a[[  =~  ]]<Left><Left><Left><Left><Left><Left><Left>
inoremap  <buffer>  <silent>  <LocalLeader>xm    [[  =~  ]]<Left><Left><Left><Left><Left><Left><Left>
  "
nnoremap  <buffer>  <silent>  <LocalLeader>pan   a[:alnum:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>pal    a[:alpha:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>pas    a[:ascii:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>pb    a[:blank:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>pc    a[:cntrl:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>pd    a[:digit:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>pg    a[:graph:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>pl    a[:lower:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>ppr   a[:print:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>ppu   a[:punct:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>ps    a[:space:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>pu    a[:upper:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>pw    a[:word:]<Esc>
nnoremap  <buffer>  <silent>  <LocalLeader>px    a[:xdigit:]<Esc>
"
inoremap  <buffer>  <silent>  <LocalLeader>pan   [:alnum:]
inoremap  <buffer>  <silent>  <LocalLeader>pal   [:alpha:]
inoremap  <buffer>  <silent>  <LocalLeader>pas   [:ascii:]
inoremap  <buffer>  <silent>  <LocalLeader>pb    [:blank:]
inoremap  <buffer>  <silent>  <LocalLeader>pc    [:cntrl:]
inoremap  <buffer>  <silent>  <LocalLeader>pd    [:digit:]
inoremap  <buffer>  <silent>  <LocalLeader>pg    [:graph:]
inoremap  <buffer>  <silent>  <LocalLeader>pl    [:lower:]
inoremap  <buffer>  <silent>  <LocalLeader>ppr   [:print:]
inoremap  <buffer>  <silent>  <LocalLeader>ppu   [:punct:]
inoremap  <buffer>  <silent>  <LocalLeader>ps    [:space:]
inoremap  <buffer>  <silent>  <LocalLeader>pu    [:upper:]
inoremap  <buffer>  <silent>  <LocalLeader>pw    [:word:]
inoremap  <buffer>  <silent>  <LocalLeader>px    [:xdigit:]
"
" ---------- snippet menu ----------------------------------------------------
"
nnoremap  <buffer>  <silent>  <LocalLeader>nr         :call BASH_CodeSnippets("read")<CR>
nnoremap  <buffer>  <silent>  <LocalLeader>nv         :call BASH_CodeSnippets("view")<CR>
nnoremap  <buffer>  <silent>  <LocalLeader>nw         :call BASH_CodeSnippets("write")<CR>
vnoremap  <buffer>  <silent>  <LocalLeader>nw    <C-C>:call BASH_CodeSnippets("writemarked")<CR>
nnoremap  <buffer>  <silent>  <LocalLeader>ne         :call BASH_CodeSnippets("edit")<CR>
"
nnoremap  <buffer>  <silent>  <LocalLeader>ntl        :call BASH_BrowseTemplateFiles("Local")<CR>
nnoremap  <buffer>  <silent>  <LocalLeader>ntg        :call BASH_BrowseTemplateFiles("Global")<CR> 
nnoremap  <buffer>  <silent>  <LocalLeader>ntr        :call BASH_RereadTemplates()<CR>
nnoremap  <buffer>            <LocalLeader>nts        :BashStyle<Space>
"
 inoremap  <buffer>  <silent>  <LocalLeader>nr    <Esc>:call BASH_CodeSnippets("read")<CR>
 inoremap  <buffer>  <silent>  <LocalLeader>nv    <Esc>:call BASH_CodeSnippets("view")<CR>
 inoremap  <buffer>  <silent>  <LocalLeader>nw    <Esc>:call BASH_CodeSnippets("write")<CR>
 inoremap  <buffer>  <silent>  <LocalLeader>ne    <Esc>:call BASH_CodeSnippets("edit")<CR>
"
 inoremap  <buffer>  <silent>  <LocalLeader>ntl   <Esc>:call BASH_BrowseTemplateFiles("Local")<CR>
 inoremap  <buffer>  <silent>  <LocalLeader>ntg   <Esc>:call BASH_BrowseTemplateFiles("Global")<CR> 
 inoremap  <buffer>  <silent>  <LocalLeader>ntr   <Esc>:call BASH_RereadTemplates()<CR>
 inoremap  <buffer>            <LocalLeader>nts   <Esc>:BashStyle<Space>
"
" ---------- test  ----------------------------------------------------
"
nnoremap  <buffer>  <silent>  <LocalLeader>t1   a[ -  ]<Left><Left><Left>
inoremap  <buffer>  <silent>  <LocalLeader>t1    [ -  ]<Left><Left><Left>
"
nnoremap  <buffer>  <silent>  <LocalLeader>t2   a[  -  ]<Left><Left><Left><Left><Left>
inoremap  <buffer>  <silent>  <LocalLeader>t2    [  -  ]<Left><Left><Left><Left><Left>
"
" ---------- run menu ----------------------------------------------------
"
 map  <buffer>  <silent>  <LocalLeader>rr           :call BASH_Run("n")<CR>
imap  <buffer>  <silent>  <LocalLeader>rr      <Esc>:call BASH_Run("n")<CR>
 map  <buffer>            <LocalLeader>ra           :BashCmdlineArgs<Space>
imap  <buffer>            <LocalLeader>ra      <Esc>:BashCmdlineArgs<Space>
 map  <buffer>  <silent>  <LocalLeader>rba          :call BASH_BashCmdLineArguments()<CR>
imap  <buffer>  <silent>  <LocalLeader>rba     <Esc>:call BASH_BashCmdLineArguments()<CR>

 map  <buffer>  <silent>  <LocalLeader>rc           :call BASH_SyntaxCheck()<CR>
imap  <buffer>  <silent>  <LocalLeader>rc      <Esc>:call BASH_SyntaxCheck()<CR>

 map  <buffer>  <silent>  <LocalLeader>rco          :call BASH_SyntaxCheckOptionsLocal()<CR>
imap  <buffer>  <silent>  <LocalLeader>rco     <Esc>:call BASH_SyntaxCheckOptionsLocal()<CR>

if !s:MSWIN
   map  <buffer> <silent> <LocalLeader>re           :call BASH_MakeScriptExecutable()<CR>
  imap  <buffer> <silent> <LocalLeader>re      <Esc>:call BASH_MakeScriptExecutable()<CR>

   map  <buffer>  <silent>  <LocalLeader>rd           :call BASH_Debugger()<CR>
  imap  <buffer>  <silent>  <LocalLeader>rd      <Esc>:call BASH_Debugger()<CR>

  vmap  <buffer>  <silent>  <LocalLeader>rr      <Esc>:call BASH_Run("v")<CR>

  if has("gui_running")
     map  <buffer>  <silent>  <LocalLeader>rt           :call BASH_XtermSize()<CR>
    imap  <buffer>  <silent>  <LocalLeader>rt      <Esc>:call BASH_XtermSize()<CR>
  endif
endif

 map  <buffer>  <silent>  <LocalLeader>rh           :call BASH_Hardcopy("n")<CR>
imap  <buffer>  <silent>  <LocalLeader>rh      <Esc>:call BASH_Hardcopy("n")<CR>
vmap  <buffer>  <silent>  <LocalLeader>rh      <Esc>:call BASH_Hardcopy("v")<CR>
"
 map  <buffer>  <silent>  <LocalLeader>rs           :call BASH_Settings()<CR>
imap  <buffer>  <silent>  <LocalLeader>rs      <Esc>:call BASH_Settings()<CR>

if s:MSWIN
   map  <buffer>  <silent>  <LocalLeader>ro           :call BASH_Toggle_Gvim_Xterm_MS()<CR>
  imap  <buffer>  <silent>  <LocalLeader>ro      <Esc>:call BASH_Toggle_Gvim_Xterm_MS()<CR>
else
   map  <buffer>  <silent>  <LocalLeader>ro           :call BASH_Toggle_Gvim_Xterm()<CR>
  imap  <buffer>  <silent>  <LocalLeader>ro      <Esc>:call BASH_Toggle_Gvim_Xterm()<CR>
endif

"-------------------------------------------------------------------------------
" additional mapping : single quotes around a Word (non-whitespaces)
"                      masks the normal mode command '' (jump to the position
"                      before the latest jump)
" additional mapping : double quotes around a Word (non-whitespaces)
"-------------------------------------------------------------------------------
nnoremap    <buffer>   ''   ciW''<Esc>P
nnoremap    <buffer>   ""   ciW""<Esc>P
"
if !exists("g:BASH_Ctrl_j") || ( exists("g:BASH_Ctrl_j") && g:BASH_Ctrl_j != 'off' )
  nmap    <buffer>  <silent>  <C-j>   i<C-R>=BASH_JumpCtrlJ()<CR>
  imap    <buffer>  <silent>  <C-j>    <C-R>=BASH_JumpCtrlJ()<CR>
endif
