"#################################################################################
"
"       Filename:  c.vim
"
"    Description:  C/C++-IDE. Write programs by inserting complete statements,
"                  comments, idioms, code snippets, templates and comments.
"                  Compile, link and run one-file-programs without a makefile.
"                  See also help file csupport.txt .
"
"   GVIM Version:  7.0+
"
"  Configuration:  There are some personal details which should be configured
"                   (see the files README.csupport and csupport.txt).
"
"         Author:  Dr.-Ing. Fritz Mehner, FH Südwestfalen, 58644 Iserlohn, Germany
"          Email:  mehner.fritz@fh-swf.de
"
"        Version:  see variable  g:C_Version  below
"        Created:  04.11.2000
"        License:  Copyright (c) 2000-2012, Fritz Mehner
"                  This program is free software; you can redistribute it and/or
"                  modify it under the terms of the GNU General Public License as
"                  published by the Free Software Foundation, version 2 of the
"                  License.
"                  This program is distributed in the hope that it will be
"                  useful, but WITHOUT ANY WARRANTY; without even the implied
"                  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
"                  PURPOSE.
"                  See the GNU General Public License version 2 for more details.
"
"------------------------------------------------------------------------------
"
if v:version < 700
  echohl WarningMsg | echo 'The plugin c-support.vim needs Vim version >= 7 .'| echohl None
  finish
endif
"
" Prevent duplicate loading:
"
if exists("g:C_Version") || &cp
 finish
endif
let g:C_Version= "6.0"  							" version number of this script; do not change
"
"#################################################################################
"
"  Global variables (with default values) which can be overridden.
"
" Platform specific items:  {{{1
" - root directory
" - characters that must be escaped for filenames
"
let s:MSWIN = has("win16") || has("win32")   || has("win64")    || has("win95")
let s:UNIX	= has("unix")  || has("macunix") || has("win32unix")
"
let g:C_Installation				= '*undefined*'
let s:plugin_dir						= ''
"
let s:C_GlobalTemplateFile	= ''
let s:C_GlobalTemplateDir		= ''
let s:C_LocalTemplateFile		= ''
let s:C_LocalTemplateDir		= ''
let s:C_FilenameEscChar 		= ''

