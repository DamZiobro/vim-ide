" ========== Vim Basic Settings ============="


" Pathogen settings.
filetype off
call pathogen#runtime_append_all_bundles()
execute pathogen#infect()
filetype plugin indent on
syntax on


" ========================================================================================
" Make vim incompatbile to vi.
set nocompatible
set modelines=0

" ========================================================================================
"TAB settings.
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set showtabline=2
set ruler

" ========================================================================================
" More Common Settings.
set encoding=utf-8
set scrolloff=3
""set autoindent
set showmode
set showcmd
set hidden
set wildmenu
set wildmode=list:longest
set visualbell

set history=1000
set undolevels=10000

set nobackup
set noswapfile

set cursorline
set ttyfast
set ruler
set backspace=indent,eol,start

set pastetoggle=<F2>
"set relativenumber
set number
set norelativenumber

set undofile
set undodir=/tmp

set shell=/bin/bash
set lazyredraw
set matchtime=3

" ========================================================================================
"Changing Leader Key
let mapleader = ","

" ========================================================================================
" Map : to ; also in command mode.
nnoremap ; :
vmap ; :
nmap <silent> <leader>/ :nohlsearch<CR>
" ========================================================================================

" Set title to window
set title

" Dictionary path, from which the words are being looked up.
" ========================================================================================
set dictionary=/usr/share/dict/words

" ========================================================================================
" Make Vim able to edit corntab fiels again.
set backupskip=/tmp/*,/private/tmp/*"

" ========================================================================================
" Enable Mouse
set mouse=a

" ========================================================================================
"Settings for Searching and Moving
nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set incsearch
set showmatch
set hlsearch
nnoremap <leader><space> :noh<cr>
"nnoremap <tab> %
"vnoremap <tab> %

" ========================================================================================
" go to next/previous tag
nnoremap <leader>f :tnext<cr>
nnoremap <leader>d :tprev<cr>
nnoremap <leader>tj :tjump<cr>

" ========================================================================================
" Make Vim to handle long lines nicely.
set wrap
set textwidth=79
set colorcolumn=+1
set formatoptions=qrn1
"set colorcolumn=79

" ========================================================================================
" To  show special characters in Vim
"set list
set listchars=tab:▸\ ,eol:¬

" ========================================================================================
" set unnamed clipboard
set clipboard=unnamedplus


"==========================================================================="
" Different search patterns 
let g:cpp_pattern = "*.{cpp,c,h,hpp}"
let g:java_pattern = "*.{java}"
let g:makefile_pattern = "Makefile*"
let g:text_pattern = "*.{txt,text}"
let g:python_pattern = "*.{py}"
let g:cpp_java_pattern = "*.{cpp,c,h.hpp,java,cc,hh}"

"==========================================================================="
" C\C++ projects settings
"==========================================================================="
"Global project settings 
let g:project_root = "."

let g:search_root = g:project_root
let g:search_pattern = "*.*"
"==========================================================================="
" Get Rid of stupid Goddamned help keys
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

"==========================================================================="
" Set vim to save the file on focus out.
au FocusLost * :wa
"==========================================================================="
" Redraw screen every time when focus gained
au FocusGained * :redraw!
"==========================================================================="
" Adding More Shorcuts keys using leader kye.
" Leader Kye provide separate namespace for specific commands.
",W Command to remove white space from a file.
nnoremap <leader>W :%s/\s\+$//<cr>:let @/=''<CR>

" ,ft Fold tag, helpful for HTML editing.
nnoremap <leader>ft vatzf

" ,q Re-hardwrap Paragraph
nnoremap <leader>q gqip

" ,ev Shortcut to edit .vimrc file on the fly on a vertical window.
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>


"==========================================================================="
" Working with split screen nicely
" Resize Split When the window is resized"
au VimResized * :wincmd =

"==========================================================================="
" Wildmenu completion "
set wildmenu
set wildmode=list:longest
set wildignore+=.hg,.git,.svn " Version Controls"
set wildignore+=*.aux,*.out,*.toc "Latex Indermediate files"
set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg "Binary Imgs"
set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest "Compiled Object files"
set wildignore+=*.spl "Compiled speolling world list"
set wildignore+=*.sw? "Vim swap files"
set wildignore+=*.DS_Store "OSX SHIT"
set wildignore+=*.luac "Lua byte code"
set wildignore+=migrations "Django migrations"
set wildignore+=*.pyc "Python Object codes"
set wildignore+=*.orig,*.rej "Merge resolution files"

"==========================================================================="
" Make Sure that Vim returns to the same line when we reopen a file"
augroup line_return
    au!
    au BufReadPost *
                \ if line("'\"") > 0 && line("'\"") <= line("$") |
                \ execute 'normal! g`"zvzz' |
                \ endif
augroup END

"==========================================================================="
" go to place of last change
nnoremap g; g;zz

" =========== END Basic Vim Settings ===========


" =========== Gvim Settings =============

" Removing scrollbars
if has("gui_running")
    set guitablabel=%-0.12t%M
    set guioptions-=T
    set guioptions-=r
    set guioptions-=L
    set guioptions+=a
    set guioptions-=m
    colo badwolf
    set listchars=tab:▸\ ,eol:¬         " Invisibles using the Textmate style
else
    set t_Co=256
    colorschem badwolf
endif

" ========== END Gvim Settings ==========


" ========== Plugin Settings =========="


" ENABLE CTRL INTERPRETING FOR VIM
silent !stty -ixon > /dev/null 2>/dev/null

"==========================================================================="
" Mapping to NERDTree
noremap <leader>m :NERDTreeToggle<cr>
let NERDTreeIgnore=['\.vim$', '\~$', '\.pyc$']

" ================ ReplaceText function ============================

function! MySearchText()
    let text = input("Text to find: ")
    :call MySearchSelectedText(text)
endfunction

function! MySearchSelectedText(text)
    :execute "vimgrep /" . a:text . "/jg ".g:search_root."/**/".g:search_pattern