if	s:MSWIN
  " ==========  MS Windows  ======================================================
	"
	" change '\' to '/' to avoid interpretation as escape character
	if match(	substitute( expand("<sfile>"), '\', '/', 'g' ), 
				\		substitute( expand("$HOME"),   '\', '/', 'g' ) ) == 0
		"
		" USER INSTALLATION ASSUMED
		let g:C_Installation				= 'local'
		let s:plugin_dir  					= substitute( expand('<sfile>:p:h:h'), '\', '/', 'g' )
		let s:C_LocalTemplateFile		= s:plugin_dir.'/c-support/templates/Templates'
		let s:C_LocalTemplateDir		= fnamemodify( s:C_LocalTemplateFile, ":p:h" ).'/'
	else
		"
		" SYSTEM WIDE INSTALLATION
		let g:C_Installation				= 'system'
		let s:plugin_dir						= $VIM.'/vimfiles'
		let s:C_GlobalTemplateDir		= s:plugin_dir.'/c-support/templates'
		let s:C_GlobalTemplateFile  = s:C_GlobalTemplateDir.'/Templates'
		let s:C_LocalTemplateFile		= $HOME.'/vimfiles/c-support/templates/Templates'
		let s:C_LocalTemplateDir		= fnamemodify( s:C_LocalTemplateFile, ":p:h" ).'/'
	endif
	"
  let s:C_FilenameEscChar 			= ''
	"
else
  " ==========  Linux/Unix  ======================================================
	"
	if match( expand("<sfile>"), resolve( expand("$HOME") ) ) == 0
		" USER INSTALLATION ASSUMED
		let g:C_Installation				= 'local'
		let s:plugin_dir 						= expand('<sfile>:p:h:h')
		let s:C_LocalTemplateFile		= s:plugin_dir.'/c-support/templates/Templates'
		let s:C_LocalTemplateDir		= fnamemodify( s:C_LocalTemplateFile, ":p:h" ).'/'
	else
		" SYSTEM WIDE INSTALLATION
		let g:C_Installation				= 'system'
		let s:plugin_dir						= $VIM.'/vimfiles'
		let s:C_GlobalTemplateDir		= s:plugin_dir.'/c-support/templates'
		let s:C_GlobalTemplateFile  = s:C_GlobalTemplateDir.'/Templates'
		let s:C_LocalTemplateFile		= $HOME.'/.vim/c-support/templates/Templates'
		let s:C_LocalTemplateDir		= fnamemodify( s:C_LocalTemplateFile, ":p:h" ).'/'
	endif
	"
  let s:C_FilenameEscChar 			= ' \%#[]'
	"
endif
"
let s:C_CodeSnippets  				= s:plugin_dir.'/c-support/codesnippets/'
let s:C_IndentErrorLog				= $HOME.'/.indent.errorlog'
"
"  Use of dictionaries  {{{1
"  Key word completion is enabled by the filetype plugin 'c.vim'
"  g:C_Dictionary_File  must be global
"
if !exists("g:C_Dictionary_File")
  let g:C_Dictionary_File = s:plugin_dir.'/c-support/wordlists/c-c++-keywords.list,'.
        \                   s:plugin_dir.'/c-support/wordlists/k+r.list,'.
        \                   s:plugin_dir.'/c-support/wordlists/stl_index.list'
endif
"
"  Modul global variables (with default values) which can be overridden. {{{1
"
if	s:MSWIN
	let s:C_CCompiler           = 'gcc.exe'  " the C   compiler
	let s:C_CplusCompiler       = 'g++.exe'  " the C++ compiler
	let s:C_ExeExtension        = '.exe'     " file extension for executables (leading point required)
	let s:C_ObjExtension        = '.obj'     " file extension for objects (leading point required)
	let s:C_Man                 = 'man.exe'  " the manual program
else
	let s:C_CCompiler           = 'gcc'      " the C   compiler
	let s:C_CplusCompiler       = 'g++'      " the C++ compiler
	let s:C_ExeExtension        = ''         " file extension for executables (leading point required)
	let s:C_ObjExtension        = '.o'       " file extension for objects (leading point required)
	let s:C_Man                 = 'man'      " the manual program
endif
let s:C_VimCompilerName				= 'gcc'      " the compiler name used by :compiler
"
let s:C_CFlags         				= '-Wall -g -O0 -c'      " C compiler flags: compile, don't optimize
let s:C_LFlags         				= '-Wall -g -O0'         " C compiler flags: link   , don't optimize
let s:C_Libs           				= '-lm'                  " C libraries to use
"
let s:C_CplusCFlags         	= '-Wall -g -O0 -c'      " C++ compiler flags: compile, don't optimize
let s:C_CplusLFlags         	= '-Wall -g -O0'         " C++ compiler flags: link   , don't optimize
let s:C_CplusLibs           	= '-lm'                  " C++ libraries to use
"
let s:C_CExtension     				= 'c'                    " C file extension; everything else is C++
let s:C_CodeCheckExeName      = 'check'
let s:C_CodeCheckOptions      = '-K13'
let s:C_LineEndCommColDefault = 49
let s:C_LoadMenus      				= 'yes'
let s:C_CreateMenusDelayed    = 'no'
let s:C_MenuHeader     				= 'yes'
let s:C_OutputGvim            = 'vim'
let s:C_Printheader           = "%<%f%h%m%<  %=%{strftime('%x %X')}     Page %N"
let s:C_RootMenu  	   				= '&C\/C\+\+.'           " the name of the root menu of this plugin
let s:C_TypeOfH               = 'cpp'
let s:C_Wrapper               = s:plugin_dir.'/c-support/scripts/wrapper.sh'
let s:C_XtermDefaults         = '-fa courier -fs 12 -geometry 80x24'
let s:C_GuiSnippetBrowser     = 'gui'										" gui / commandline
let s:C_GuiTemplateBrowser    = 'gui'										" gui / explorer / commandline
"
let s:C_Ctrl_j								= 'on'
"
let s:C_FormatDate						= '%x'
let s:C_FormatTime						= '%X'
let s:C_FormatYear						= '%Y'
let s:C_SourceCodeExtensions  = 'c cc cp cxx cpp CPP c++ C i ii'
let g:C_MapLeader							= '\'
let s:C_CppcheckSeverity			= 'all'
"
"------------------------------------------------------------------------------
"
"  Look for global variables (if any), to override the defaults.
"
function! C_CheckGlobal ( name )
  if exists('g:'.a:name)
    exe 'let s:'.a:name.'  = g:'.a:name
  endif
endfunction    " ----------  end of function C_CheckGlobal ----------
"
call C_CheckGlobal('C_CCompiler            ')
call C_CheckGlobal('C_CExtension           ')
call C_CheckGlobal('C_CFlags               ')
call C_CheckGlobal('C_LFlags               ')
call C_CheckGlobal('C_Libs                 ')
call C_CheckGlobal('C_CplusCFlags          ')
call C_CheckGlobal('C_CplusLFlags          ')
call C_CheckGlobal('C_CplusLibs            ')
call C_CheckGlobal('C_CodeCheckExeName     ')
call C_CheckGlobal('C_CodeCheckOptions     ')
call C_CheckGlobal('C_CodeSnippets         ')
call C_CheckGlobal('C_CplusCompiler        ')
call C_CheckGlobal('C_CreateMenusDelayed   ')
call C_CheckGlobal('C_Ctrl_j               ')
call C_CheckGlobal('C_ExeExtension         ')
call C_CheckGlobal('C_FormatDate           ')
call C_CheckGlobal('C_FormatTime           ')
call C_CheckGlobal('C_FormatYear           ')
call C_CheckGlobal('C_GlobalTemplateFile   ')
call C_CheckGlobal('C_GuiSnippetBrowser    ')
call C_CheckGlobal('C_GuiTemplateBrowser   ')
call C_CheckGlobal('C_IndentErrorLog       ')
call C_CheckGlobal('C_LineEndCommColDefault')
call C_CheckGlobal('C_LoadMenus            ')
call C_CheckGlobal('C_LocalTemplateFile    ')
call C_CheckGlobal('C_Man                  ')
call C_CheckGlobal('C_MenuHeader           ')
call C_CheckGlobal('C_ObjExtension         ')
call C_CheckGlobal('C_OutputGvim           ')
call C_CheckGlobal('C_Printheader          ')
call C_CheckGlobal('C_RootMenu             ')
call C_CheckGlobal('C_SourceCodeExtensions ')
call C_CheckGlobal('C_TypeOfH              ')
call C_CheckGlobal('C_VimCompilerName      ')
call C_CheckGlobal('C_XtermDefaults        ')

if exists('g:C_GlobalTemplateFile') && !empty(g:C_GlobalTemplateFile)
	let s:C_GlobalTemplateDir	= fnamemodify( s:C_GlobalTemplateFile, ":h" )
endif
"
"----- some variables for internal use only -----------------------------------
"
"
" set default geometry if not specified
"
if match( s:C_XtermDefaults, "-geometry\\s\\+\\d\\+x\\d\\+" ) < 0
	let s:C_XtermDefaults	= s:C_XtermDefaults." -geometry 80x24"
endif
"
" escape the printheader
"
let s:C_Printheader  = escape( s:C_Printheader, ' %' )
"
let s:C_HlMessage    = ""
"
" characters that must be escaped for filenames
"
let s:C_If0_Counter   = 0
let s:C_If0_Txt		 		= "If0Label_"
"
let s:C_SplintIsExecutable		= executable( "splint" )
let s:C_CppcheckIsExecutable	= executable( "cppcheck" )
let s:C_CodeCheckIsExecutable	= executable( s:C_CodeCheckExeName )
let s:C_IndentIsExecutable		= executable( "indent" )
"
"------------------------------------------------------------------------------
"  Control variables (not user configurable)
"------------------------------------------------------------------------------
"
let s:C_Com1          			= '/*'     " C-style : comment start
let s:C_Com2          			= '*/'     " C-style : comment end
"
let s:C_TJT									= '[ 0-9a-zA-Z_]*'
let s:C_TemplateJumpTarget1 = '<+'.s:C_TJT.'+>\|{+'.s:C_TJT.'+}'
let s:C_TemplateJumpTarget2 = '<-'.s:C_TJT.'->\|{-'.s:C_TJT.'-}'
let s:C_TemplatesLoaded			= 'no'

let s:C_ForTypes     = [
    \ 'char'                  ,
    \ 'int'                   ,
    \ 'long'                  ,
    \ 'long int'              ,
    \ 'long long'             ,
    \ 'long long int'         ,
    \ 'short'                 ,
    \ 'short int'             ,
    \ 'size_t'                ,
    \ 'unsigned'              , 
    \ 'unsigned char'         ,
    \ 'unsigned int'          ,
    \ 'unsigned long'         ,
    \ 'unsigned long int'     ,
    \ 'unsigned long long'    ,
    \ 'unsigned long long int',
    \ 'unsigned short'        ,
    \ 'unsigned short int'    ,
    \ ]

let s:MsgInsNotAvail	= "insertion not available for a fold" 
let s:MenuRun         = s:C_RootMenu.'&Run'

let	s:output1	= 'VIM->buffer->xterm'
let	s:output2	= 'BUFFER->xterm->vim'
let	s:output3	= 'XTERM->vim->buffer'

let s:C_saved_global_option				= {}
let s:C_SourceCodeExtensionsList	= split( s:C_SourceCodeExtensions, '\s\+' )
"
let s:CppcheckSeverity	= [ "all", "error", "warning", "style", "performance", "portability", "information" ]
"
"===  FUNCTION  ================================================================
"          NAME:  C_MenuTitle     {{{1
"   DESCRIPTION:  display warning
"    PARAMETERS:  -
"       RETURNS:  
"===============================================================================
function! C_MenuTitle ()
		echohl WarningMsg | echo "This is a menu header." | echohl None
endfunction    " ----------  end of function C_MenuTitle  ----------

"------------------------------------------------------------------------------
"  C : C_InitMenus                              {{{1
"  Initialization of C support menus
"------------------------------------------------------------------------------
"
function! s:C_InitMenus ()
	"
	if ! has ( 'menu' )
		return
	endif
	"
	" Preparation
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'do_reset' )
	"
	exe 'amenu '.s:C_RootMenu.'C\/C\+\+ <Nop>'
	exe 'amenu '.s:C_RootMenu.'-Sep00-  <Nop>'
"
	"===============================================================================================
	"----- Menu : C-Comments --------------------------------------------------   {{{2
	"===============================================================================================
	"
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Comments' )
	let	MenuComments	= s:C_RootMenu.'&Comments'
	"
	exe "amenu <silent> ".MenuComments.'.end-of-&line\ comment<Tab>\\cl           :call C_EndOfLineComment( )<CR>'
	exe "vmenu <silent> ".MenuComments.'.end-of-&line\ comment<Tab>\\cl           :call C_EndOfLineComment( )<CR>'

	exe "amenu <silent> ".MenuComments.'.ad&just\ end-of-line\ com\.<Tab>\\cj     :call C_AdjustLineEndComm()<CR>'
	exe "vmenu <silent> ".MenuComments.'.ad&just\ end-of-line\ com\.<Tab>\\cj     :call C_AdjustLineEndComm()<CR>'

	exe "amenu <silent> ".MenuComments.'.&set\ end-of-line\ com\.\ col\.<Tab>\\cs :call C_GetLineEndCommCol()<CR>'

	exe "amenu  ".MenuComments.'.-SEP10-                              :'
	exe "amenu <silent> ".MenuComments.'.code\ ->\ comment\ \/&*\ *\/<Tab>\\c*    :call C_CodeToCommentC()<CR>:nohlsearch<CR>j'
	exe "vmenu <silent> ".MenuComments.'.code\ ->\ comment\ \/&*\ *\/<Tab>\\c*    :call C_CodeToCommentC()<CR>:nohlsearch<CR>j'
	exe "amenu <silent> ".MenuComments.'.code\ ->\ comment\ &\/\/<Tab>\\cc        :call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j'
	exe "vmenu <silent> ".MenuComments.'.code\ ->\ comment\ &\/\/<Tab>\\cc        :call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j'
	exe "amenu <silent> ".MenuComments.'.c&omment\ ->\ code<Tab>\\co              :call C_CommentToCode()<CR>:nohlsearch<CR>'
	exe "vmenu <silent> ".MenuComments.'.c&omment\ ->\ code<Tab>\\co              :call C_CommentToCode()<CR>:nohlsearch<CR>'

	exe "amenu          ".MenuComments.'.-SEP0-                        :'
	"
  "===============================================================================================
  "----- Menu : Statements (title)                              {{{2
  "===============================================================================================
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Statements' )
	"
  "===============================================================================================
  "----- Menu : Idioms (title)                             {{{2
  "===============================================================================================
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Idioms' )
	"
  "===============================================================================================
  "----- Menu : Preprocessor (title)                             {{{2
  "===============================================================================================
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Preprocessor' )
	"
	"===============================================================================================
	"----- Menu : Snippets ----------------------------------------------------   {{{2
	"===============================================================================================
	"
 	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', 'S&nippets' )
	let	ahead	= 'anoremenu <silent> '.s:C_RootMenu.'S&nippets.'
	let	vhead	= 'vnoremenu <silent> '.s:C_RootMenu.'S&nippets.'
	let	ihead	= 'inoremenu <silent> '.s:C_RootMenu.'S&nippets.'
  "
	if !empty(s:C_CodeSnippets)
		exe ahead.'&read\ code\ snippet<Tab>\\nr       :call C_CodeSnippet("r")<CR>'
		exe ihead.'&read\ code\ snippet<Tab>\\nr  <C-C>:call C_CodeSnippet("r")<CR>'
		exe ahead.'&view\ code\ snippet<Tab>\\nv       :call C_CodeSnippet("view")<CR>'
		exe ihead.'&view\ code\ snippet<Tab>\\nv  <C-C>:call C_CodeSnippet("view")<CR>'
		exe ahead.'&write\ code\ snippet<Tab>\\nw      :call C_CodeSnippet("w")<CR>'
		exe vhead.'&write\ code\ snippet<Tab>\\nw <C-C>:call C_CodeSnippet("wv")<CR>'
		exe ihead.'&write\ code\ snippet<Tab>\\nw <C-C>:call C_CodeSnippet("w")<CR>'
		exe ahead.'&edit\ code\ snippet<Tab>\\ne       :call C_CodeSnippet("e")<CR>'
		exe ihead.'&edit\ code\ snippet<Tab>\\ne  <C-C>:call C_CodeSnippet("e")<CR>'
		exe ahead.'-SEP1-								:'
	endif
	exe ahead.'&pick\ up\ func\.\ prototype<Tab>\\nf,\ \\np         :call C_ProtoPick("function")<CR>'
	exe vhead.'&pick\ up\ func\.\ prototype<Tab>\\nf,\ \\np         :call C_ProtoPick("function")<CR>'
	exe ihead.'&pick\ up\ func\.\ prototype<Tab>\\nf,\ \\np    <C-C>:call C_ProtoPick("function")<CR>'
	exe ahead.'&pick\ up\ method\ prototype<Tab>\\nm                :call C_ProtoPick("method")<CR>'
	exe vhead.'&pick\ up\ method\ prototype<Tab>\\nm                :call C_ProtoPick("method")<CR>'
	exe ihead.'&pick\ up\ method\ prototype<Tab>\\nm           <C-C>:call C_ProtoPick("method")<CR>'
	exe ahead.'&insert\ prototype(s)<Tab>\\ni        :call C_ProtoInsert()<CR>'
	exe ihead.'&insert\ prototype(s)<Tab>\\ni   <C-C>:call C_ProtoInsert()<CR>'
	exe ahead.'&clear\ prototype(s)<Tab>\\nc         :call C_ProtoClear()<CR>'
	exe ihead.'&clear\ prototype(s)<Tab>\\nc 	 <C-C>:call C_ProtoClear()<CR>'
	exe ahead.'&show\ prototype(s)<Tab>\\ns		      :call C_ProtoShow()<CR>'
	exe ihead.'&show\ prototype(s)<Tab>\\ns		 <C-C>:call C_ProtoShow()<CR>'

	exe ahead.'-SEP2-									     :'
		"
		exe ahead.'edit\ &local\ templates<Tab>\\ntl       :call mmtemplates#core#EditTemplateFiles(g:C_Templates,-1)<CR>'
		exe ihead.'edit\ &local\ templates<Tab>\\ntl  <C-C>:call mmtemplates#core#EditTemplateFiles(g:C_Templates,-1)<CR>'
		if g:C_Installation == 'system'
			exe ahead.'edit\ &local\ templates<Tab>\\ntg       :call mmtemplates#core#EditTemplateFiles(g:C_Templates,1)<CR>'
			exe ihead.'edit\ &local\ templates<Tab>\\ntg  <C-C>:call mmtemplates#core#EditTemplateFiles(g:C_Templates,1)<CR>'
		endif
		"
		exe ahead.'reread\ &templates<Tab>\\ntr       :call mmtemplates#core#ReadTemplates(g:C_Templates,"reload","all")<CR>'
		exe ihead.'reread\ &templates<Tab>\\ntr  <C-C>:call mmtemplates#core#ReadTemplates(g:C_Templates,"reload","all")<CR>'
	"
	if !empty(s:C_CodeSnippets)
		call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'do_styles', 
					\ 'specials_menu', 'Snippets'	)
	endif
	"
  "===============================================================================================
  "----- Menu : Run                             {{{2
  "===============================================================================================
	"
 	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', 'C&++' )
	"
	"===============================================================================================
	"----- Menu : run  ----- --------------------------------------------------   {{{2
	"===============================================================================================
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Run' )
	"
	let	ahead	= 'anoremenu <silent> '.s:MenuRun.'.'
	let	vhead	= 'vnoremenu <silent> '.s:MenuRun.'.'
	let	ihead	= 'inoremenu <silent> '.s:MenuRun.'.'
	"
	exe ahead.'save\ and\ &compile<Tab>\\rc\ \ \<A-F9\>         :call C_Compile()<CR>:call C_HlMessage()<CR>'
	exe ihead.'save\ and\ &compile<Tab>\\rc\ \ \<A-F9\>    <C-C>:call C_Compile()<CR>:call C_HlMessage()<CR>'
	exe ahead.'&link<Tab>\\rl\ \ \ \ \<F9\>                     :call C_Link()<CR>:call C_HlMessage()<CR>'
	exe ihead.'&link<Tab>\\rl\ \ \ \ \<F9\>                <C-C>:call C_Link()<CR>:call C_HlMessage()<CR>'
	exe ahead.'&run<Tab>\\rr\ \ \<C-F9\>                        :call C_Run()<CR>'
	exe ihead.'&run<Tab>\\rr\ \ \<C-F9\>                   <C-C>:call C_Run()<CR>'
	exe ahead.'cmd\.\ line\ &arg\.<Tab>\\ra\ \ \<S-F9\>         :call C_Arguments()<CR>'
	exe ihead.'cmd\.\ line\ &arg\.<Tab>\\ra\ \ \<S-F9\>    <C-C>:call C_Arguments()<CR>'
	"
	exe ahead.'-SEP0-                            :'
	exe ahead.'&make<Tab>\\rm                                    :call C_Make()<CR>'
	exe ihead.'&make<Tab>\\rm                               <C-C>:call C_Make()<CR>'
	exe ahead.'&choose\ makefile<Tab>\\rcm                       :call C_ChooseMakefile()<CR>'
	exe ihead.'&choose\ makefile<Tab>\\rcm                  <C-C>:call C_ChooseMakefile()<CR>'
	exe ahead.'executable\ to\ run<Tab>\\rme                     :call C_ExeToRun()<CR>'
	exe ihead.'executable\ to\ run<Tab>\\rme                <C-C>:call C_ExeToRun()<CR>'
	exe ahead.'&make\ clean<Tab>\\rmc                            :call C_MakeClean()<CR>'
	exe ihead.'&make\ clean<Tab>\\rmc                       <C-C>:call C_MakeClean()<CR>'
	exe ahead.'cmd\.\ line\ ar&g\.\ for\ make<Tab>\\rma          :call C_MakeArguments()<CR>'
	exe ihead.'cmd\.\ line\ ar&g\.\ for\ make<Tab>\\rma     <C-C>:call C_MakeArguments()<CR>'
	"
	exe ahead.'-SEP1-                            :'
	"
	if s:C_SplintIsExecutable==1
		exe ahead.'s&plint<Tab>\\rp                                :call C_SplintCheck()<CR>:call C_HlMessage()<CR>'
		exe ihead.'s&plint<Tab>\\rp                           <C-C>:call C_SplintCheck()<CR>:call C_HlMessage()<CR>'
		exe ahead.'cmd\.\ line\ arg\.\ for\ spl&int<Tab>\\rpa      :call C_SplintArguments()<CR>'
		exe ihead.'cmd\.\ line\ arg\.\ for\ spl&int<Tab>\\rpa <C-C>:call C_SplintArguments()<CR>'
		exe ahead.'-SEP2-                          :'
	endif
	"
	if s:C_CppcheckIsExecutable==1
		exe ahead.'cppcheck<Tab>\\rcc                            :call C_CppcheckCheck()<CR>:call C_HlMessage()<CR>'
		exe ihead.'cppcheck<Tab>\\rcc                       <C-C>:call C_CppcheckCheck()<CR>:call C_HlMessage()<CR>'
		"
		if s:C_MenuHeader == 'yes'
			exe ahead.'cppcheck\ severity<Tab>\\rccs.cppcheck\ severity     :call C_MenuTitle()<CR>'
			exe ahead.'cppcheck\ severity<Tab>\\rccs.-Sep5-       :'
		endif

		for level in s:CppcheckSeverity
			exe ahead.'cppcheck\ severity<Tab>\\rccs.&'.level.'   :call C_GetCppcheckSeverity("'.level.'")<CR>'
		endfor
	endif
	"
	if s:C_CodeCheckIsExecutable==1
		exe ahead.'CodeChec&k<Tab>\\rk                                :call C_CodeCheck()<CR>:call C_HlMessage()<CR>'
		exe ihead.'CodeChec&k<Tab>\\rk                           <C-C>:call C_CodeCheck()<CR>:call C_HlMessage()<CR>'
		exe ahead.'cmd\.\ line\ arg\.\ for\ Cod&eCheck<Tab>\\rka      :call C_CodeCheckArguments()<CR>'
		exe ihead.'cmd\.\ line\ arg\.\ for\ Cod&eCheck<Tab>\\rka <C-C>:call C_CodeCheckArguments()<CR>'
		exe ahead.'-SEP3-                          :'
	endif
	"
	exe ahead.'in&dent<Tab>\\ri                                  :call C_Indent()<CR>'
	exe ihead.'in&dent<Tab>\\ri                             <C-C>:call C_Indent()<CR>'
	if	s:MSWIN
		exe ahead.'&hardcopy\ to\ printer<Tab>\\rh                 :call C_Hardcopy()<CR>'
		exe ihead.'&hardcopy\ to\ printer<Tab>\\rh            <C-C>:call C_Hardcopy()<CR>'
		exe vhead.'&hardcopy\ to\ printer<Tab>\\rh                 :call C_Hardcopy()<CR>'
	else
		exe ahead.'&hardcopy\ to\ FILENAME\.ps<Tab>\\rh            :call C_Hardcopy()<CR>'
		exe ihead.'&hardcopy\ to\ FILENAME\.ps<Tab>\\rh       <C-C>:call C_Hardcopy()<CR>'
		exe vhead.'&hardcopy\ to\ FILENAME\.ps<Tab>\\rh            :call C_Hardcopy()<CR>'
	endif
	exe ihead.'-SEP4-                           :'

	exe ahead.'&settings<Tab>\\rs                                :call C_Settings()<CR>'
	exe ihead.'&settings<Tab>\\rs                           <C-C>:call C_Settings()<CR>'
	exe ihead.'-SEP5-                           :'

	if	!s:MSWIN
		exe ahead.'&xterm\ size<Tab>\\rx                           :call C_XtermSize()<CR>'
		exe ihead.'&xterm\ size<Tab>\\rx                      <C-C>:call C_XtermSize()<CR>'
	endif
	if s:C_OutputGvim == "vim"
		exe ahead.'&output:\ '.s:output1.'<Tab>\\ro           :call C_Toggle_Gvim_Xterm()<CR>'
		exe ihead.'&output:\ '.s:output1.'<Tab>\\ro      <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
	else
		if s:C_OutputGvim == "buffer"
			exe ahead.'&output:\ '.s:output2.'<Tab>\\ro         :call C_Toggle_Gvim_Xterm()<CR>'
			exe ihead.'&output:\ '.s:output2.'<Tab>\\ro    <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
		else
			exe ahead.'&output:\ '.s:output3.'<Tab>\\ro         :call C_Toggle_Gvim_Xterm()<CR>'
			exe ihead.'&output:\ '.s:output3.'<Tab>\\ro    <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
		endif
	endif
	"
	"===============================================================================================
	"----- Menu : help  -------------------------------------------------------   {{{2
	"===============================================================================================
	"
	exe " menu  <silent>  ".s:C_RootMenu.'&help\ (C-Support)<Tab>\\hp        :call C_HelpCsupport()<CR>'
	exe "imenu  <silent>  ".s:C_RootMenu.'&help\ (C-Support)<Tab>\\hp   <C-C>:call C_HelpCsupport()<CR>'
	exe " menu  <silent>  ".s:C_RootMenu.'show\ &manual<Tab>\\hm   		       :call C_Help("m")<CR>'
	exe "imenu  <silent>  ".s:C_RootMenu.'show\ &manual<Tab>\\hm 		    <C-C>:call C_Help("m")<CR>'
	"
  "===============================================================================================
  "----- Menu : GENERATE MENU ITEMS FROM THE TEMPLATES                              {{{2
  "===============================================================================================
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'do_templates' )
  "===============================================================================================
  "===============================================================================================
	"
	"===============================================================================================
	"----- Menu : C-Comments --------------------------------------------------   {{{2
	"===============================================================================================
	"
	exe "amenu  ".MenuComments.'.-SEP8-                        :'
	exe " menu  ".MenuComments.'.&date<Tab>\\cd                       <Esc>:call C_InsertDateAndTime("d")<CR>'
	exe "imenu  ".MenuComments.'.&date<Tab>\\cd                       <Esc>:call C_InsertDateAndTime("d")<CR>a'
	exe "vmenu  ".MenuComments.'.&date<Tab>\\cd                      s<Esc>:call C_InsertDateAndTime("d")<CR>a'
	exe " menu  ".MenuComments.'.date\ &time<Tab>\\ct                 <Esc>:call C_InsertDateAndTime("dt")<CR>'
	exe "imenu  ".MenuComments.'.date\ &time<Tab>\\ct                 <Esc>:call C_InsertDateAndTime("dt")<CR>a'
	exe "vmenu  ".MenuComments.'.date\ &time<Tab>\\ct                s<Esc>:call C_InsertDateAndTime("dt")<CR>a'

	exe "amenu  ".MenuComments.'.-SEP12-                    :'
	exe "amenu <silent> ".MenuComments.'.\/*\ &xxx\ *\/\ \ <->\ \ \/\/\ xxx<Tab>\\cx   :call C_CommentToggle()<CR>'
	exe "vmenu <silent> ".MenuComments.'.\/*\ &xxx\ *\/\ \ <->\ \ \/\/\ xxx<Tab>\\cx   :call C_CommentToggle()<CR>'
	"
	"===============================================================================================
	"----- Menu : C-Idioms ----------------------------------------------------   {{{2
	"===============================================================================================
	"
	let	MenuIdioms	= s:C_RootMenu.'&Idioms.'
	"
	exe "amenu          ".MenuIdioms.'-SEP1-                      :'
	exe "amenu          ".MenuIdioms.'for(x=&0;\ x<n;\ x\+=1)<Tab>\\i0          :call C_CodeFor("up"    )<CR>'
	exe "vmenu          ".MenuIdioms.'for(x=&0;\ x<n;\ x\+=1)<Tab>\\i0          :call C_CodeFor("up","v")<CR>'
	exe "imenu          ".MenuIdioms.'for(x=&0;\ x<n;\ x\+=1)<Tab>\\i0     <Esc>:call C_CodeFor("up"    )<CR>'
	exe "amenu          ".MenuIdioms.'for(x=&n-1;\ x>=0;\ x\-=1)<Tab>\\in       :call C_CodeFor("down"    )<CR>'
	exe "vmenu          ".MenuIdioms.'for(x=&n-1;\ x>=0;\ x\-=1)<Tab>\\in       :call C_CodeFor("down","v")<CR>'
	exe "imenu          ".MenuIdioms.'for(x=&n-1;\ x>=0;\ x\-=1)<Tab>\\in  <Esc>:call C_CodeFor("down"    )<CR>'
	"
	"===============================================================================================
	"----- Menu : C-Preprocessor ----------------------------------------------   {{{2
	"===============================================================================================
	"
	let	MenuPreprocessor	= s:C_RootMenu.'&Preprocessor.'
	"
	exe "amenu  ".MenuPreprocessor.'-SEP2-                        :'
	exe "amenu  ".MenuPreprocessor.'#if\ &0\ #endif<Tab>\\pi0                     :call C_PPIf0("a")<CR>2ji'
	exe "imenu  ".MenuPreprocessor.'#if\ &0\ #endif<Tab>\\pi0                <Esc>:call C_PPIf0("a")<CR>2ji'
	exe "vmenu  ".MenuPreprocessor.'#if\ &0\ #endif<Tab>\\pi0                <Esc>:call C_PPIf0("v")<CR>'
	"
	exe "amenu <silent> ".MenuPreprocessor.'&remove\ #if\ 0\ #endif<Tab>\\pr0             :call C_PPIf0Remove()<CR>'
	exe "imenu <silent> ".MenuPreprocessor.'&remove\ #if\ 0\ #endif<Tab>\\pr0        <Esc>:call C_PPIf0Remove()<CR>'
	"
endfunction    " ----------  end of function  s:C_InitMenus  ----------
"
"===============================================================================================
"----- Menu Functions --------------------------------------------------------------------------
"===============================================================================================
"
"------------------------------------------------------------------------------
"  C_SaveGlobalOption    {{{1
"  param 1 : option name
"  param 2 : characters to be escaped (optional)
"------------------------------------------------------------------------------
function! s:C_SaveGlobalOption ( option, ... )
	exe 'let escaped =&'.a:option
	if a:0 == 0
		let escaped	= escape( escaped, ' |"\' )
	else
		let escaped	= escape( escaped, ' |"\'.a:1 )
	endif
	let s:C_saved_global_option[a:option]	= escaped
endfunction    " ----------  end of function C_SaveGlobalOption  ----------
"
"------------------------------------------------------------------------------
"  C_RestoreGlobalOption    {{{1
"------------------------------------------------------------------------------
function! s:C_RestoreGlobalOption ( option )
	exe ':set '.a:option.'='.s:C_saved_global_option[a:option]
endfunction    " ----------  end of function C_RestoreGlobalOption  ----------
"
"------------------------------------------------------------------------------
"  C_Input: Input after a highlighted prompt     {{{1
"           3. argument : optional completion
"------------------------------------------------------------------------------
function! C_Input ( promp, text, ... )
	echohl Search																					" highlight prompt
	call inputsave()																			" preserve typeahead
	if a:0 == 0 || empty(a:1)
		let retval	=input( a:promp, a:text )
	else
		let retval	=input( a:promp, a:text, a:1 )
	endif
	call inputrestore()																		" restore typeahead
	echohl None																						" reset highlighting
	let retval  = substitute( retval, '^\s\+', "", "" )		" remove leading whitespaces
	let retval  = substitute( retval, '\s\+$', "", "" )		" remove trailing whitespaces
	return retval
endfunction    " ----------  end of function C_Input ----------
"
"------------------------------------------------------------------------------
"  C_AdjustLineEndComm: adjust line-end comments     {{{1
"------------------------------------------------------------------------------
"
" C comment or C++ comment:
let	s:c_cppcomment= '\(\/\*.\{-}\*\/\|\/\/.*$\)'

function! C_AdjustLineEndComm ( ) range
	"
	if !exists("b:C_LineEndCommentColumn")
		let	b:C_LineEndCommentColumn	= s:C_LineEndCommColDefault
	endif

	let save_cursor = getpos(".")

	let	save_expandtab	= &expandtab
	exe	":set expandtab"

	let	linenumber	= a:firstline
	exe ":".a:firstline

	while linenumber <= a:lastline
		let	line= getline(".")

		" line is not a pure comment but contains one
		"
		if  match( line, '^\s*'.s:c_cppcomment ) < 0 &&  match( line, s:c_cppcomment ) > 0
      "
      " disregard comments starting in a string
      "
			let	idx1	      = -1
			let	idx2	      = -1
			let	commentstart= -2
			let	commentend	= 0
			while commentstart < idx2 && idx2 < commentend
				let start	      = commentend
				let idx2	      = match( line, s:c_cppcomment, start )
				let commentstart= match   ( line, '"[^"]\+"', start )
				let commentend	= matchend( line, '"[^"]\+"', start )
			endwhile
      "
      " try to adjust the comment
      "
			let idx1	= 1 + match( line, '\s*'.s:c_cppcomment, start )
			let idx2	= 1 + idx2
			call setpos(".", [ 0, linenumber, idx1, 0 ] )
			let vpos1	= virtcol(".")
			call setpos(".", [ 0, linenumber, idx2, 0 ] )
			let vpos2	= virtcol(".")

			if   ! (   vpos2 == b:C_LineEndCommentColumn
						\	|| vpos1 > b:C_LineEndCommentColumn
						\	|| idx2  == 0 )

				exe ":.,.retab"
				" insert some spaces
				if vpos2 < b:C_LineEndCommentColumn
					let	diff	= b:C_LineEndCommentColumn-vpos2
					call setpos(".", [ 0, linenumber, vpos2, 0 ] )
					let	@"	= ' '
					exe "normal	".diff."P"
				endif

				" remove some spaces
				if vpos1 < b:C_LineEndCommentColumn && vpos2 > b:C_LineEndCommentColumn
					let	diff	= vpos2 - b:C_LineEndCommentColumn
					call setpos(".", [ 0, linenumber, b:C_LineEndCommentColumn, 0 ] )
					exe "normal	".diff."x"
				endif

			endif
		endif
		let linenumber=linenumber+1
		normal j
	endwhile
	"
	" restore tab expansion settings and cursor position
	let &expandtab	= save_expandtab
	call setpos('.', save_cursor)

endfunction		" ---------- end of function  C_AdjustLineEndComm  ----------
"
"------------------------------------------------------------------------------
"  C_GetLineEndCommCol: get line-end comment position    {{{1
"------------------------------------------------------------------------------
function! C_GetLineEndCommCol ()
	let actcol	= virtcol(".")
	if actcol+1 == virtcol("$")
		let	b:C_LineEndCommentColumn	= ''
		while match( b:C_LineEndCommentColumn, '^\s*\d\+\s*$' ) < 0
			let b:C_LineEndCommentColumn = C_Input( 'start line-end comment at virtual column : ', actcol, '' )
		endwhile
	else
		let	b:C_LineEndCommentColumn	= virtcol(".")
	endif
  echomsg "line end comments will start at column  ".b:C_LineEndCommentColumn
endfunction		" ---------- end of function  C_GetLineEndCommCol  ----------
"
"------------------------------------------------------------------------------
"  C_EndOfLineComment: single line-end comment    {{{1
"------------------------------------------------------------------------------
function! C_EndOfLineComment ( ) range
	if !exists("b:C_LineEndCommentColumn")
		let	b:C_LineEndCommentColumn	= s:C_LineEndCommColDefault
	endif
	" ----- trim whitespaces -----
	exe a:firstline.','.a:lastline.'s/\s*$//'

	for line in range( a:lastline, a:firstline, -1 )
		let linelength	= virtcol( [line, "$"] ) - 1
		let	diff				= 1
		if linelength < b:C_LineEndCommentColumn
			let diff	= b:C_LineEndCommentColumn -1 -linelength
		endif
		exe "normal	".diff."A "
			call mmtemplates#core#InsertTemplate(g:C_Templates, 'Comments.end-of-line-comment')
		if line > a:firstline
			normal k
		endif
	endfor
endfunction		" ---------- end of function  C_EndOfLineComment  ----------
"
"----------------------------------------------------------------------
"  C_CodeToCommentC : Code -> Comment   {{{1
"----------------------------------------------------------------------
function! C_CodeToCommentC ( ) range
	silent exe ':'.a:firstline.','.a:lastline."s/^/ \* /"
	silent exe ":".a:firstline."s'^ '\/'"
	silent exe ":".a:lastline
	silent put = ' */'
endfunction    " ----------  end of function  C_CodeToCommentC  ----------
"
"----------------------------------------------------------------------
"  C_CodeToCommentCpp : Code -> Comment   {{{1
"----------------------------------------------------------------------
function! C_CodeToCommentCpp ( ) range
	silent exe a:firstline.','.a:lastline.":s#^#//#"
endfunction    " ----------  end of function  C_CodeToCommentCpp  ----------
"
"----------------------------------------------------------------------
"  C_StartMultilineComment : Comment -> Code   {{{1
"----------------------------------------------------------------------
let s:C_StartMultilineComment	= '^\s*\/\*[\*! ]\='

function! C_RemoveCComment( start, end )

	if a:end-a:start<1
		return 0										" lines removed
	endif
	"
	" Is the C-comment complete ? Get length.
	"
	let check				= getline(	a:start ) =~ s:C_StartMultilineComment
	let	linenumber	= a:start+1
	while linenumber < a:end && getline(	linenumber ) !~ '^\s*\*\/'
		let check				= check && getline(	linenumber ) =~ '^\s*\*[ ]\='
		let linenumber	= linenumber+1
	endwhile
	let check = check && getline(	linenumber ) =~ '^\s*\*\/'
	"
	" remove a complete comment
	"
	if check
		exe "silent :".a:start.'   s/'.s:C_StartMultilineComment.'//'
		let	linenumber1	= a:start+1
		while linenumber1 < linenumber
			exe "silent :".linenumber1.' s/^\s*\*[ ]\=//'
			let linenumber1	= linenumber1+1
		endwhile
		exe "silent :".linenumber1.'   s/^\s*\*\///'
	endif

	return linenumber-a:start+1			" lines removed
endfunction    " ----------  end of function  C_RemoveCComment  ----------
"
"----------------------------------------------------------------------
"  C_CommentToCode : Comment -> Code       {{{1
"----------------------------------------------------------------------
function! C_CommentToCode( ) range

	let	removed	= 0
	"
	let	linenumber	= a:firstline
	while linenumber <= a:lastline
		" Do we have a C++ comment ?
		if getline(	linenumber ) =~ '^\s*//'
			exe "silent :".linenumber.' s#^\s*//##'
			let	removed    = 1
		endif
		" Do we have a C   comment ?
		if removed == 0 && getline(	linenumber ) =~ s:C_StartMultilineComment
			let removed = C_RemoveCComment( linenumber, a:lastline )
		endif

		if removed!=0
			let linenumber = linenumber+removed
			let	removed    = 0
		else
			let linenumber = linenumber+1
		endif
	endwhile
endfunction    " ----------  end of function  C_CommentToCode  ----------
"
"----------------------------------------------------------------------
"  C_CommentCToCpp : C Comment -> C++ Comment       {{{1
"  Changes the first comment in case of multiple C comments:
"    xxxx;               /* 1 */ /* 2 */
"    xxxx;               // 1 // 2
"----------------------------------------------------------------------
function! C_CommentToggle () range
	let	LineEndCommentC		= '\/\*\(.*\)\*\/'
	let	LineEndCommentCpp	= '\/\/\(.*\)$'
	"
	for linenumber in range( a:firstline, a:lastline )
		let line			= getline(linenumber)
		" ----------  C => C++  ----------
		if match( line, LineEndCommentC ) >= 0
			let	line	= substitute( line, '\/\*\s*\(.\{-}\)\*\/', '\/\/ \1', '' )
			call setline( linenumber, line )
			continue
		endif
		" ----------  C++ => C  ----------
		if match( line, LineEndCommentCpp ) >= 0
			let	line	= substitute( line, '\/\/\s*\(.*\)\s*$', '/* \1 */', '' )
			call setline( linenumber, line )
		endif
	endfor
endfunction    " ----------  end of function C_CommentToggle  ----------
"
"=====================================================================================
"----- Menu : Statements -----------------------------------------------------------
"=====================================================================================
"
"------------------------------------------------------------------------------
"  C_PPIf0 : #if 0 .. #endif        {{{1
"------------------------------------------------------------------------------
function! C_PPIf0 (mode)
	"
	let	s:C_If0_Counter	= 0
	let	save_line					= line(".")
	let	actual_line				= 0
	"
	" search for the maximum option number (if any)
	"
	normal gg
	while actual_line < search( s:C_If0_Txt."\\d\\+" )
		let actual_line	= line(".")
	 	let actual_opt  = matchstr( getline(actual_line), s:C_If0_Txt."\\d\\+" )
		let actual_opt  = strpart( actual_opt, strlen(s:C_If0_Txt),strlen(actual_opt)-strlen(s:C_If0_Txt))
		if s:C_If0_Counter < actual_opt
			let	s:C_If0_Counter = actual_opt
		endif
	endwhile
	let	s:C_If0_Counter = s:C_If0_Counter+1
	silent exe ":".save_line
	"
	if a:mode=='a'
		let zz=    "\n#if  0     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n"
		let zz= zz."\n#endif     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n\n"
		put =zz
		normal 4k
	endif

	if a:mode=='v'
		let	pos1	= line("'<")
		let	pos2	= line("'>")
		let zz=      "#endif     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n\n"
		exe ":".pos2."put =zz"
		let zz=    "\n#if  0     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n"
		exe ":".pos1."put! =zz"
		"
		if  &foldenable && foldclosed(".")
			normal zv
		endif
	endif

endfunction    " ----------  end of function C_PPIf0 ----------
"
"------------------------------------------------------------------------------
"  C_PPIf0Remove : remove  #if 0 .. #endif        {{{1
"------------------------------------------------------------------------------
function! C_PPIf0Remove ()
	"
	" cursor on fold: open fold first
	if  &foldenable && foldclosed(".")
		normal zv
	endif
	"
	let frstline	= searchpair( '^\s*#if\s\+0', '', '^\s*#endif\>.\+\<If0Label_', 'bn' )
  if frstline<=0
		echohl WarningMsg | echo 'no  #if 0 ... #endif  found or cursor not inside such a directive'| echohl None
    return
  endif
	let lastline	= searchpair( '^\s*#if\s\+0', '', '^\s*#endif\>.\+\<If0Label_', 'n' )
	if lastline<=0
		echohl WarningMsg | echo 'no  #if 0 ... #endif  found or cursor not inside such a directive'| echohl None
		return
	endif
  let actualnumber1  = matchstr( getline(frstline), s:C_If0_Txt."\\d\\+" )
  let actualnumber2  = matchstr( getline(lastline), s:C_If0_Txt."\\d\\+" )
	if actualnumber1 != actualnumber2
    echohl WarningMsg | echo 'lines '.frstline.', '.lastline.': comment tags do not match'| echohl None
		return
	endif

  silent exe ':'.lastline.','.lastline.'d'
	silent exe ':'.frstline.','.frstline.'d'

endfunction    " ----------  end of function C_PPIf0Remove ----------

"------------------------------------------------------------------------------
"  C_CodeSnippet : read / edit code snippet       {{{1
"------------------------------------------------------------------------------
function! C_CodeSnippet(mode)

	if isdirectory(s:C_CodeSnippets)
		"
		" read snippet file, put content below current line and indent
		"
		if a:mode == "r"
			if has("browse") && s:C_GuiSnippetBrowser == 'gui'
				let	l:snippetfile=browse(0,"read a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("read snippet ", s:C_CodeSnippets, "file" )
			endif
			if filereadable(l:snippetfile)
				let	linesread= line("$")
				let l:old_cpoptions	= &cpoptions " Prevent the alternate buffer from being set to this files
				setlocal cpoptions-=a
				:execute "read ".l:snippetfile
				let &cpoptions	= l:old_cpoptions		" restore previous options
				let	linesread= line("$")-linesread-1
				if linesread>=0 && match( l:snippetfile, '\.\(ni\|noindent\)$' ) < 0
				endif
			endif
			if line(".")==2 && getline(1)=~"^$"
				silent exe ":1,1d"
			endif
		endif
		"
		" update current buffer / split window / edit snippet file
		"
		if a:mode == "e"
			if has("browse") && s:C_GuiSnippetBrowser == 'gui'
				let	l:snippetfile	= browse(0,"edit a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("edit snippet ", s:C_CodeSnippets, "file" )
			endif
			if !empty(l:snippetfile)
				:execute "update! | split | edit ".l:snippetfile
			endif
		endif
    "
    " update current buffer / split window / view snippet file
    "
    if a:mode == "view"
			if has("gui_running") && s:C_GuiSnippetBrowser == 'gui'
				let l:snippetfile=browse(0,"view a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("view snippet ", s:C_CodeSnippets, "file" )
			endif
      if !empty(l:snippetfile)
        :execute "update! | split | view ".l:snippetfile
      endif
    endif
		"
		" write whole buffer into snippet file
		"
		if a:mode == "w" || a:mode == "wv"
			if has("browse") && s:C_GuiSnippetBrowser == 'gui'
				let	l:snippetfile	= browse(0,"write a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("write snippet ", s:C_CodeSnippets, "file" )
			endif
			if !empty(l:snippetfile)
				if filereadable(l:snippetfile)
					if confirm("File ".l:snippetfile." exists ! Overwrite ? ", "&Cancel\n&No\n&Yes") != 3
						return
					endif
				endif
				if a:mode == "w"
					:execute ":write! ".l:snippetfile
				else
					:execute ":*write! ".l:snippetfile
				endif
			endif
		endif

	else
		echo "code snippet directory ".s:C_CodeSnippets." does not exist (please create it)"
	endif
endfunction    " ----------  end of function C_CodeSnippets  ----------
"
"------------------------------------------------------------------------------
"  C_help : builtin completion    {{{1
"------------------------------------------------------------------------------
function!	C_ForTypeComplete ( ArgLead, CmdLine, CursorPos )
	"
	" show all types
	if empty(a:ArgLead)
		return s:C_ForTypes
	endif
	"
	" show types beginning with a:ArgLead
	let	expansions	= []
	for item in s:C_ForTypes
		if match( item, '\<'.a:ArgLead.'\s*\w*' ) == 0
			call add( expansions, item )
		endif
	endfor
	return	expansions
endfunction    " ----------  end of function C_ForTypeComplete  ----------
"
"------------------------------------------------------------------------------
"  C_CodeFor : for (idiom)       {{{1
"------------------------------------------------------------------------------
function! C_CodeFor( direction, ... ) range
	"
	let updown	= ( a:direction == 'up' ? 'INCR.' : 'DECR.' )
	let	string	= C_Input( '[TYPE (expand)] VARIABLE [START [END ['.updown.']]] : ', '',
									\				'customlist,C_ForTypeComplete' )
	if empty(string)
		return
	endif
	"
	let string	= substitute( string, '\s\+', ' ', 'g' )
	let nextindex			= -1
	let loopvar_type	= ''
	for item in sort( copy( s:C_ForTypes ) )
		let nextindex	= matchend( string, '^'.item )
		if nextindex > 0
			let loopvar_type	= item
			let	string				= strpart( string, nextindex )
		endif
	endfor
	if !empty(loopvar_type)
		let loopvar_type	.= ' '
		if empty(string)
			let	string	= C_Input( 'VARIABLE [START [END ['.updown.']]] : ', '' )
			if empty(string)
				return
			endif
		endif
	endif
	let part	= split( string )

	if len( part ) 	> 4
    echohl WarningMsg | echomsg "for loop construction : to many arguments " | echohl None
		return
	endif

	let missing	= 0
	while len(part) < 4
		let part	= part + ['']
		let missing	= missing+1
	endwhile

	let [ loopvar, startval, endval, incval ]	= part

	if empty(incval)
		let incval	= '1'
	endif

	if a:direction == 'up'
		if empty(endval)
			let endval	= 'n'
		endif
		if empty(startval)
			let startval	= '0'
		endif
		let txt_init = loopvar_type.loopvar.' = '.startval
		let txt_cond = loopvar.' < '.endval
		let txt_incr = loopvar.' += '.incval
	else
		if empty(endval)
			let endval	= '0'
		endif
		if empty(startval)
			let startval	= 'n-1'
		endif
		let txt_init = loopvar_type.loopvar.' = '.startval
		let txt_cond = loopvar.' >= '.endval
		let txt_incr = loopvar.' -= '.incval
	endif
	"
	if a:0 == 0
		call mmtemplates#core#InsertTemplate ( g:C_Templates, 'Statements.for block',
					\ '|INIT|', txt_init, '|CONDITION|', txt_cond, '|INCREMENT|', txt_incr,
					\ 'range', a:firstline, a:lastline )
	elseif a:0 == 1 && a:1 == 'v'
		call mmtemplates#core#InsertTemplate ( g:C_Templates, 'Statements.for block',
					\ '|INIT|', txt_init, '|CONDITION|', txt_cond, '|INCREMENT|', txt_incr,
					\ 'range', a:firstline, a:lastline, 'v' )
	else
    echohl WarningMsg | echomsg "for loop construction : unknown argument ".a:1 | echohl None
	endif
	"
endfunction    " ----------  end of function C_CodeFor ----------
"
"------------------------------------------------------------------------------
"  Handle prototypes       {{{1
"------------------------------------------------------------------------------
"
let s:C_Prototype        = []
let s:C_PrototypeShow    = []
let s:C_PrototypeCounter = 0
let s:C_CComment         = '\/\*.\{-}\*\/\s*'		" C comment with trailing whitespaces
																								"  '.\{-}'  any character, non-greedy
let s:C_CppComment       = '\/\/.*$'						" C++ comment
"
"------------------------------------------------------------------------------
"  C_ProtoPick: pick up a method prototype (normal/visual)       {{{1
"  type : 'function', 'method'
"------------------------------------------------------------------------------
function! C_ProtoPick( type ) range
	"
	" remove C/C++-comments, leading and trailing whitespaces, squeeze whitespaces
	"
	let prototyp   = ''
	for linenumber in range( a:firstline, a:lastline )
		let newline			= getline(linenumber)
		let newline 	  = substitute( newline, s:C_CppComment, "", "" ) " remove C++ comment
		let prototyp		= prototyp." ".newline
	endfor
	"
	let prototyp  = substitute( prototyp, '^\s\+', "", "" )					" remove leading whitespaces
	let prototyp  = substitute( prototyp, s:C_CComment, "", "g" )		" remove (multiline) C comments
	let prototyp  = substitute( prototyp, '\s\+', " ", "g" )				" squeeze whitespaces
	let prototyp  = substitute( prototyp, '\s\+$', "", "" )					" remove trailing whitespaces
	"
	"-------------------------------------------------------------------------------
	" prototype for  methods
	"-------------------------------------------------------------------------------
	if a:type == 'method'
		"
		" remove template keyword
		"
		let prototyp  = substitute( prototyp, '^template\s*<\s*class \w\+\s*>\s*', "", "" )
		"
		let idx     = stridx( prototyp, '(' )								    		" start of the parameter list
		let head    = strpart( prototyp, 0, idx )
		let parlist = strpart( prototyp, idx )
		"
		" remove the scope resolution operator
		"
		let	template_id	= '\h\w*\s*\(<[^>]\+>\)\?'
		let	rgx2				= '\('.template_id.'\s*::\s*\)*\([~]\?\h\w*\|operator.\+\)\s*$'
		let idx 				= match( head, rgx2 )								    		" start of the function name
		let returntype	= strpart( head, 0, idx )
		let fctname	  	= strpart( head, idx )

		let resret	= matchstr( returntype, '\('.template_id.'\s*::\s*\)*'.template_id )
		let resret	= substitute( resret, '\s\+', '', 'g' )

		let resfct	= matchstr( fctname   , '\('.template_id.'\s*::\s*\)*'.template_id )
		let resfct	= substitute( resfct, '\s\+', '', 'g' )

		if  !empty(resret) && match( resfct, resret.'$' ) >= 0
			"-------------------------------------------------------------------------------
			" remove scope resolution from the return type (keep 'std::')
			"-------------------------------------------------------------------------------
			let returntype	= substitute( returntype, '<\s*\w\+\s*>', '', 'g' )
			let returntype 	= substitute( returntype, '\<std\s*::', 'std##', 'g' )	" remove the scope res. operator
			let returntype 	= substitute( returntype, '\<\h\w*\s*::', '', 'g' )			" remove the scope res. operator
			let returntype 	= substitute( returntype, '\<std##', 'std::', 'g' )			" remove the scope res. operator
		endif

		let fctname		  = substitute( fctname, '<\s*\w\+\s*>', "", "g" )
		let fctname   	= substitute( fctname, '\<std\s*::', 'std##', 'g' )	" remove the scope res. operator
		let fctname   	= substitute( fctname, '\<\h\w*\s*::', '', 'g' )		" remove the scope res. operator
		let fctname   	= substitute( fctname, '\<std##', 'std::', 'g' )		" remove the scope res. operator

		let	prototyp	= returntype.fctname.parlist
		"
		if empty(fctname) || empty(parlist)
			echon 'No prototype saved. Wrong selection ?'
			return
		endif
	endif
	"
	" remove trailing parts of the function body; add semicolon
	"
	let prototyp	= substitute( prototyp, '\s*{.*$', "", "" )
	let prototyp	= prototyp.";\n"

	"
	" bookkeeping
	"
	let s:C_PrototypeCounter += 1
	let s:C_Prototype        += [prototyp]
	let s:C_PrototypeShow    += ["(".s:C_PrototypeCounter.") ".bufname("%")." #  ".prototyp]
	"
	echon	s:C_PrototypeCounter.' prototype'
	if s:C_PrototypeCounter > 1
		echon	's'
	endif
	"
endfunction    " ---------  end of function C_ProtoPick ----------
"
"------------------------------------------------------------------------------
"  C_ProtoInsert : insert       {{{1
"------------------------------------------------------------------------------
function! C_ProtoInsert ()
	"
	" use internal formatting to avoid conficts when using == below
	let	equalprg_save	= &equalprg
	set equalprg=
	"
	if s:C_PrototypeCounter > 0
		for protytype in s:C_Prototype
			put =protytype
		endfor
		let	lines	= s:C_PrototypeCounter	- 1
		silent exe "normal =".lines."-"
		call C_ProtoClear()
	else
		echo "currently no prototypes available"
	endif
	"
	" restore formatter programm
	let &equalprg	= equalprg_save
	"
endfunction    " ---------  end of function C_ProtoInsert  ----------
"
"------------------------------------------------------------------------------
"  C_ProtoClear : clear       {{{1
"------------------------------------------------------------------------------
function! C_ProtoClear ()
	if s:C_PrototypeCounter > 0
		let s:C_Prototype        = []
		let s:C_PrototypeShow    = []
		if s:C_PrototypeCounter == 1
			echo	s:C_PrototypeCounter.' prototype deleted'
		else
			echo	s:C_PrototypeCounter.' prototypes deleted'
		endif
		let s:C_PrototypeCounter = 0
	else
		echo "currently no prototypes available"
	endif
endfunction    " ---------  end of function C_ProtoClear  ----------
"
"------------------------------------------------------------------------------
"  C_ProtoShow : show       {{{1
"------------------------------------------------------------------------------
function! C_ProtoShow ()
	if s:C_PrototypeCounter > 0
		for protytype in s:C_PrototypeShow
			echo protytype
		endfor
	else
		echo "currently no prototypes available"
	endif
endfunction    " ---------  end of function C_ProtoShow  ----------
"
"------------------------------------------------------------------------------
"  C_EscapeBlanks : C_EscapeBlanks       {{{1
"------------------------------------------------------------------------------
function! C_EscapeBlanks (arg)
	return  substitute( a:arg, " ", "\\ ", "g" )
endfunction    " ---------  end of function C_EscapeBlanks  ----------
"
"------------------------------------------------------------------------------
"  C_Compile : C_Compile       {{{1
"------------------------------------------------------------------------------
"  The standard make program 'make' called by vim is set to the C or C++ compiler
"  and reset after the compilation  (setlocal makeprg=... ).
"  The errorfile created by the compiler will now be read by gvim and
"  the commands cl, cp, cn, ... can be used.
"------------------------------------------------------------------------------
let s:LastShellReturnCode	= 0			" for compile / link / run only

function! C_Compile ()

	let s:C_HlMessage = ""
	exe	":cclose"
	let	Sou		= expand("%:p")											" name of the file in the current buffer
	let	Obj		= expand("%:p:r").s:C_ObjExtension	" name of the object
	let SouEsc= escape( Sou, s:C_FilenameEscChar )
	let ObjEsc= escape( Obj, s:C_FilenameEscChar )
	if s:MSWIN
		let	SouEsc	= '"'.SouEsc.'"'
		let	ObjEsc	= '"'.ObjEsc.'"'
	endif
	let	compilerflags	= ''

	" update : write source file if necessary
	exe	":update"

	" compilation if object does not exist or object exists and is older then the source
	if !filereadable(Obj) || (filereadable(Obj) && (getftime(Obj) < getftime(Sou)))
		" &makeprg can be a string containing blanks
		call s:C_SaveGlobalOption('makeprg')
		if expand("%:e") == s:C_CExtension
			exe		"setlocal makeprg=".s:C_CCompiler
			let	compilerflags	= s:C_CFlags
		else
			exe		"setlocal makeprg=".s:C_CplusCompiler
			let	compilerflags	= s:C_CplusCFlags 
		endif
		"
		" COMPILATION
		"
		exe ":compiler ".s:C_VimCompilerName
		let v:statusmsg = ''
		let	s:LastShellReturnCode	= 0
		exe		"make ".compilerflags." ".SouEsc." -o ".ObjEsc
		if empty(v:statusmsg)
			let s:C_HlMessage = "'".Obj."' : compilation successful"
		endif
		if v:shell_error != 0
			let	s:LastShellReturnCode	= v:shell_error
		endif
		call s:C_RestoreGlobalOption('makeprg')
		"
		" open error window if necessary
		:redraw!
		exe	":botright cwindow"
	else
		let s:C_HlMessage = " '".Obj."' is up to date "
	endif

endfunction    " ----------  end of function C_Compile ----------

"===  FUNCTION  ================================================================
"          NAME:  C_CheckForMain
"   DESCRIPTION:  check if current buffer contains a main function
"    PARAMETERS:  
"       RETURNS:  0 : no main function
"===============================================================================
function! C_CheckForMain ()
	return  search( '^\(\s*int\s\+\)\=\s*main', "cnw" )
endfunction    " ----------  end of function C_CheckForMain  ----------
"
"------------------------------------------------------------------------------
"  C_Link : C_Link       {{{1
"------------------------------------------------------------------------------
"  The standard make program which is used by gvim is set to the compiler
"  (for linking) and reset after linking.
"
"  calls: C_Compile
"------------------------------------------------------------------------------
function! C_Link ()

	call	C_Compile()
	:redraw!
	if s:LastShellReturnCode != 0
		let	s:LastShellReturnCode	=  0
		return
	endif

	let s:C_HlMessage = ""
	let	Sou		= expand("%:p")						       		" name of the file (full path)
	let	Obj		= expand("%:p:r").s:C_ObjExtension	" name of the object file
	let	Exe		= expand("%:p:r").s:C_ExeExtension	" name of the executable
	let ObjEsc= escape( Obj, s:C_FilenameEscChar )
	let ExeEsc= escape( Exe, s:C_FilenameEscChar )
	if s:MSWIN
		let	ObjEsc	= '"'.ObjEsc.'"'
		let	ExeEsc	= '"'.ExeEsc.'"'
	endif

	if C_CheckForMain() == 0
		let s:C_HlMessage = "no main function in '".Sou."'"
		return
	endif

	" no linkage if:
	"   executable exists
	"   object exists
	"   source exists
	"   executable newer then object
	"   object newer then source

	if    filereadable(Exe)                &&
      \ filereadable(Obj)                &&
      \ filereadable(Sou)                &&
      \ (getftime(Exe) >= getftime(Obj)) &&
      \ (getftime(Obj) >= getftime(Sou))
		let s:C_HlMessage = " '".Exe."' is up to date "
		return
	endif

	" linkage if:
	"   object exists
	"   source exists
	"   object newer then source
	let	linkerflags	= s:C_LFlags 

	if filereadable(Obj) && (getftime(Obj) >= getftime(Sou))
		call s:C_SaveGlobalOption('makeprg')
		if expand("%:e") == s:C_CExtension
			exe		"setlocal makeprg=".s:C_CCompiler
			let	linkerflags	= s:C_LFlags
		else
			exe		"setlocal makeprg=".s:C_CplusCompiler
			let	linkerflags	= s:C_CplusLFlags 
		endif
		exe ":compiler ".s:C_VimCompilerName
		let	s:LastShellReturnCode	= 0
		let v:statusmsg = ''
		silent exe "make ".linkerflags." -o ".ExeEsc." ".ObjEsc." ".s:C_Libs
		if v:shell_error != 0
			let	s:LastShellReturnCode	= v:shell_error
		endif
		call s:C_RestoreGlobalOption('makeprg')
		"
		if empty(v:statusmsg)
			let s:C_HlMessage = "'".Exe."' : linking successful"
		" open error window if necessary
		:redraw!
		exe	":botright cwindow"
		else
			exe ":botright copen"
		endif
	endif
endfunction    " ----------  end of function C_Link ----------
"
"------------------------------------------------------------------------------
"  C_Run : 	C_Run       {{{1
"  calls: C_Link
"------------------------------------------------------------------------------
"
let s:C_OutputBufferName   = "C-Output"
let s:C_OutputBufferNumber = -1
let s:C_RunMsg1						 ="' does not exist or is not executable or object/source older then executable"
let s:C_RunMsg2						 ="' does not exist or is not executable"
"
function! C_Run ()
"
	let s:C_HlMessage = ""
	let Sou  					= expand("%:p")												" name of the source file
	let Obj  					= expand("%:p:r").s:C_ObjExtension		" name of the object file
	let Exe  					= expand("%:p:r").s:C_ExeExtension		" name of the executable
	let ExeEsc  			= escape( Exe, s:C_FilenameEscChar )	" name of the executable, escaped
	let Quote					= ''
	if s:MSWIN
		let Quote					= '"'
	endif
	"
	let l:arguments     = exists("b:C_CmdLineArgs") ? b:C_CmdLineArgs : ''
	"
	let	l:currentbuffer	= bufname("%")
	"
	"==============================================================================
	"  run : run from the vim command line
	"==============================================================================
	if s:C_OutputGvim == "vim"
		"
		if s:C_ExecutableToRun !~ "^\s*$"
			call C_HlMessage( "executable : '".s:C_ExecutableToRun."'" )
			exe		'!'.Quote.s:C_ExecutableToRun.Quote.' '.l:arguments
		else

			silent call C_Link()
			if s:LastShellReturnCode == 0
				" clear the last linking message if any"
				let s:C_HlMessage = ""
				call C_HlMessage()
			endif
			"
			if	executable(Exe) && getftime(Exe) >= getftime(Obj) && getftime(Obj) >= getftime(Sou)
				exe		"!".Quote.ExeEsc.Quote." ".l:arguments
			else
				echomsg "file '".Exe.s:C_RunMsg1
			endif
		endif

	endif
	"
	"==============================================================================
	"  run : redirect output to an output buffer
	"==============================================================================
	if s:C_OutputGvim == "buffer"
		let	l:currentbuffernr	= bufnr("%")
		"
		if s:C_ExecutableToRun =~ "^\s*$"
			call C_Link()
		endif
		if l:currentbuffer ==  bufname("%")
			"
			"
			if bufloaded(s:C_OutputBufferName) != 0 && bufwinnr(s:C_OutputBufferNumber)!=-1
				exe bufwinnr(s:C_OutputBufferNumber) . "wincmd w"
				" buffer number may have changed, e.g. after a 'save as'
				if bufnr("%") != s:C_OutputBufferNumber
					let s:C_OutputBufferNumber	= bufnr(s:C_OutputBufferName)
					exe ":bn ".s:C_OutputBufferNumber
				endif
			else
				silent exe ":new ".s:C_OutputBufferName
				let s:C_OutputBufferNumber=bufnr("%")
				setlocal buftype=nofile
				setlocal noswapfile
				setlocal syntax=none
				setlocal bufhidden=delete
				setlocal tabstop=8
			endif
			"
			" run programm
			"
			setlocal	modifiable
			if s:C_ExecutableToRun !~ "^\s*$"
				call C_HlMessage( "executable : '".s:C_ExecutableToRun."'" )
				exe		'%!'.Quote.s:C_ExecutableToRun.Quote.' '.l:arguments
				setlocal	nomodifiable
				"
				if winheight(winnr()) >= line("$")
					exe bufwinnr(l:currentbuffernr) . "wincmd w"
				endif
			else
				"
				if	executable(Exe) && getftime(Exe) >= getftime(Obj) && getftime(Obj) >= getftime(Sou)
					exe		"%!".Quote.ExeEsc.Quote." ".l:arguments
					setlocal	nomodifiable
					"
					if winheight(winnr()) >= line("$")
						exe bufwinnr(l:currentbuffernr) . "wincmd w"
					endif
				else
					setlocal	nomodifiable
					:close
					echomsg "file '".Exe.s:C_RunMsg1
				endif
			endif
			"
		endif
	endif
	"
	"==============================================================================
	"  run : run in a detached xterm  (not available for MS Windows)
	"==============================================================================
	if s:C_OutputGvim == "xterm"
		"
		if s:C_ExecutableToRun !~ "^\s*$"
			if s:MSWIN
				exe		'!'.Quote.s:C_ExecutableToRun.Quote.' '.l:arguments
			else
				silent exe '!xterm -title '.s:C_ExecutableToRun.' '.s:C_XtermDefaults.' -e '.s:C_Wrapper.' '.s:C_ExecutableToRun.' '.l:arguments.' &'
				:redraw!
				call C_HlMessage( "executable : '".s:C_ExecutableToRun."'" )
			endif
		else

			silent call C_Link()
			"
			if	executable(Exe) && getftime(Exe) >= getftime(Obj) && getftime(Obj) >= getftime(Sou)
				if s:MSWIN
					exe		"!".Quote.ExeEsc.Quote." ".l:arguments
				else
					silent exe '!xterm -title '.ExeEsc.' '.s:C_XtermDefaults.' -e '.s:C_Wrapper.' '.ExeEsc.' '.l:arguments.' &'
					:redraw!
				endif
			else
				echomsg "file '".Exe.s:C_RunMsg1
			endif
		endif
	endif

endfunction    " ----------  end of function C_Run ----------
"
"------------------------------------------------------------------------------
"  C_Arguments : Arguments for the executable       {{{1
"------------------------------------------------------------------------------
function! C_Arguments ()
	let	Exe		  = expand("%:r").s:C_ExeExtension
  if empty(Exe)
		redraw
		echohl WarningMsg | echo "no file name " | echohl None
		return
  endif
	let	prompt	= 'command line arguments for "'.Exe.'" : '
	if exists("b:C_CmdLineArgs")
		let	b:C_CmdLineArgs= C_Input( prompt, b:C_CmdLineArgs, 'file' )
	else
		let	b:C_CmdLineArgs= C_Input( prompt , "", 'file' )
	endif
endfunction    " ----------  end of function C_Arguments ----------
"
"----------------------------------------------------------------------
"  C_Toggle_Gvim_Xterm : change output destination       {{{1
"----------------------------------------------------------------------
function! C_Toggle_Gvim_Xterm ()
	if s:C_OutputGvim == "vim"
		exe "aunmenu  <silent>  ".s:MenuRun.'.&output:\ '.s:output1
		exe "amenu    <silent>  ".s:MenuRun.'.&output:\ '.s:output2.'<Tab>\\ro              :call C_Toggle_Gvim_Xterm()<CR>'
		exe "imenu    <silent>  ".s:MenuRun.'.&output:\ '.s:output2.'<Tab>\\ro         <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
		let	s:C_OutputGvim	= "buffer"
	else
		if s:C_OutputGvim == "buffer"
				exe "aunmenu  <silent>  ".s:MenuRun.'.&output:\ '.s:output2
				if (!s:MSWIN)
					exe "amenu    <silent>  ".s:MenuRun.'.&output:\ '.s:output3.'<Tab>\\ro            :call C_Toggle_Gvim_Xterm()<CR>'
					exe "imenu    <silent>  ".s:MenuRun.'.&output:\ '.s:output3.'<Tab>\\ro       <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
				else
					exe "amenu    <silent>  ".s:MenuRun.'.&output:\ '.s:output1.'<Tab>\\ro            :call C_Toggle_Gvim_Xterm()<CR>'
					exe "imenu    <silent>  ".s:MenuRun.'.&output:\ '.s:output1.'<Tab>\\ro       <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
				endif
			if (!s:MSWIN) 
				let	s:C_OutputGvim	= "xterm"
			else
				let	s:C_OutputGvim	= "vim"
			endif
		else
			" ---------- output : xterm -> gvim
				exe "aunmenu  <silent>  ".s:MenuRun.'.&output:\ '.s:output3
				exe "amenu    <silent>  ".s:MenuRun.'.&output:\ '.s:output1.'<Tab>\\ro            :call C_Toggle_Gvim_Xterm()<CR>'
				exe "imenu    <silent>  ".s:MenuRun.'.&output:\ '.s:output1.'<Tab>\\ro       <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
			let	s:C_OutputGvim	= "vim"
		endif
	endif
	echomsg "output destination is '".s:C_OutputGvim."'"

endfunction    " ----------  end of function C_Toggle_Gvim_Xterm ----------
"
"------------------------------------------------------------------------------
"  C_XtermSize : xterm geometry       {{{1
"------------------------------------------------------------------------------
function! C_XtermSize ()
	let regex	= '-geometry\s\+\d\+x\d\+'
	let geom	= matchstr( s:C_XtermDefaults, regex )
	let geom	= matchstr( geom, '\d\+x\d\+' )
	let geom	= substitute( geom, 'x', ' ', "" )
	let	answer= C_Input("   xterm size (COLUMNS LINES) : ", geom )
	while match(answer, '^\s*\d\+\s\+\d\+\s*$' ) < 0
		let	answer= C_Input(" + xterm size (COLUMNS LINES) : ", geom )
	endwhile
	let answer  = substitute( answer, '\s\+', "x", "" )						" replace inner whitespaces
	let s:C_XtermDefaults	= substitute( s:C_XtermDefaults, regex, "-geometry ".answer , "" )
endfunction    " ----------  end of function C_XtermSize ----------
"
"------------------------------------------------------------------------------
"  run make(1)       {{{1
"------------------------------------------------------------------------------
let s:C_ExecutableToRun	    = ''
let s:C_Makefile						= ''
let s:C_MakeCmdLineArgs   	= ''   " command line arguments for Run-make; initially empty
"
"------------------------------------------------------------------------------
"  C_ChooseMakefile : choose a makefile       {{{1
"------------------------------------------------------------------------------
function! C_ChooseMakefile ()
	let s:C_Makefile	= ''
	let mkfile	= findfile( "Makefile", ".;" )    " try to find a Makefile
	if mkfile == ''
    let mkfile  = findfile( "makefile", ".;" )  " try to find a makefile
	endif
	if mkfile == ''
		let mkfile	= getcwd()
	endif
	let	s:C_Makefile	= C_Input ( "choose a Makefile: ", mkfile, "file" )
	if  s:MSWIN
		let	s:C_Makefile	= substitute( s:C_Makefile, '\\ ', ' ', 'g' )
	endif
endfunction    " ----------  end of function C_ChooseMakefile  ----------
"
"------------------------------------------------------------------------------
"  C_Make : run make       {{{1
"------------------------------------------------------------------------------
function! C_Make()
	exe	":cclose"
	" update : write source file if necessary
	exe	":update"
	" run make
	if s:C_Makefile == ''
		exe	":make ".s:C_MakeCmdLineArgs
	else
		exe	':lchdir  '.fnamemodify( s:C_Makefile, ":p:h" )
		if  s:MSWIN
			exe	':make -f "'.s:C_Makefile.'" '.s:C_MakeCmdLineArgs
		else
			exe	':make -f '.s:C_Makefile.' '.s:C_MakeCmdLineArgs
		endif
		exe	":lchdir -"
	endif
	exe	":botright cwindow"
	"
endfunction    " ----------  end of function C_Make ----------
"
"------------------------------------------------------------------------------
"  C_MakeClean : run 'make clean'       {{{1
"------------------------------------------------------------------------------
function! C_MakeClean()
	" run make clean
	if s:C_Makefile == ''
		exe	":!make clean"
	else
		exe	':lchdir  '.fnamemodify( s:C_Makefile, ":p:h" )
		if  s:MSWIN
			exe	':!make -f "'.s:C_Makefile.'" clean'
		else
			exe	':!make -f '.s:C_Makefile.' clean'
		endif
		exe	":lchdir -"
	endif
endfunction    " ----------  end of function C_MakeClean ----------

"------------------------------------------------------------------------------
"  C_MakeArguments : get make command line arguments       {{{1
"------------------------------------------------------------------------------
function! C_MakeArguments ()
	let	s:C_MakeCmdLineArgs= C_Input( 'make command line arguments : ', s:C_MakeCmdLineArgs, 'file' )
endfunction    " ----------  end of function C_MakeArguments ----------

"------------------------------------------------------------------------------
"  C_ExeToRun : choose executable to run       {{{1
"------------------------------------------------------------------------------
function! C_ExeToRun ()
	let	s:C_ExecutableToRun = C_Input( 'executable to run [tab compl.]: ', '', 'file' )
	if s:C_ExecutableToRun !~ "^\s*$"
		if s:MSWIN
			let s:C_ExecutableToRun = substitute(s:C_ExecutableToRun, '\\ ', ' ', 'g' )
		endif
		let	s:C_ExecutableToRun = escape( getcwd().'/', s:C_FilenameEscChar ).s:C_ExecutableToRun
	endif
endfunction    " ----------  end of function C_ExeToRun ----------
"
"------------------------------------------------------------------------------
"  C_SplintArguments : splint command line arguments       {{{1
"------------------------------------------------------------------------------
function! C_SplintArguments ()
	if s:C_SplintIsExecutable==0
		let s:C_HlMessage = ' Splint is not executable or not installed! '
	else
		let	prompt	= 'Splint command line arguments for "'.expand("%").'" : '
		if exists("b:C_SplintCmdLineArgs")
			let	b:C_SplintCmdLineArgs= C_Input( prompt, b:C_SplintCmdLineArgs )
		else
			let	b:C_SplintCmdLineArgs= C_Input( prompt , "" )
		endif
	endif
endfunction    " ----------  end of function C_SplintArguments ----------
"
"------------------------------------------------------------------------------
"  C_SplintCheck : run splint(1)        {{{1
"------------------------------------------------------------------------------
function! C_SplintCheck ()
	if s:C_SplintIsExecutable==0
		let s:C_HlMessage = ' Splint is not executable or not installed! '
		return
	endif
	let	l:currentbuffer=bufname("%")
	if &filetype != "c" && &filetype != "cpp"
		let s:C_HlMessage = ' "'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	let s:C_HlMessage = ""
	exe	":cclose"
	silent exe	":update"
	call s:C_SaveGlobalOption('makeprg')
	" Windows seems to need this:
	if	s:MSWIN
		:compiler splint
	endif
	:setlocal makeprg=splint
	"
	let l:arguments  = exists("b:C_SplintCmdLineArgs") ? b:C_SplintCmdLineArgs : ' '
	silent exe	"make ".l:arguments." ".escape(l:currentbuffer,s:C_FilenameEscChar)
	call s:C_RestoreGlobalOption('makeprg')
	exe	":botright cwindow"
	"
	" message in case of success
	"
	if l:currentbuffer == bufname("%")
		let s:C_HlMessage = " Splint --- no warnings for : ".l:currentbuffer
	endif
endfunction    " ----------  end of function C_SplintCheck ----------
"
"------------------------------------------------------------------------------
"  C_CppcheckCheck : run cppcheck(1)        {{{1
"------------------------------------------------------------------------------
function! C_CppcheckCheck ()
	if s:C_CppcheckIsExecutable==0
		let s:C_HlMessage = ' Cppcheck is not executable or not installed! '
		return
	endif
	let	l:currentbuffer=bufname("%")
	if &filetype != "c" && &filetype != "cpp"
		let s:C_HlMessage = ' "'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	let s:C_HlMessage = ""
	exe	":cclose"
	silent exe	":update"
	call s:C_SaveGlobalOption('makeprg')
	"
	call s:C_SaveGlobalOption('errorformat')
	setlocal errorformat=[%f:%l]:%m
	" Windows seems to need this:
	if	s:MSWIN
		:compiler cppcheck
	endif
	:setlocal makeprg=cppcheck
	"
	silent exe	"make --enable=".s:C_CppcheckSeverity.' '.escape(l:currentbuffer,s:C_FilenameEscChar)
	call s:C_RestoreGlobalOption('makeprg')
	exe	":botright cwindow"
	"
	" message in case of success
	"
	if l:currentbuffer == bufname("%")
		let s:C_HlMessage = " Cppcheck --- no warnings for : ".l:currentbuffer
	endif
endfunction    " ----------  end of function C_CppcheckCheck ----------

"===  FUNCTION  ================================================================
"          NAME:  C_CppcheckSeverityList     {{{1
"   DESCRIPTION:  cppcheck severity : callback function for completion
"    PARAMETERS:  ArgLead - 
"                 CmdLine - 
"                 CursorPos - 
"       RETURNS:  
"===============================================================================
function!	C_CppcheckSeverityList ( ArgLead, CmdLine, CursorPos )
	return filter( copy( s:CppcheckSeverity ), 'v:val =~ "\\<'.a:ArgLead.'\\w*"' )
endfunction    " ----------  end of function C_CppcheckSeverityList  ----------

"===  FUNCTION  ================================================================
"          NAME:  C_GetCppcheckSeverity     {{{1
"   DESCRIPTION:  cppcheck severity : used in command definition
"    PARAMETERS:  severity - cppcheck severity
"       RETURNS:  
"===============================================================================
function! C_GetCppcheckSeverity ( severity )
	let	sev	= a:severity
	let sev	= substitute( sev, '^\s\+', '', '' )  	     			" remove leading whitespaces
	let sev	= substitute( sev, '\s\+$', '', '' )	       			" remove trailing whitespaces
	"
	if index( s:CppcheckSeverity, tolower(sev) ) >= 0
		let s:C_CppcheckSeverity = sev
		echomsg "cppcheck severity is set to '".s:C_CppcheckSeverity."'"
	else
		let s:C_CppcheckSeverity = 'all'			                        " the default
		echomsg "wrong argument '".a:severity."' / severity is set to '".s:C_CppcheckSeverity."'"
	endif
	"
endfunction    " ----------  end of function C_GetCppcheckSeverity  ----------
"
"===  FUNCTION  ================================================================
"          NAME:  C_CppcheckSeverityInput
"   DESCRIPTION:  read cppcheck severity from the command line
"    PARAMETERS:  -
"       RETURNS:  
"===============================================================================
function! C_CppcheckSeverityInput ()
		let retval = input( "cppcheck severity  (current = '".s:C_CppcheckSeverity."' / tab exp.): ", '', 'customlist,C_CppcheckSeverityList' )
		redraw!
		call C_GetCppcheckSeverity( retval )
	return
endfunction    " ----------  end of function C_CppcheckSeverityInput  ----------
"
"------------------------------------------------------------------------------
"  C_CodeCheckArguments : CodeCheck command line arguments       {{{1
"------------------------------------------------------------------------------
function! C_CodeCheckArguments ()
	if s:C_CodeCheckIsExecutable==0
		let s:C_HlMessage = ' CodeCheck is not executable or not installed! '
	else
		let	prompt	= 'CodeCheck command line arguments for "'.expand("%").'" : '
		if exists("b:C_CodeCheckCmdLineArgs")
			let	b:C_CodeCheckCmdLineArgs= C_Input( prompt, b:C_CodeCheckCmdLineArgs )
		else
			let	b:C_CodeCheckCmdLineArgs= C_Input( prompt , s:C_CodeCheckOptions )
		endif
	endif
endfunction    " ----------  end of function C_CodeCheckArguments ----------
"
"------------------------------------------------------------------------------
"  C_CodeCheck : run CodeCheck       {{{1
"------------------------------------------------------------------------------
function! C_CodeCheck ()
	if s:C_CodeCheckIsExecutable==0
		let s:C_HlMessage = ' CodeCheck is not executable or not installed! '
		return
	endif
	let	l:currentbuffer=bufname("%")
	if &filetype != "c" && &filetype != "cpp"
		let s:C_HlMessage = ' "'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	let s:C_HlMessage = ""
	exe	":cclose"
	silent exe	":update"
	call s:C_SaveGlobalOption('makeprg')
	exe	"setlocal makeprg=".s:C_CodeCheckExeName
	"
	" match the splint error messages (quickfix commands)
	" ignore any lines that didn't match one of the patterns
	"
	call s:C_SaveGlobalOption('errorformat')
	setlocal errorformat=%f(%l)%m
	"
	let l:arguments  = exists("b:C_CodeCheckCmdLineArgs") ? b:C_CodeCheckCmdLineArgs : ""
	if empty( l:arguments )
		let l:arguments	=	s:C_CodeCheckOptions
	endif
	exe	":make ".l:arguments." ".escape( l:currentbuffer, s:C_FilenameEscChar )
	call s:C_RestoreGlobalOption('errorformat')
	call s:C_RestoreGlobalOption('makeprg')
	exe	":botright cwindow"
	"
	" message in case of success
	"
	if l:currentbuffer == bufname("%")
		let s:C_HlMessage = " CodeCheck --- no warnings for : ".l:currentbuffer
	endif
endfunction    " ----------  end of function C_CodeCheck ----------
"
"------------------------------------------------------------------------------
"  C_Indent : run indent(1)       {{{1
"------------------------------------------------------------------------------
"
function! C_Indent ( )
	if s:C_IndentIsExecutable == 0
		echomsg 'indent is not executable or not installed!'
		return
	endif
	let	l:currentbuffer=expand("%:p")
	if &filetype != "c" && &filetype != "cpp"
		echomsg '"'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	if C_Input("indent whole file [y/n/Esc] : ", "y" ) != "y"
		return
	endif
	:update

	exe	":cclose"
	if s:MSWIN
		silent exe ":%!indent "
	else
		silent exe ":%!indent 2> ".s:C_IndentErrorLog
		redraw!
		call s:C_SaveGlobalOption('errorformat')
		if getfsize( s:C_IndentErrorLog ) > 0
			exe ':edit! '.s:C_IndentErrorLog
			let errorlogbuffer	= bufnr("%")
			exe ':%s/^indent: Standard input/indent: '.escape( l:currentbuffer, '/' ).'/'
			setlocal errorformat=indent:\ %f:%l:%m
			:cbuffer
			exe ':bdelete! '.errorlogbuffer
			exe	':botright cwindow'
		else
			echomsg 'File "'.l:currentbuffer.'" reformatted.'
		endif
		call s:C_RestoreGlobalOption('errorformat')
	endif

endfunction    " ----------  end of function C_Indent ----------
"
"------------------------------------------------------------------------------
"  C_HlMessage : indent message     {{{1
"------------------------------------------------------------------------------
function! C_HlMessage ( ... )
	redraw!
	echohl Search
	if a:0 == 0
		echo s:C_HlMessage
	else
		echo a:1
	endif
	echohl None
endfunction    " ----------  end of function C_HlMessage ----------
"
"------------------------------------------------------------------------------
"  C_Settings : settings     {{{1
"------------------------------------------------------------------------------
function! C_Settings ()
	let	txt =     " C/C++-Support settings\n\n"
	let txt = txt.'                   author :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|AUTHOR|'      )."\"\n"
	let txt = txt.'                authorref :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|AUTHORREF|'   )."\"\n"
	let txt = txt.'                  company :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|COMPANY|'     )."\"\n"
	let txt = txt.'         copyright holder :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|COPYRIGHT|'   )."\"\n"
	let txt = txt.'                    email :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|EMAIL|'       )."\"\n"
  let txt = txt.'                  licence :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|LICENSE|'     )."\"\n"
	let txt = txt.'             organization :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|ORGANIZATION|')."\"\n"
	let txt = txt.'                  project :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|PROJECT|'     )."\"\n"
	let txt = txt.'         C / C++ compiler :  '.s:C_CCompiler.' / '.s:C_CplusCompiler."\n"
	let txt = txt.'         C file extension :  "'.s:C_CExtension.'"  (everything else is C++)'."\n"
	let txt = txt.'    extension for objects :  "'.s:C_ObjExtension."\"\n"
	let txt = txt.'extension for executables :  "'.s:C_ExeExtension."\"\n"
	let txt = txt.'       compiler flags (C) :  "'.s:C_CFlags."\"\n"
	let txt = txt.'         linker flags (C) :  "'.s:C_LFlags."\"\n"
	let txt = txt.'            libraries (C) :  "'.s:C_Libs."\"\n"
	let txt = txt.'     compiler flags (C++) :  "'.s:C_CplusCFlags."\"\n"
	let txt = txt.'       linker flags (C++) :  "'.s:C_CplusLFlags."\"\n"
	let txt = txt.'          libraries (C++) :  "'.s:C_CplusLibs."\"\n"
	let txt = txt.'   code snippet directory :  "'.s:C_CodeSnippets."\"\n"
	" ----- template files  ------------------------
 	let txt = txt.'           template style :  "'.mmtemplates#core#Resource ( g:C_Templates, "style" )[0]."\"\n"
	let txt = txt.'      plugin installation :  "'.g:C_Installation."\"\n"
	if g:C_Installation == 'system'
		let txt = txt.'global template directory :  '.s:C_GlobalTemplateDir."\n"
		if filereadable( s:C_LocalTemplateFile )
			let txt = txt.' local template directory :  '.s:C_LocalTemplateDir."\n"
		endif
	else
		let txt = txt.' local template directory :  '.s:C_LocalTemplateDir."\n"
	endif
	if	!s:MSWIN
		let txt = txt.'           xterm defaults :  '.s:C_XtermDefaults."\n"
	endif
	" ----- dictionaries ------------------------
	if !empty(g:C_Dictionary_File)
		let ausgabe= &dictionary
		let ausgabe= substitute( ausgabe, ",", ",\n                           + ", "g" )
		let txt = txt."       dictionary file(s) :  ".ausgabe."\n"
	endif
	let txt = txt.'     current output dest. :  '.s:C_OutputGvim."\n"
	" ----- splint ------------------------------
	if s:C_SplintIsExecutable==1
		if exists("b:C_SplintCmdLineArgs")
			let ausgabe = b:C_SplintCmdLineArgs
		else
			let ausgabe = ""
		endif
		let txt = txt."        splint options(s) :  ".ausgabe."\n"
	endif
	" ----- cppcheck ------------------------------
	if s:C_CppcheckIsExecutable==1
		let txt = txt."        cppcheck severity :  ".s:C_CppcheckSeverity."\n"
	endif
	" ----- code check --------------------------
	if s:C_CodeCheckIsExecutable==1
		if exists("b:C_CodeCheckCmdLineArgs")
			let ausgabe = b:C_CodeCheckCmdLineArgs
		else
			let ausgabe = s:C_CodeCheckOptions
		endif
		let txt = txt."CodeCheck (TM) options(s) :  ".ausgabe."\n"
	endif
	let txt = txt."\n"
	let	txt = txt."__________________________________________________________________________\n"
	let	txt = txt." C/C++-Support, Version ".g:C_Version." / Dr.-Ing. Fritz Mehner / mehner.fritz@fh-swf.de\n\n"
	echo txt
endfunction    " ----------  end of function C_Settings ----------
"
"------------------------------------------------------------------------------
"  C_Hardcopy : hardcopy     {{{1
"    MSWIN : a printer dialog is displayed
"    other : print PostScript to file
"------------------------------------------------------------------------------
function! C_Hardcopy () range
  let outfile = expand("%")
  if empty(outfile)
		let s:C_HlMessage = 'Buffer has no name.'
		call C_HlMessage()
  endif
	let outdir	= getcwd()
	if filewritable(outdir) != 2
		let outdir	= $HOME
	endif
	if  !s:MSWIN
		let outdir	= outdir.'/'
	endif
  let old_printheader=&printheader
  exe  ':set printheader='.s:C_Printheader
  " ----- normal mode ----------------
  if a:firstline == a:lastline
    silent exe  'hardcopy > '.outdir.outfile.'.ps'
    if  !s:MSWIN
      echo 'file "'.outfile.'" printed to "'.outdir.outfile.'.ps"'
    endif
  endif
  " ----- visual mode / range ----------------
  if a:firstline < a:lastline
    silent exe  a:firstline.','.a:lastline."hardcopy > ".outdir.outfile.".ps"
    if  !s:MSWIN
      echo 'file "'.outfile.'" (lines '.a:firstline.'-'.a:lastline.') printed to "'.outdir.outfile.'.ps"'
    endif
  endif
  exe  ':set printheader='.escape( old_printheader, ' %' )