endfunction

map <F3> :call MySearchText() <Bar> botright cw<cr>
map <F3><F3> :execute "call MySearchSelectedText (\"".expand("<cword>") . "\")" <Bar> botright cw<cr>

"==========================================================================="
"Make window mosaic 
nmap <leader>mon :split<cr>:vsplit<cr><C-Down>:vsplit<cr><C-Up><leader>l
imap <leader>mon <ESC>:split<cr>:vsplit<cr><C-Down>:vsplit<cr><C-Up><leader>li

"==========================================================================="
" Make check spelling on or off 
nmap <leader>cson   :set spell<CR>
nmap <leader>csoff  :set nospell<CR>


"==========================================================================="
" Indentation (got to opening bracket and indent section) 

nmap <leader>ip [{=%

"==========================================================================="
"Highlight section between brackets (do to opening bracket and highlight)
nmap <leader>hp [{%v%<Home>
"
"==========================================================================="
" Map copy delete and paste to system clipboard
"
vmap <Leader>y "+y
vmap <Leader>d "+d

nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

"==========================================================================="
" Double learder for selection whole line
nmap <Leader>v V

"==========================================================================="
function! FindProjectRoot(lookFor)
    let pathMaker='%:p'
    while(len(expand(pathMaker))>len(expand(pathMaker.':h')))
        let pathMaker=pathMaker.':h'
        let fileToCheck=expand(pathMaker).'/'.a:lookFor
        if filereadable(fileToCheck)||isdirectory(fileToCheck)
            return expand(pathMaker)
        endif
    endwhile
    return 0
endfunction

"==========================================================================="
function! BuildAndInstallCppApp()
    let project_root = FindProjectRoot("main.cpp")
    if project_root == 0
        let project_root = "."
    endif
    execute "!cd ".project_root."/build; sudo make install;"
endfunction

"==========================================================================="
function! BuildAndInstallCSharpApp()
    execute "!xbuild;"
endfunction

"==========================================================================="
function! BuildAndInstallQtApp()
    execute "!make;"
endfunction

function! OpenQuickFixInRightLocation() 
    execute ":TagbarClose"
    execute ":copen"
    execute ":TagbarOpen"
    " TODO - improve me
    " go to window one above the quickfix window
    execute ":normal \<C-j>\<C-l>100\<C-j>\<C-k>"
endfunction

"==========================================================================="
" Improve detecting filetype (ex. for files starting with /bin/echo syntax
" should be as for sh files)
function! DetectFileType() 
    "if did_filetype() 
      "finish
    "endif 
    if getline(1) =~ '^#!.*/bin/echo.*'
      setfiletype sh
    endif
endfunction

"==========================================================================="
" Quickfix navigation 
nmap <leader>co :call OpenQuickFixInRightLocation()<cr>
nmap <leader>cq :cclose<cr>
nmap <leader>cw :q<cr>:cclose<cr>
nmap <leader>n :cnext<cr>
nmap <leader>p :cprevious<cr>

"==========================================================================="
" CMake 
nmap <F8> <C-s> :call BuildAndInstallCppApp()<cr>
imap <F8> <ESC> <C-s> :call BuildAndInstallCppApp()<cr>

"==========================================================================="
" Make 
nmap <C-F8> <C-s> :call BuildAndInstallQtApp()<cr>
imap <C-F8> <ESC> <C-s> :call BuildAndInstallQtApp()<cr>

"==========================================================================="
" CSharp make 
nmap <C-F5> <C-s> :call BuildAndInstallCSharpApp()<cr>
imap <C-F5> <ESC> <C-s> :call BuildAndInstallCSharpApp()<cr>

"==========================================================================="
" Normal make 
nmap <F9>> :set makeprg=make\ -C\ .<cr> :make --no-print-directory <cr> :TagbarClose<cr> :cw <cr> :TagbarOpen <cr>
imap <F9> <ESC> set makeprg=make\ -C\ ./build<cr> :make --no-print-directory <cr> :TagbarClose<cr> :cw <cr> :TagbarOpen <cr>i


"==========================================================================="
"Tagbar key bindings
nmap <leader>l <ESC>:TagbarToggle<cr>

"==========================================================================="
" Mini Buffer some settigns."
let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1

"==========================================================================="
" Force Saving Files that Require Root Permission
"
command! Sudowrite w !sudo tee % > /dev/null

"==========================================================================="
" TAB and Shift-TAB in normal mode cycle buffers
"
nmap <Tab> :bn<CR>
nmap <S-Tab> :bp<CR> 


"==========================================================================="
" highlight current line
set cursorline

"==========================================================================="
" Configure autocomplete tool
let g:acp_EnableAtStartup = 1

"==========================================================================="
set laststatus=2
set statusline=%F%m%r%h%w[%L][%{&ff}]%y[%p%%][%04l,%04v]

set nowrap
set expandtab

"==========================================================================="
" Edit .vimrc file
nmap <silent> <leader>ov :e $MYVIMRC<CR>
nmap <silent> <leader>sv :w<CR> :so $MYVIMRC<CR>

"==========================================================================="
" Manpage for word under cursor via 'K' in command moderuntime
runtime ftplugin/man.vim
noremap <buffer> <silent> K :exe "Man" expand('<cword>') <CR>

"==========================================================================="
" Map SyntasticCheck to F4 
"
noremap <silent> <F4> :SyntasticCheck<CR>
noremap! <silent> <F4> <ESC>:SyntasticCheck<CR>

"==========================================================================="
au BufNewFile,BufRead *.c,*.cc,*.cpp,*.h call SetupCandCPPenviron()
function! SetupCandCPPenviron()
    "
    " Search path for 'gf' command (e.g. open #include-d files)
    "
    set path+=/usr/include/c++/**

    "
    " Especially for C and C++, use section 3 of the manpages
    "
    noremap <buffer> <silent> K :exe "Man" 3 expand('<cword>') <CR>
endfunction


"==========================================================================="
" CCTree configuration
let g:CCTreeRecursiveDepth = 1
let g:CCTreeMinVisibleDepth = 1
let g:CCTreeOrientation = "rightbelow"

function! LoadCCTree()
    let databaseDir = $HOME."/.vim/cscope_databases"
    if IsFileAlreadyExists ( databaseDir."/last_project_cscope")
        execute "silent :CCTreeLoadDB ".databaseDir."/last_project_cscope"
    endif
    let userDef = substitute(system("echo $USER"), "\n", '', '')
    if userDef == "docker" && IsFileAlreadyExists( databaseDir."/dtv_project_cscope")
        execute "silent :CCTreeAppendDB ".databaseDir."/dtv_project"
    endif
endfunction


" CCTree shortucts"
nmap <leader>ct :silent call LoadCCTree()<cr>
noremap <buffer> <silent> <leader>cr :execute "CCTreeTraceReverse ".expand('<cword>')<cr>
noremap <buffer> <silent> <leader>cf :execute "CCTreeTraceForward ".expand('<cword>')<cr>

let g:CCTreeKeyHilightTree = '<C-l>'        " Static highlighting
let g:CCTreeKeySaveWindow = '<C-\>y' 
let g:CCTreeKeyToggleWindow = '<C-\>w' 
let g:CCTreeKeyCompressTree = 'zs'     " Compress call-tree 
let g:CCTreeKeyDepthPlus = '<C-\>=' 
let g:CCTreeKeyDepthMinus = '<C-\>-'

"==========================================================================="
function! LoadCScopeDatabases()
    let databaseDir = $HOME."/.vim/cscope_databases"
    if IsFileAlreadyExists ( databaseDir."/last_project_cscope")
        execute ":silent cs add ".databaseDir."/last_project_cscope"  
    endif
    if IsFileAlreadyExists ( databaseDir."/gstreamer_cscope")
        execute ":silent cs add ".databaseDir."/gstreamer_cscope"  
    endif
    if IsFileAlreadyExists ( databaseDir."/mythtv_cscope")
        execute ":silent cs add ".databaseDir."/mythtv_cscope"  
    endif
    if IsFileAlreadyExists ( databaseDir."/cpp_scope")
        execute ":silent cs add ".databaseDir."/cpp_scope"
    endif
    "load dtv_project only when we are working on docker 
    let userDef = substitute(system("echo $USER"), "\n", '', '')
    if userDef == "docker" && IsFileAlreadyExists( databaseDir."/dtv_project_cscope")
        execute ":silent cs add ".databaseDir."/dtv_project_cscope"  
    endif
    echohl StatusLine | echo "CScope databases loaded successfully..." | echohl None 
endfunction


function! UpdateCscopeDatabase(basedir)
    let databaseDir = $HOME."/.vim/cscope_databases"
    let findCommand = "find `pwd` -name '*.c' -o -name '*.h' -o -name '*.java' -o -name '*.py' -o -name '*.js' -o -name '*.hpp' -o -name '*.hh' -o -name '*.cpp' -o -name '*.cc' > cscope.files"

    execute ":silent !cd ".a:basedir." && ".findCommand." && cscope -b && cp cscope.out ".databaseDir."/last_project_cscope && rm cscope.files cscope.out"
    execute ":silent cs reset"

    call UpdateTags(a:basedir)
    execute ":redraw!"

endfunction

function! UpdateAllCscopeDatabases()
    let databaseDir = $HOME."/.vim/cscope_databases"
    let tagsDir = $HOME."/.vim/tags"

    call UpdateCscopeDatabase("/usr/src/gstreamerInstall")
    execute ":silent !cp ".databaseDir."/last_project_cscope ".databaseDir."/gstreamer_cscope"
    execute ":silent !cp ".tagsDir."/last_project_tags ".tagsDir."/gstreamer_tags"

    call UpdateCscopeDatabase($HOME."/projects/xmementoit/digitalTVOpenSource/mythtv")
    execute ":silent !cp ".databaseDir."/last_project_cscope ".databaseDir."/mythtv_cscope"
    execute ":silent !cp ".tagsDir."/last_project_tags ".tagsDir."/mythtv_tags"

    call UpdateCscopeDatabase($HOME."/.vim/tags/cpp_src")
    execute ":silent !cp ".databaseDir."/last_project_cscope ".databaseDir."/cpp_scope"
    execute ":silent !cp ".tagsDir."/last_project_tags ".tagsDir."/cpp_tags"

    call UpdateCscopeDatabase("/usr/local/include")
    execute ":silent !cp ".databaseDir."/last_project_cscope ".databaseDir."/usr_local_include_cscope"
    execute ":silent !cp ".tagsDir."/last_project_tags ".tagsDir."/usr_local_include_tags"

    call UpdateCscopeDatabase(".")
    execute ":redraw!"
endfunction

function! UpdateTags(basedir)
    execute ":silent !cd ".a:basedir." && ctags -R --sort=yes --fields=+iaSnkt --extra=+q+f --exclude=build -f ~/.vim/tags/last_project_tags `pwd`"
    execute ":redraw!"
endfunction

function! IsFileAlreadyExists(filename)
   if filereadable(a:filename)
        return 1
    else 
        return 0
    endif
endfunction

"==========================================================================="
"Invoke this function if we are opening main.cpp or main.c file"
function! CheckIfMain()
    if !IsFileAlreadyExists(expand("%:t")) && expand("%:t:r") == "main" && expand("%:e") == "cpp"
        execute 'normal! 1G 1000dd'
        execute ':Template maincpp'
        execute ':w'
    elseif !IsFileAlreadyExists(expand("%:t")) && expand("%:t:r") == "main" && expand("%:e") == "c"
        execute 'normal! 1G 1000dd' 
        execute ':Template mainc'
        execute ':w'
    endif
endfunction

"==========================================================================="
"Invoke this function when you would like to create new C++ class files (.cpp
"and .h file)"
function! CreateCppClassFiles(className)
    "create cpp file
    if !IsFileAlreadyExists(a:className.'.cpp')
        execute ':n '.a:className.'.cpp'
        execute 'normal! 1G 1000dd'
        execute ':Template cppclass'
        execute ':w'
    else
        execute ':n '.a:className.'.cpp'
    endif 
    "create h file
    if !IsFileAlreadyExists(a:className.'.h')
        execute ':n '.a:className.'.h'
        execute 'normal! 1G 1000dd'
        execute ':Template cppclassh'
        execute ':w'
    else
        execute ':n '.a:className.'.h'
    endif
endfunction

"create new command for creating cpp class"
command! -nargs=1 NewCppClass call CreateCppClassFiles("<args>")

"==========================================================================="
" setting ctags 
set tags+=~/.vim/tags/last_project_tags
set tags+=~/.vim/tags/dtv_project_tags
set tags+=~/.vim/tags/gstreamer_tags
set tags+=~/.vim/tags/mythtv_tags
set tags+=~/.vim/tags/cpp_tags
set tags+=~/.vim/tags/usr_local_include_tags

"==========================================================================="
nmap <leader>ud :silent call UpdateCscopeDatabase(".")<cr>:w<cr>
imap <leader>ud <ESC>l:silent call UpdateCscopeDatabase(".")<cr>:w<cr>i

nmap <leader>uad :call UpdateAllCscopeDatabases()<cr>:w<cr>
imap <leader>uad <ESC>l:call UpdateAllCscopeDatabases()<cr>:w<cr>i

"==========================================================================="
set autochdir
let NERDTreeChDirMode=2

" =========== END Plugin Settings =========="
"
"

"==========================================================================="
" Save and load session
"
map <leader>ss :SessionSaveAs user_auto_saved_session<cr>:NERDTree .<cr>
map <leader>so :SessionOpen user_auto_saved_session<cr><C-d><C-d>,n:NERDTree .<cr>

"==========================================================================="
""Open default session (session saved during closing vim)
map <leader>sd :SessionOpen vim_auto_saved_session<cr>:NERDTree .<cr> 

" =========== Startup commands =========="

autocmd VimEnter * SignatureToggleSigns
if &diff 
    "autocmd VimEnter * NERDTree .
else 
    autocmd VimEnter * NERDTree .
    autocmd VimEnter * TagbarOpen
    autocmd VimEnter * helptags ~/.vim/doc
    autocmd VimEnter * exe 2 . "wincmd w"
    autocmd VimEnter * call CheckIfMain()
    autocmd VimEnter * call LoadCScopeDatabases()
    autocmd VimEnter * call DetectFileType()

    autocmd BufWritePost ~/.vimrc source ~/.vimrc
    "au BufNewFile,BufRead * :set relativenumber " relative line numbers

endif

" =========== Leaving commands =========="

autocmd VimLeave * SessionSaveAs vim_auto_saved_session


"============ Configuration Omni Completion =============================="

filetype plugin on
autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType cpp set omnifunc=omni#cpp#complete#Main

if v:version >= 600
    filetype plugin on
    filetype indent on
else
    filetype on
endif

if v:version >= 700
    set omnifunc=syntaxcomplete#Complete " override built-in C omnicomplete with C++ OmniCppComplete plugin
    "let g:SuperTabDefaultCompletionType = "<C-@>" 
    let OmniCpp_NamespaceSearch     = 1
    let OmniCpp_GlobalScopeSearch   = 1
    let OmniCpp_DisplayMode         = 1
    let OmniCpp_ShowScopeInAbbr     = 0 "do not show namespace in pop-up
    let OmniCpp_ShowPrototypeInAbbr = 1 "show prototype in pop-up
    let OmniCpp_ShowAccess          = 1 "show access in pop-up
    let OmniCpp_SelectFirstItem     = 2 "select first item in pop-up
    let OmniCpp_MayCompleteDot      = 1
    let OmniCpp_MayCompleteArrow    = 1
    let OmniCpp_MayCompleteScope    = 1
    let OmniCpp_DefaultNamespaces   = ['std','_GLIBCXX_STD']

    set completeopt=menuone,menu,longest,preview
endif

"===================================================================================================
" Commenting blocks of code.
autocmd FileType c,cppva,scala let b:comment_leader = '// '
autocmd FileType sh,ruby,python   let b:comment_leader = '# '
autocmd FileType conf,fstab       let b:comment_leader = '# '
autocmd FileType tex              let b:comment_leader = '% '
autocmd FileType mail             let b:comment_leader = '> '
autocmd FileType vim              let b:comment_leader = '" '
noremap <silent> <leader>cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:nohlsearch<CR>
noremap <silent> <leader>cu :<C-B>silent <C-E>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:nohlsearch<CR>'"'"


" ========================================================================================
" SURRENDINGS 

autocmd FileType c,cpp let b:surround_105  = "if (condition) {\n \r } \n"
autocmd FileType c,cpp let b:surround_102  = "for (int i=0; i<condition;i++) {\n\r}\n"
autocmd FileType c,cpp let b:surround_119  = "while (condition) {\n\r}\n"
autocmd FileType c,cpp let b:surround_112  = "printf(\"\r\\n\");"
autocmd FileType c,cpp let b:surround_99   = "/*\n\r*/"

autocmd FileType html  let b:surround_102  = "<font face=\"courier\">/r</font>"

" ========================================================================================
"Enable snippets for cpputest 
autocmd FileType cpp :set filetype=cpp.cpputest
autocmd FileType c   :set filetype=c.cpputest

" ========================================================================================
" REFRESH COMMANDS

" warning: to refresh NERDTree just type 'r' being in NERD window

nmap <F5> :e<cr>
imap <F5> <ESC>l:e<cr>i

" ========================================================================================
" " USING MARKERS
" Create marker: m<markerSign> ex. ma 
" Goto marker:   '<markerSign> ex. 'a 
"
" ========================================================================================
" " INSERT C++ GETTER NAD SETTER
"map <Leader>igs :InsertBothGetterSetter<CR>

" ========================================================================================
" " USING VIM AS HEX EDITOR
map <Leader>hon :%!xxd<CR>
map <Leader>hof :%!xxd -r<CR>

" ========================================================================================
" " USING TASKLIST
" TODO
map <leader>td <Plug>TaskList

" ========================================================================================
" " USING GUNDO (revision of history saving)

map <leader>gu :GundoToggle<CR>
let g:gundo_width = 60
let g:gundo_preview_height = 40
let g:gundo_right = 1

" ========================================================================================
" " Resize split window horizontally and vertically
" Shortcuts to Shift-Alt-Up - Alt is mapped as M in vim
nmap <S-M-Up> :2winc+<cr>
imap <S-M-Up> <Esc>:2winc+<cr>i
nmap <S-M-Down> :2winc-<cr>
imap <S-M-Down> <Esc>:2winc-<cr>i

nmap <S-M-Left> :2winc><cr>
imap <S-M-Left> <Esc>:2winc><cr>i
nmap <S-M-Right> :2winc<<cr>
imap <S-M-Right> <Esc>:2winc<<cr>i

" ========================================================================================
" " ProtoDef plugin 
" ========================================================================================
" Allows pulling C++ function prototypes into implementation files 
" https://github.com/derekwyatt/vim-protodef 
"
let g:protodefprotogetter="$HOME/.vim/bundle/vim-protodef/pullproto.pl" 


" ========================================================================================
" " localvimrc plugin 
" This plugin searches for local vimrc files in the file system tree of the
" currently opened file.
" https://github.com/embear/vim-localvimrc
" ========================================================================================
" 
let g:localvimrc_persistent=2 


" ========================================================================================
" " gototagwithlinenumber 
" This plugin allows going to file and line_number stored in tag (using ctags)
" It is useful ex. when we are working with project and have logs for project. 
" Then we can easly switch between logs and real source code using tags + functions
" ========================================================================================
" 
nmap <leader>gt :GotoFileWithLineNumTag <cr>

" ========================================================================================
" shortcuts for switch plugin
" ========================================================================================
" 
nmap <leader>- :Switch <cr>
nmap <leader>= :call switch#Switch(g:variable_style_switch_definitions) <cr>


" ========================================================================================
" " Set up folding configuration 
"
nnoremap <leader>fo :setlocal foldexpr=(getline(v:lnum)=~@/)?0:1 foldmethod=expr fml=0 foldlevelstart=0 foldcolumn=1<CR> 

" ========================================================================================
" " Set up scrolling winding one line up and down  
nnoremap <S-Up> <C-E>
nnoremap <S-Down> <C-Y> 

" ========================================================================================
" " Automatically go to the end of pasted text 
vnoremap <silent> y y`]
vnoremap <silent> p p`]
nnoremap <silent> p p`]
 
" ========================================================================================
" " Quickly select text which I just pasted  
noremap gV `[v`]

" ========================================================================================
" VIM-expand-region  plugin 
" https://github.com/terryma/vim-expand-region   
" 
vmap v <Plug>(expand_region_expand)
vmap r <Plug>(expand_region_shrink) 

" ========================================================================================
" VIM-airline  plugin 
" https://github.com/bling/vim-airline   
let g:airline#extensions#tabline#enabled = 1 
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|' 

function! AirlineInit()
  let g:airline_section_a = airline#section#create(['mode'])
  let g:airline_section_c = airline#section#create(['%F'])
endfunction
autocmd VimEnter * call AirlineInit() 

  let g:airline_theme_patch_func = 'AirlineThemePatch'
  function! AirlineThemePatch(palette)
    if g:airline_theme == 'badwolf'
      for colors in values(a:palette.inactive)
        let colors[3] = 245
      endfor
    endif
  endfunction

" ========================================================================================
" VIM-easy-align  plugin 
"
vmap <Enter> <Plug>(EasyAlign)
" Start interacptive EasyAlign for a motion/text object (e.g. <Leader>aip)
"nmap <Leader>b <Plug>(EasyAlign)

" ========================================================================================
" VIM-signature plugin 
" https://github.com/kshenoy/vim-signature 
nnoremap <leader>sm :SignatureToggleSigns<cr>

" ========================================================================================
" map ctrl+j to ctrl+m (for INSERT mode)in order to be more consistent with bash terminal 
let g:BASH_Ctrl_j='off'
inoremap <C-j> <C-m>
noremap  <C-j> <C-m>

" ========================================================================================
" automatically detect messages.log files and highlight them
au BufNewfile,BufRead messages* set filetype=dtv_logs_highlights
au BufNewfile,BufRead logsense*[^py] set filetype=dtv_logs_highlights
au BufNewfile,BufRead syslog* set filetype=gstreamer_highlight_syntax

" ========================================================================================
" remap f{char} repetition keys shortcuts
noremap _ ,
noremap - ;

" ========================================================================================
" enable matchit plugin which extends usage of % operator to match 
" more words ex. if/end def/end html tags etc.
runtime macros/matchit.vim

" ========================================================================================
" set F2 as shortcut for toggle INSERT (paste) mode    
nnoremap <F2> :set invpaste paste?<CR>

" ========================================================================================
" map last substitute execution to normal mode & operator
nnoremap & :&&<CR>
xnoremap & :&&<CR>

" ========================================================================================
" quick-scope plugin settings
" Trigger a highlight in the appropriate direction when pressing these keys:
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" Trigger a highlight only when pressing f and F.
let g:qs_highlight_on_keys = ['f', 'F']

let g:qs_first_occurrence_highlight_color = 155       " terminal vim

let g:qs_second_occurrence_highlight_color = 81         " terminal vim

" =======================================================================================
" yankring
" 2nd and 3rd <cr> is needed only if you use DidYouMean plugin ()
noremap <leader>yr :YRShow <cr><cr><cr>
let g:yankring_replace_n_pkey = '<leader>yp'

" ========================================================================================
" vimdiff options
" Always use vertical diffs 
set diffopt+=vertical
if &diff 
    colorscheme badwolf_diff
endif

" ========================================================================================
" ack and silversearcher-ag 
if executable('ag')
  let g:ackprg = 'ag --nogroup --nocolor --column'
endif

nmap  <leader>ag :exe "Ack " expand('<cword>') <CR>

" ========================================================================================
" CtrlSF shortcuts
nmap     <C-F>f :exe "CtrlSF" expand('<cword>') <CR>
vmap     <C-F>F <Plug>CtrlSFVwordExec <CR>
nmap     <C-F>n <Plug>CtrlSFCwordPath <CR>
nmap     <C-F>p <Plug>CtrlSFPwordPath <CR>
nnoremap <C-F>o :CtrlSFOpen<CR>
nnoremap <C-F>t :CtrlSFToggle<CR>
inoremap <C-F>t <Esc>:CtrlSFToggle<CR>

" ========================================================================================
" remap movement for wrapped lines being the same as for non-wrapped lines
nnoremap k gk
nnoremap gk k
nnoremap j gj
nnoremap gj j

" ========================================================================================
" set middle of screen for new searches
nnoremap <silent>n nzz
nnoremap <silent>N Nzz
nnoremap <silent>* *zz
nnoremap <silent># #zz
nnoremap <silent>g* g*zz

" ========================================================================================
" toggle normal line numbers and relative line numbers
function! NumberToggle()
  if(&relativenumber == 1)
    set norelativenumber
  else
    set relativenumber
  endif
endfunc
nnoremap <leader>tn :call NumberToggle()<cr>
" ========================================================================================
iabbr /** /************************************************************************
iabbr **/ ************************************************************************/
iabbr //- //-----------------------------------------------------------------------

" ========================================================================================
" replaces selected text with test from buffer
vnoremap p <Esc>:let current_reg = @"<CR>gvs<C-R>=current_reg<CR><Esc>

" ========================================================================================
" search but say in the current search occurance
nmap * *N
" " ========================================================================================
" " Easy motion configuration 
" "
" " <Leader>f{char} to move to {char}
" map  <Leader><Leader>f <Plug>(easymotion-bd-f)
" nmap <Leader><Leader>f <Plug>(easymotion-overwin-f)
" 
" " s{char}{char} to move to {char}{char}
nmap s <Plug>(easymotion-overwin-f2)
" 
" " Move to line
" map <Leader><Leader>l <Plug>(easymotion-bd-jk)
" nmap <Leader><Leader>l <Plug>(easymotion-overwin-line)
" 
" " Move to word
" " map  <Leader><Leader>w <Plug>(easymotion-bd-w)
" " nmap <Leader><Leader>w <Plug>(easymotion-overwin-w)
"
map  <leader>/ <Plug>(easymotion-sn)
omap <leader>/ <Plug>(easymotion-tn)
" " ========================================================================================
" vimwiki configuration
let g:vimwiki_list = [{'path': '/var/www/html/vimsite', 'path_html': '/var/www/html/vimhtml'}]
"<leader>ww - iopen wiki in current tab
"<leader>wt - iopen wiki in new tab

" " ========================================================================================
" vimwiki configuration
"<leader>rr - browse using ranger in current tab
"<leader>rt - browser using ranger in new tab
"<leader>rv - browser using ranger in tab splitted vertically
"<leader>rs - browser using ranger in tab splitted horizontally

" " ========================================================================================
" run command conriguration
let g:vim_run_command_map = {
  \'javascript': 'node',
  \'php': 'php',
  \'python': 'python',
  \'bash': 'bash',
  \}
":Run yourcommand - runs selected command 
" '<,'>RunVisual - run commands from selected lines 
""AutoRun - autorun commands from file on each save
" " ========================================================================================
" ctrlp configuration
let g:ctrlp_map = '<C-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
" " ========================================================================================
" ctrlp configuration
nmap <leader><leader>l :CtrlPLocate<cr>
" " ========================================================================================
" visualmarks configuration
vmap <unique> m <Plug>VisualMarksVisualMark
nmap <leader>< <Plug>VisualMarksGetVisualMark


" " ========================================================================================
" set mutt-based variables 
"setlocal fo+=aw

" " ========================================================================================
" Make 0 go to the first character rather than the beginning
" of the line. When we're programming, we're almost always
" interested in working with text rather than empty space. If
" you want the traditional beginning of line, use ^
nnoremap 0 ^
nnoremap ^ 0

" " ========================================================================================
" ," Surround a word with "quotes"
map <leader>" ysiw"
vmap <leader>" c"<C-R>""<ESC>

" <leader>' Surround a word with 'single quotes'
map <leader>' ysiw'
vmap <leader>' c'<C-R>"'<ESC>
" <leader>) or ,( Surround a word with (parens)
" The difference is in whether a space is put in
map <leader>( ysiw(
map <leader>) ysiw)
vmap <leader>( c( <C-R>" )<ESC>
vmap <leader>) c(<C-R>")<ESC>

" <leader>[ Surround a word with [brackets]
map <leader>] ysiw]
map <leader>[ ysiw[
vmap <leader>[ c[ <C-R>" ]<ESC>
vmap <leader>] c[<C-R>"]<ESC>

" <leader>{ Surround a word with {braces}
map <leader>} ysiw}
map <leader>{ ysiw{
vmap <leader>} c{ <C-R>" }<ESC>
vmap <leader>{ c{<C-R>"}<ESC>

map <leader>` ysiw`

" " ========================================================================================
"Clear current search highlight by double tapping //
nmap <silent> // :nohlsearch<CR>
" " ========================================================================================
" Change inside various enclosures with Alt-" and Alt-'
" The f makes it find the enclosure so you don't have
" to be standing inside it
nnoremap <leader><leader>' f'ci'
nnoremap <leader><leader>" f"ci"
nnoremap <leader><leader>( f(ci(
nnoremap <leader><leader>) f)ci)
nnoremap <leader><leader>[ f[ci[
nnoremap <leader><leader>] f]ci]
" " ========================================================================================
" assign q; to avoid shift pressing when searching last ex commands
nmap q; q:
vmap q; q:
" " ========================================================================================
" use ag as default grep tool if it is installed on the machine
if executable("ag")
  set grepprg=ag\ --nogroup\ --nocolor\ --ignore-case\ --column
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

map <leader>gr :grep <C-R><C-w><CR><CR><CR>
vmap <leader>gr :grep <C-R><C-w><CR><CR><CR>

" " ========================================================================================
" make vim working as tailf
function! Tailf()
    e
    normal G
    redraw

    sleep 1
    call Tailf()
endfunction

" ======================================================================================== 
" function allows going to selected jump from :jumps list
function! GotoJump()
  jumps
  let j = input("Please select your jump: ")
  if j != ''
    let pattern = '\v\c^\+'
    if j =~ pattern
      let j = substitute(j, pattern, '', 'g')
      execute "normal " . j . "\<c-i>"
    else
      execute "normal " . j . "\<c-o>"
    endif
  endif
endfunction

nmap <leader>j :call GotoJump()<cr>

" ======================================================================================== 
" add fzf plugin to runtimepath
""
set rtp+=~/.fzf

nmap <C-]> g<C-]>

" ======================================================================================== 
" rainbow levels toggle
nmap <leader>rlt :RainbowLevelsToggle<cr>