endfunction   " ---------- end of function  C_Hardcopy  ----------
"
"------------------------------------------------------------------------------
"  C_HelpCsupport : help csupport     {{{1
"------------------------------------------------------------------------------
function! C_HelpCsupport ()
	try
		:help csupport
	catch
		exe ':helptags '.s:plugin_dir.'/doc'
		:help csupport
	endtry
endfunction    " ----------  end of function C_HelpCsupport ----------
"
"------------------------------------------------------------------------------
"  C_Help : lookup word under the cursor or ask    {{{1
"------------------------------------------------------------------------------
"
let s:C_DocBufferName       = "C_HELP"
let s:C_DocHelpBufferNumber = -1
"
function! C_Help( type )

	let cuc		= getline(".")[col(".") - 1]		" character under the cursor
	let	item	= expand("<cword>")							" word under the cursor
	if empty(cuc) || empty(item) || match( item, cuc ) == -1
		let	item=C_Input('name of the manual page : ', '' )
	endif

	if empty(item)
		return
	endif
	"------------------------------------------------------------------------------
	"  replace buffer content with bash help text
	"------------------------------------------------------------------------------
	"
	" jump to an already open bash help window or create one
	"
	if bufloaded(s:C_DocBufferName) != 0 && bufwinnr(s:C_DocHelpBufferNumber) != -1
		exe bufwinnr(s:C_DocHelpBufferNumber) . "wincmd w"
		" buffer number may have changed, e.g. after a 'save as'
		if bufnr("%") != s:C_DocHelpBufferNumber
			let s:C_DocHelpBufferNumber=bufnr(s:C_OutputBufferName)
			exe ":bn ".s:C_DocHelpBufferNumber
		endif
	else
		exe ":new ".s:C_DocBufferName
		let s:C_DocHelpBufferNumber=bufnr("%")
		setlocal buftype=nofile
		setlocal noswapfile
		setlocal bufhidden=delete
		setlocal filetype=sh		" allows repeated use of <S-F1>
		setlocal syntax=OFF
	endif
	setlocal	modifiable
	"
	if a:type == 'm' 
		"
		" Is there more than one manual ?
		"
		let manpages	= system( s:C_Man.' -k '.item )
		if v:shell_error
			echomsg	"Shell command '".s:C_Man." -k ".item."' failed."
			:close
			return
		endif
		let	catalogs	= split( manpages, '\n', )
		let	manual		= {}
		"
		" Select manuals where the name exactly matches
		"
		for line in catalogs
			if line =~ '^'.item.'\s\+(' 
				let	itempart	= split( line, '\s\+' )
				let	catalog		= itempart[1][1:-2]
				if match( catalog, '.p$' ) == -1
					let	manual[catalog]	= catalog
				endif
			endif
		endfor
		"
		" Build a selection list if there are more than one manual
		"
		let	catalog	= ""
		if len(keys(manual)) > 1
			for key in keys(manual)
				echo ' '.item.'  '.key
			endfor
			let defaultcatalog	= ''
			if has_key( manual, '3' )
				let defaultcatalog	= '3'
			else
				if has_key( manual, '2' )
					let defaultcatalog	= '2'
				endif
			endif
			let	catalog	= input( 'select manual section (<Enter> cancels) : ', defaultcatalog )
			if ! has_key( manual, catalog )
				:close
				:redraw
				echomsg	"no appropriate manual section '".catalog."'"
				return
			endif
		endif

		set filetype=man
		silent exe ":%!".s:C_Man." ".catalog." ".item

		if s:MSWIN
			call s:C_RemoveSpecialCharacters()
		endif
	endif

	setlocal nomodifiable
endfunction		" ---------- end of function  C_Help  ----------
"
"------------------------------------------------------------------------------
"  C_RemoveSpecialCharacters   {{{1
"  remove <backspace><any character> in CYGWIN man(1) output
"  remove           _<any character> in CYGWIN man(1) output
"------------------------------------------------------------------------------
"
function! s:C_RemoveSpecialCharacters ( )
	let	patternunderline	= '_\%x08'
	let	patternbold				= '\%x08.'
	setlocal modifiable
	if search(patternunderline) != 0
		silent exe ':%s/'.patternunderline.'//g'
	endif
	if search(patternbold) != 0
		silent exe ':%s/'.patternbold.'//g'
	endif
	setlocal nomodifiable
	silent normal gg
endfunction		" ---------- end of function  s:C_RemoveSpecialCharacters   ----------

"------------------------------------------------------------------------------
"  C_CreateMenusDelayed     {{{1
"------------------------------------------------------------------------------
let s:C_MenusVisible = 'no'								" state variable controlling the C-menus
"
function! C_CreateMenusDelayed ()
	if s:C_CreateMenusDelayed == 'yes' && s:C_MenusVisible == 'no'
		call C_CreateGuiMenus()
	endif
endfunction    " ----------  end of function C_CreateMenusDelayed  ----------
"
"------------------------------------------------------------------------------
"  C_CreateGuiMenus     {{{1
"------------------------------------------------------------------------------
function! C_CreateGuiMenus ()
	if s:C_MenusVisible == 'no'
		aunmenu <silent> &Tools.Load\ C\ Support
		amenu   <silent> 40.1000 &Tools.-SEP100- :
		amenu   <silent> 40.1030 &Tools.Unload\ C\ Support <C-C>:call C_RemoveGuiMenus()<CR>
		call s:C_RereadTemplates('no')
		call s:C_InitMenus()
		let  s:C_MenusVisible = 'yes'
	endif
endfunction    " ----------  end of function C_CreateGuiMenus  ----------

function! C_CheckAndRereadTemplates ()
	if s:C_TemplatesLoaded == 'no'
		call s:C_RereadTemplates('no')        
		let  s:C_TemplatesLoaded	= 'yes'
	endif
endfunction    " ----------  end of function C_CheckAndRereadTemplates  ----------

"===  FUNCTION  ================================================================
"          NAME:  C_RereadTemplates     {{{1
"   DESCRIPTION:  rebuild commands and the menu from the (changed) template file
"    PARAMETERS:  displaymsg - yes / no
"       RETURNS:  
"===============================================================================
function! s:C_RereadTemplates ( displaymsg )
	let g:C_Templates = mmtemplates#core#NewLibrary ()
	call mmtemplates#core#ChangeSyntax  ( g:C_Templates, 'comment', '§', '§' )
	let s:C_TemplateJumpTarget 	=  mmtemplates#core#Resource ( g:C_Templates, "jumptag" )[0]

	let	messsage							= ''
	"
	if g:C_Installation == 'system'
		"-------------------------------------------------------------------------------
		" SYSTEM INSTALLATION
		"-------------------------------------------------------------------------------
		if filereadable( s:C_GlobalTemplateFile )
			call mmtemplates#core#ReadTemplates ( g:C_Templates, 'load', s:C_GlobalTemplateFile )
		else
			echomsg "Global template file '".s:C_GlobalTemplateFile."' not readable."
			return
		endif
		let	messsage	= "Templates read from '".s:C_GlobalTemplateFile."'"
		"
		"-------------------------------------------------------------------------------
		" handle local template files
		"-------------------------------------------------------------------------------
		if finddir( s:C_LocalTemplateDir ) == ''
			" try to create a local template directory
			if exists("*mkdir")
				try 
					call mkdir( s:C_LocalTemplateDir, "p" )
				catch /.*/
				endtry
			endif
		endif

		if isdirectory( s:C_LocalTemplateDir ) && !filereadable( s:C_LocalTemplateFile )
			" write a default local template file
			let template	= [	]
			let sample_template_file	= fnamemodify( s:C_GlobalTemplateDir, ':h' ).'/rc/sample_template_file'
			if filereadable( sample_template_file )
				for line in readfile( sample_template_file )
					call add( template, line )
				endfor
				call writefile( template, s:C_LocalTemplateFile )
			endif
		endif
		"
		if filereadable( s:C_LocalTemplateFile )
			call mmtemplates#core#ReadTemplates ( g:C_Templates, 'load', s:C_LocalTemplateFile )
			let messsage	= messsage." and '".s:C_LocalTemplateFile."'"
			if mmtemplates#core#ExpandText( g:C_Templates, '|AUTHOR|' ) == 'YOUR NAME'
				echomsg "Please set your personal details in file '".s:C_LocalTemplateFile."'."
			endif
		endif
		"
	else
		"-------------------------------------------------------------------------------
		" LOCAL INSTALLATION
		"-------------------------------------------------------------------------------
		if filereadable( s:C_LocalTemplateFile )
			call mmtemplates#core#ReadTemplates ( g:C_Templates, 'load', s:C_LocalTemplateFile )
			let	messsage	= "Templates read from '".s:C_LocalTemplateFile."'"
		else
			echomsg "Local template file '".s:C_LocalTemplateFile."' not readable." 
			return
		endif
		"
	endif
	if a:displaymsg == 'yes'
		echomsg messsage.'.'
	endif

endfunction    " ----------  end of function s:C_RereadTemplates  ----------

"------------------------------------------------------------------------------
"  C_ToolMenu     {{{1
"------------------------------------------------------------------------------
function! C_ToolMenu ()
	amenu   <silent> 40.1000 &Tools.-SEP100- :
	amenu   <silent> 40.1030 &Tools.Load\ C\ Support      :call C_CreateGuiMenus()<CR>
	imenu   <silent> 40.1030 &Tools.Load\ C\ Support <C-C>:call C_CreateGuiMenus()<CR>
endfunction    " ----------  end of function C_ToolMenu  ----------

"------------------------------------------------------------------------------
"  C_RemoveGuiMenus     {{{1
"------------------------------------------------------------------------------
function! C_RemoveGuiMenus ()
	if s:C_MenusVisible == 'yes'
		exe "aunmenu <silent> ".s:C_RootMenu
		"
		aunmenu <silent> &Tools.Unload\ C\ Support
		call C_ToolMenu()
		"
		let s:C_MenusVisible = 'no'
	endif
endfunction    " ----------  end of function C_RemoveGuiMenus  ----------

"------------------------------------------------------------------------------
" C_OpenFold     {{{1
" Open fold and go to the first or last line of this fold. 
"------------------------------------------------------------------------------
function! C_OpenFold ( mode )
	if foldclosed(".") >= 0
		" we are on a closed  fold: get end position, open fold, jump to the
		" last line of the previously closed fold
		let	foldstart	= foldclosed(".")
		let	foldend		= foldclosedend(".")
		normal zv
		if a:mode == 'below'
			exe ":".foldend
		endif
		if a:mode == 'start'
			exe ":".foldstart
		endif
	endif
endfunction    " ----------  end of function C_OpenFold  ----------

"------------------------------------------------------------------------------
"  C_HighlightJumpTargets
"------------------------------------------------------------------------------
function! C_HighlightJumpTargets ()
	if s:C_Ctrl_j == 'on'
		exe 'match Search /'.s:C_TemplateJumpTarget1.'\|'.s:C_TemplateJumpTarget2.'/'
	endif
endfunction    " ----------  end of function C_HighlightJumpTargets  ----------

"------------------------------------------------------------------------------
"  C_JumpCtrlJ     {{{1
"------------------------------------------------------------------------------
function! C_JumpCtrlJ ()
  let match	= search( s:C_TemplateJumpTarget1.'\|'.s:C_TemplateJumpTarget2, 'c' )
	if match > 0
		" remove the target
		call setline( match, substitute( getline('.'), s:C_TemplateJumpTarget1.'\|'.s:C_TemplateJumpTarget2, '', '' ) )
	else
		" try to jump behind parenthesis or strings in the current line 
		if match( getline(".")[col(".") - 1], "[\]})\"'`]"  ) != 0
			call search( "[\]})\"'`]", '', line(".") )
		endif
		normal l
	endif
	return ''
endfunction    " ----------  end of function C_JumpCtrlJ  ----------
"
"------------------------------------------------------------------------------
"  C_ExpandSingleMacro     {{{1
"------------------------------------------------------------------------------
function! C_ExpandSingleMacro ( val, macroname, replacement )
  return substitute( a:val, escape(a:macroname, '$' ), a:replacement, "g" )
endfunction    " ----------  end of function C_ExpandSingleMacro  ----------

"------------------------------------------------------------------------------
"  insert date and time     {{{1
"------------------------------------------------------------------------------
function! C_InsertDateAndTime ( format )
	if &foldenable && foldclosed(".") >= 0
		echohl WarningMsg | echomsg s:MsgInsNotAvail  | echohl None
		return ""
	endif
	if col(".") > 1
		exe 'normal a'.C_DateAndTime(a:format)
	else
		exe 'normal i'.C_DateAndTime(a:format)
	endif
endfunction    " ----------  end of function C_InsertDateAndTime  ----------

"------------------------------------------------------------------------------
"  generate date and time     {{{1
"------------------------------------------------------------------------------
function! C_DateAndTime ( format )
	if a:format == 'd'
		return strftime( s:C_FormatDate )
	elseif a:format == 't'
		return strftime( s:C_FormatTime )
	elseif a:format == 'dt'
		return strftime( s:C_FormatDate ).' '.strftime( s:C_FormatTime )
	elseif a:format == 'y'
		return strftime( s:C_FormatYear )
	endif
endfunction    " ----------  end of function C_DateAndTime  ----------

"------------------------------------------------------------------------------
"  check for header or implementation file     {{{1
"------------------------------------------------------------------------------
function! C_InsertTemplateWrapper ()
	" prevent insertion for a file generated from a link error:
	"
	call C_CheckAndRereadTemplates()
	if isdirectory(expand('%:p:h'))
		if index( s:C_SourceCodeExtensionsList, expand('%:e') ) >= 0 
 			call mmtemplates#core#InsertTemplate(g:C_Templates, 'Comments.file description impl')
		else
 			call mmtemplates#core#InsertTemplate(g:C_Templates, 'Comments.file description-header')
		endif
		set modified
	endif
endfunction    " ----------  end of function C_InsertTemplateWrapper  ----------

"
"===  FUNCTION  ================================================================
"          NAME:  CreateAdditionalMaps     {{{1
"   DESCRIPTION:  create additional maps
"    PARAMETERS:  -
"       RETURNS:  
"===============================================================================
function! s:CreateAdditionalMaps ()
	"
	" ---------- Do we have a mapleader other than '\' ? ------------
	if exists("g:C_MapLeader")
		let maplocalleader  = g:C_MapLeader
	endif    
	"
	" ---------- C/C++ dictionary -----------------------------------
	" This will enable keyword completion for C and C++
	" using Vim's dictionary feature |i_CTRL-X_CTRL-K|.
	" Set the new dictionaries in front of the existing ones
	" 
	if exists("g:C_Dictionary_File")
		silent! exe 'setlocal dictionary+='.g:C_Dictionary_File
	endif    
	"
	"-------------------------------------------------------------------------------
	" USER DEFINED COMMANDS
	"-------------------------------------------------------------------------------
	"
	" ---------- F-key mappings  ------------------------------------
	"
	"   Alt-F9   write buffer and compile
	"       F9   compile and link
	"  Ctrl-F9   run executable
	" Shift-F9   command line arguments
	"
	map  <buffer>  <silent>  <A-F9>       :call C_Compile()<CR>:call C_HlMessage()<CR>
	imap <buffer>  <silent>  <A-F9>  <C-C>:call C_Compile()<CR>:call C_HlMessage()<CR>
	"
	map  <buffer>  <silent>    <F9>       :call C_Link()<CR>:call C_HlMessage()<CR>
	imap <buffer>  <silent>    <F9>  <C-C>:call C_Link()<CR>:call C_HlMessage()<CR>
	"
	map  <buffer>  <silent>  <C-F9>       :call C_Run()<CR>
	imap <buffer>  <silent>  <C-F9>  <C-C>:call C_Run()<CR>
	"
	map  <buffer>  <silent>  <S-F9>       :call C_Arguments()<CR>
	imap <buffer>  <silent>  <S-F9>  <C-C>:call C_Arguments()<CR>
	"

	" ---------- KEY MAPPINGS : MENU ENTRIES -------------------------------------
	" ---------- comments menu  ------------------------------------------------
	"
	noremap    <buffer>  <silent>  <LocalLeader>cl         :call C_EndOfLineComment()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>cl    <Esc>:call C_EndOfLineComment()<CR>
	"
	nnoremap   <buffer>  <silent>  <LocalLeader>cj         :call C_AdjustLineEndComm()<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>cj         :call C_AdjustLineEndComm()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>cj    <Esc>:call C_AdjustLineEndComm()<CR>a
	"
	noremap    <buffer>  <silent>  <LocalLeader>cs         :call C_GetLineEndCommCol()<CR>

	noremap    <buffer>  <silent>  <LocalLeader>c*         :call C_CodeToCommentC()<CR>:nohlsearch<CR>j
	vnoremap   <buffer>  <silent>  <LocalLeader>c*         :call C_CodeToCommentC()<CR>:nohlsearch<CR>j

	noremap    <buffer>  <silent>  <LocalLeader>cc         :call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j
	vnoremap   <buffer>  <silent>  <LocalLeader>cc         :call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j
	noremap    <buffer>  <silent>  <LocalLeader>co         :call C_CommentToCode()<CR>:nohlsearch<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>co         :call C_CommentToCode()<CR>:nohlsearch<CR>

	noremap    <buffer>  <silent>  <LocalLeader>cd    <Esc>:call C_InsertDateAndTime('d')<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>cd    <Esc>:call C_InsertDateAndTime('d')<CR>a
	vnoremap   <buffer>  <silent>  <LocalLeader>cd   s<Esc>:call C_InsertDateAndTime('d')<CR>a
	noremap    <buffer>  <silent>  <LocalLeader>ct    <Esc>:call C_InsertDateAndTime('dt')<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>ct    <Esc>:call C_InsertDateAndTime('dt')<CR>a
	vnoremap   <buffer>  <silent>  <LocalLeader>ct   s<Esc>:call C_InsertDateAndTime('dt')<CR>a
	" 
	noremap    <buffer>  <silent>  <LocalLeader>cx          :call C_CommentToggle( )<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>cx    <Esc>:call C_CommentToggle( )<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>cx         :call C_CommentToggle( )<CR>
	" 
	" ---------- statements menu  ------------------------------------------------
	"
	" ---------- preprocessor menu  ----------------------------------------------
	"
	noremap    <buffer>  <silent>  <LocalLeader>pi0       :call C_PPIf0("a")<CR>2ji
	inoremap   <buffer>  <silent>  <LocalLeader>pi0  <Esc>:call C_PPIf0("a")<CR>2ji
	vnoremap   <buffer>  <silent>  <LocalLeader>pi0  <Esc>:call C_PPIf0("v")<CR>

	noremap    <buffer>  <silent>  <LocalLeader>pr0       :call C_PPIf0Remove()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>pr0  <Esc>:call C_PPIf0Remove()<CR>
	"
	" ---------- idioms menu  ----------------------------------------------------
	"
	noremap    <buffer>  <silent>  <LocalLeader>i0         :call C_CodeFor("up"    )<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>i0         :call C_CodeFor("up","v")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>i0    <Esc>:call C_CodeFor("up"    )<CR>
	noremap    <buffer>  <silent>  <LocalLeader>in         :call C_CodeFor("down"    )<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>in         :call C_CodeFor("down","v")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>in    <Esc>:call C_CodeFor("down"    )<CR>
	"
	" ---------- snippet menu : snippets -----------------------------------------
	"
	noremap    <buffer>  <silent>  <LocalLeader>nr         :call C_CodeSnippet("r")<CR>
	noremap    <buffer>  <silent>  <LocalLeader>nv         :call C_CodeSnippet("view")<CR>
	noremap    <buffer>  <silent>  <LocalLeader>nw         :call C_CodeSnippet("w")<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>nw    <Esc>:call C_CodeSnippet("wv")<CR>
	noremap    <buffer>  <silent>  <LocalLeader>ne         :call C_CodeSnippet("e")<CR>
	"
	inoremap   <buffer>  <silent>  <LocalLeader>nr    <Esc>:call C_CodeSnippet("r")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nv    <Esc>:call C_CodeSnippet("view")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nw    <Esc>:call C_CodeSnippet("w")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>ne    <Esc>:call C_CodeSnippet("e")<CR>
	"
	" ---------- snippet menu : prototypes ---------------------------------------
	"
	noremap    <buffer>  <silent>  <LocalLeader>np        :call C_ProtoPick("function")<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>np        :call C_ProtoPick("function")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>np   <Esc>:call C_ProtoPick("function")<CR>
	"                                                                                 
	noremap    <buffer>  <silent>  <LocalLeader>nf        :call C_ProtoPick("function")<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>nf        :call C_ProtoPick("function")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nf   <Esc>:call C_ProtoPick("function")<CR>
	"
	noremap    <buffer>  <silent>  <LocalLeader>nm        :call C_ProtoPick("method")<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>nm        :call C_ProtoPick("method")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nm   <Esc>:call C_ProtoPick("method")<CR>
	"
	noremap    <buffer>  <silent>  <LocalLeader>ni         :call C_ProtoInsert()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>ni    <Esc>:call C_ProtoInsert()<CR>
	"
	noremap    <buffer>  <silent>  <LocalLeader>nc         :call C_ProtoClear()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nc    <Esc>:call C_ProtoClear()<CR>
	"
	noremap    <buffer>  <silent>  <LocalLeader>ns         :call C_ProtoShow()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>ns    <Esc>:call C_ProtoShow()<CR>
	"
	" ---------- snippet menu : templates ----------------------------------------
	"
	nnoremap    <buffer>  <silent> <LocalLeader>ntl       :call mmtemplates#core#EditTemplateFiles(g:C_Templates,-1)<CR>
	inoremap    <buffer>  <silent> <LocalLeader>ntl  <C-C>:call mmtemplates#core#EditTemplateFiles(g:C_Templates,-1)<CR>
	if g:C_Installation == 'system'
		nnoremap  <buffer>  <silent> <LocalLeader>ntg       :call mmtemplates#core#EditTemplateFiles(g:C_Templates,1)<CR>
		inoremap  <buffer>  <silent> <LocalLeader>ntg  <C-C>:call mmtemplates#core#EditTemplateFiles(g:C_Templates,1)<CR>
	endif
	nnoremap    <buffer>  <silent> <LocalLeader>ntr       :call mmtemplates#core#ReadTemplates(g:C_Templates,"reload","all")<CR>
	inoremap    <buffer>  <silent> <LocalLeader>ntr  <C-C>:call mmtemplates#core#ReadTemplates(g:C_Templates,"reload","all")<CR>
	nnoremap    <buffer>  <silent> <LocalLeader>nts       :call mmtemplates#core#ChooseStyle(g:C_Templates,"!pick")<CR>
	inoremap    <buffer>  <silent> <LocalLeader>nts  <C-C>:call mmtemplates#core#ChooseStyle(g:C_Templates,"!pick")<CR>
	"
	" ---------- C++ menu ----------------------------------------------------
	"
	" ---------- run menu --------------------------------------------------------
	"
	map  <buffer>  <silent>  <LocalLeader>rc         :call C_Compile()<CR>:call C_HlMessage()<CR>
	imap <buffer>  <silent>  <LocalLeader>rc    <C-C>:call C_Compile()<CR>:call C_HlMessage()<CR>
	map  <buffer>  <silent>  <LocalLeader>rl         :call C_Link()<CR>:call C_HlMessage()<CR>
	imap <buffer>  <silent>  <LocalLeader>rl    <C-C>:call C_Link()<CR>:call C_HlMessage()<CR>
	map  <buffer>  <silent>  <LocalLeader>rr         :call C_Run()<CR>
	imap <buffer>  <silent>  <LocalLeader>rr    <C-C>:call C_Run()<CR>
	map  <buffer>  <silent>  <LocalLeader>ra         :call C_Arguments()<CR>
	imap <buffer>  <silent>  <LocalLeader>ra    <C-C>:call C_Arguments()<CR>
	map  <buffer>  <silent>  <LocalLeader>rm         :call C_Make()<CR>
	imap <buffer>  <silent>  <LocalLeader>rm    <C-C>:call C_Make()<CR>
	map  <buffer>  <silent>  <LocalLeader>rcm        :call C_ChooseMakefile()<CR>
	imap <buffer>  <silent>  <LocalLeader>rcm   <C-C>:call C_ChooseMakefile()<CR>
	map  <buffer>  <silent>  <LocalLeader>rmc        :call C_MakeClean()<CR>
	imap <buffer>  <silent>  <LocalLeader>rmc   <C-C>:call C_MakeClean()<CR>
	map  <buffer>  <silent>  <LocalLeader>rme        :call C_ExeToRun()<CR>
	imap <buffer>  <silent>  <LocalLeader>rme   <C-C>:call C_ExeToRun()<CR>
	map  <buffer>  <silent>  <LocalLeader>rma        :call C_MakeArguments()<CR>
	imap <buffer>  <silent>  <LocalLeader>rma   <C-C>:call C_MakeArguments()<CR>
	map  <buffer>  <silent>  <LocalLeader>rp         :call C_SplintCheck()<CR>:call C_HlMessage()<CR>
	imap <buffer>  <silent>  <LocalLeader>rp    <C-C>:call C_SplintCheck()<CR>:call C_HlMessage()<CR>
	map  <buffer>  <silent>  <LocalLeader>rpa        :call C_SplintArguments()<CR>
	imap <buffer>  <silent>  <LocalLeader>rpa   <C-C>:call C_SplintArguments()<CR>
	map  <buffer>  <silent>  <LocalLeader>rcc        :call C_CppcheckCheck()<CR>:call C_HlMessage()<CR>
	imap <buffer>  <silent>  <LocalLeader>rcc   <C-C>:call C_CppcheckCheck()<CR>:call C_HlMessage()<CR>
	map  <buffer>  <silent>  <LocalLeader>rccs       :call C_CppcheckSeverityInput()<CR>
	imap <buffer>  <silent>  <LocalLeader>rccs  <C-C>:call C_CppcheckSeverityInput()<CR>

	map  <buffer>  <silent>  <LocalLeader>ri         :call C_Indent()<CR>
	imap <buffer>  <silent>  <LocalLeader>ri    <C-C>:call C_Indent()<CR>
	map  <buffer>  <silent>  <LocalLeader>rh         :call C_Hardcopy()<CR>
	imap <buffer>  <silent>  <LocalLeader>rh    <C-C>:call C_Hardcopy()<CR>
	vmap <buffer>  <silent>  <LocalLeader>rh         :call C_Hardcopy()<CR>
	map  <buffer>  <silent>  <LocalLeader>rs         :call C_Settings()<CR>
	imap <buffer>  <silent>  <LocalLeader>rs    <C-C>:call C_Settings()<CR>
	"
	if has("unix")
		map  <buffer>  <silent>  <LocalLeader>rx       :call C_XtermSize()<CR>
		imap <buffer>  <silent>  <LocalLeader>rx  <C-C>:call C_XtermSize()<CR>
	endif
	map  <buffer>  <silent>  <LocalLeader>ro         :call C_Toggle_Gvim_Xterm()<CR>
	imap <buffer>  <silent>  <LocalLeader>ro    <C-C>:call C_Toggle_Gvim_Xterm()<CR>
	"
	" Abraxas CodeCheck (R)
	"
	if s:C_CodeCheckIsExecutable==1
		map  <buffer>  <silent>  <LocalLeader>rk       :call C_CodeCheck()<CR>:call C_HlMessage()<CR>
		imap <buffer>  <silent>  <LocalLeader>rk  <C-C>:call C_CodeCheck()<CR>:call C_HlMessage()<CR>
		map  <buffer>  <silent>  <LocalLeader>rka      :call C_CodeCheckArguments()<CR>
		imap <buffer>  <silent>  <LocalLeader>rka <C-C>:call C_CodeCheckArguments()<CR>
	endif
	" ---------- plugin help -----------------------------------------------------
	"
	map  <buffer>  <silent>  <LocalLeader>hp         :call C_HelpCsupport()<CR>
	imap <buffer>  <silent>  <LocalLeader>hp    <C-C>:call C_HelpCsupport()<CR>
	map  <buffer>  <silent>  <LocalLeader>hm         :call C_Help("m")<CR>
	imap <buffer>  <silent>  <LocalLeader>hm    <C-C>:call C_Help("m")<CR>
	"
	if !exists("g:C_Ctrl_j") || ( exists("g:C_Ctrl_j") && g:C_Ctrl_j != 'off' )
		nmap  <buffer>  <silent>  <C-j>   i<C-R>=C_JumpCtrlJ()<CR>
		imap  <buffer>  <silent>  <C-j>    <C-R>=C_JumpCtrlJ()<CR>
	endif
endfunction    " ----------  end of function s:CreateAdditionalMaps  ----------
"
" Plug-in setup:  {{{1
"
"------------------------------------------------------------------------------
"  show / hide the c-support menus
"  define key mappings (gVim only)
"------------------------------------------------------------------------------
"
call C_ToolMenu()
"
if s:C_LoadMenus == 'yes' && s:C_CreateMenusDelayed == 'no'
	call C_CreateGuiMenus()
endif
"
"
command! -nargs=1 -complete=customlist,C_CppcheckSeverityList  CppcheckSeverity   call C_GetCppcheckSeverity (<f-args>)
"
"------------------------------------------------------------------------------
"  Automated header insertion
"  Local settings for the quickfix window
"
"			Vim always adds the {cmd} after existing autocommands,
"			so that the autocommands execute in the order in which
"			they were given. The order matters!
"------------------------------------------------------------------------------

if has("autocmd")
	"
	"  *.h has filetype 'cpp' by default; this can be changed to 'c' :
	"
	if s:C_TypeOfH=='c'
		autocmd BufNewFile,BufEnter  *.h  :set filetype=c
	endif
	"
	" C/C++ source code files which should not be preprocessed.
	"
	autocmd BufNewFile,BufRead  *.i  :set filetype=c
	autocmd BufNewFile,BufRead  *.ii :set filetype=cpp
	"
	" DELAYED LOADING OF THE TEMPLATE DEFINITIONS
	"
	autocmd FileType *
				\	if ( &filetype == 'cpp' || &filetype == 'c') |
				\		call C_CreateMenusDelayed() |
				\		call s:CreateAdditionalMaps() |
				\		call mmtemplates#core#CreateMaps ( 'g:C_Templates', g:C_MapLeader ) |
				\	endif

		"-------------------------------------------------------------------------------
		" style switching :Automated header insertion (suffixes from the gcc manual)
		"-------------------------------------------------------------------------------
			if !exists( 'g:C_Styles' )
				"-------------------------------------------------------------------------------
				" template styles are the default settings
				"-------------------------------------------------------------------------------
				autocmd BufNewFile  * if &filetype =~ '^\(c\|cpp\)$' && expand("%:e") !~ 'ii\?' |
							\     call C_InsertTemplateWrapper() | endif
				"
			else
				"-------------------------------------------------------------------------------
				" template styles are related to file extensions 
				"-------------------------------------------------------------------------------
				for [ pattern, stl ] in items( g:C_Styles )
					exe "autocmd BufNewFile,BufRead,BufEnter ".pattern." call mmtemplates#core#ChooseStyle ( g:C_Templates, '".stl."')"
					exe "autocmd BufNewFile                  ".pattern." call C_InsertTemplateWrapper()"
				endfor
				"
			endif
	"
	" Wrap error descriptions in the quickfix window.
	"
	autocmd BufReadPost quickfix  setlocal wrap | setlocal linebreak
	"
	exe 'autocmd BufRead *.'.join( s:C_SourceCodeExtensionsList, '\|*.' )
				\     .' call C_HighlightJumpTargets()'
	"
" 	autocmd BufNewFile,BufRead * if &filetype =~ '^\(c\|cpp\)$' |
" 							\     call s:CreateAdditionalMaps() | endif
endif " has("autocmd")
"
"=====================================================================================
" vim: tabstop=2 shiftwidth=2 foldmethod=marker
