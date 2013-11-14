"
" Template system for Vim
"
" Copyright (C) 2012 Adrian Perez de Castro <aperez@igalia.com>
" Copyright (C) 2005 Adrian Perez de Castro <the.lightman@gmail.com>
"
" Distributed under terms of the MIT license.
"

if exists("g:templates_plugin_loaded")
	finish
endif
let g:templates_plugin_loaded = 1


" Put template system autocommands in their own group. {{{1
if !exists('g:templates_no_autocmd')
	let g:templates_no_autocmd = 0
endif

if !g:templates_no_autocmd
	augroup Templating
		autocmd!
		autocmd BufNewFile * call <SID>TLoad()
	augroup END
endif

" normalize the path
" replace the windows path sep \ with /
function <SID>NormalizePath(path)
	return substitute(a:path, "\\", "/", "g")
endfunction

" Template searching. {{{1
" Returns a string containing the path of the parent directory of the given
" path. Works like dirname(3). It also simplifies the given path.
function <SID>DirName(path)
	let l:tmp = <SID>NormalizePath(a:path)
	return substitute(l:tmp, "[^/][^/]*/*$", "", "")
endfunction

" Default templates directory
let s:default_template_dir = <SID>DirName(<SID>DirName(expand("<sfile>"))) . "templates"
  
" Find the target template in windows
"
" In windows while we clone the symbol link from github
" it will turn to normal file, so we use this function
" to figure out the destination file
function <SID>TFindLink(path, template)
	if !filereadable(a:path . a:template)
		return a:template
	endif

	let l:content = readfile(a:path . a:template, "b")
	if len(l:content) != 1
		return a:template
	endif

	if filereadable(a:path . l:content[0])
		return <SID>TFindLink(a:path, l:content[0])
	else
		return a:template
	endif
endfunction

" Searches for a [template] in a given [path].
"
" If [upwards] is [1] the template is searched only in the given directory;
" if it's zero it is searched all along the directory structure, going to
" parent directory whenever a template is *not* found for a given [path]. If
" it's greater than zero [upwards] is the maximum depth of directories that
" will be traversed.
"
" If no template is found an empty string is returned.
"
function <SID>TSearch(path, template, upwards)
	if filereadable(a:path . a:template)
		" Suitable template found.
		if !has("win32")
			return a:path . a:template
		else
			return a:path . <SID>TFindLink(a:path, a:template)
		endif
	else
		" File not found/not readable.
		if (a:upwards == 0) || (a:upwards > 1)
			" Check wether going upwards results in a different path...
			let l:pathUp = <SID>DirName(a:path)
			if l:pathUp != a:path
				" ...and traverse it.
				return <SID>TSearch(l:pathUp, a:template, a:upwards ? a:upwards-1 : 0)
			endif
		endif
	endif
	" Ooops, either we cannot go up in the path or [upwards] reached 1
	return ""
endfunction


" Tries to find a template by its name, searching using:
"   1. The [path] passed to the function, [upwards] times up.
"   2. The g:template_dir directory, if it exists.
"   3. Built-in templates from s:default_template_dir.
" Returns an empty string if no template is found.
"
function <SID>TFind(path, name, up)
	let l:tmpl = <SID>TSearch(a:path, "=" . a:name, a:up)
	let l:path = exists("g:template_dir") ? g:template_dir : s:default_template_dir
	if l:tmpl != ""
		return l:tmpl
	else
		return <SID>TSearch(<SID>NormalizePath(expand(l:path . "/")), a:name, 1)
	endif
endfunction


" Template variable expansion. {{{1

" Makes a single [variable] expansion, using [value] as replacement.
"
function <SID>TExpand(variable, value)
	silent! execute "%s/%" . a:variable . "%/" .  a:value . "/g"
endfunction


" Performs variable expansion in a template once it was loaded {{{2
"
function <SID>TExpandVars()
	" Date/time values
	let l:day   = strftime("%d")
	let l:year  = strftime("%Y")
	let l:month = strftime("%m")
	let l:time  = strftime("%H:%M")
	let l:date  = exists("g:dateformat") ? strftime(g:dateformat) :
				\ (l:year . "-" . l:month . "-" . l:day)
	let l:fdate = l:date . " " . l:time
	let l:filen = expand("%:t:r")
	let l:filex = expand("%:e")
	let l:filec = expand("%:t")
	let l:hostn = hostname()
	let l:user  = exists("g:username") ? g:username :
				\ (exists("g:user") ? g:user : $USER)
	let l:email = exists("g:email") ? g:email : (l:user . "@" . l:hostn)
	let l:guard = toupper(substitute(l:filec, "[^a-zA-Z0-9]", "_", "g"))
	let l:class = substitute(l:filen, "\\([a-zA-Z]\\+\\)", "\\u\\1\\e", "g")

	" Finally, perform expansions
	call <SID>TExpand("DAY",   l:day)
	call <SID>TExpand("YEAR",  l:year)
	call <SID>TExpand("DATE",  l:date)
	call <SID>TExpand("TIME",  l:time)
	call <SID>TExpand("USER",  l:user)
	call <SID>TExpand("FDATE", l:fdate)
	call <SID>TExpand("MONTH", l:month)
	call <SID>TExpand("FILE",  l:filen)
	call <SID>TExpand("FFILE", l:filec)
	call <SID>TExpand("EXT",   l:filex)
	call <SID>TExpand("MAIL",  l:email)
	call <SID>TExpand("HOST",  l:hostn)
	call <SID>TExpand("GUARD", l:guard)
	call <SID>TExpand("CLASS", l:class)
	call <SID>TExpand("LICENSE", exists("g:license") ? g:license : "MIT")
endfunction

" }}}2

" Puts the cursor either at the first line of the file or in the place of
" the template where the %HERE% string is found, removing %HERE% from the
" template.
"
function <SID>TPutCursor()
	0  " Go to first line before searching
	if search("%HERE%", "W")
		let l:column = col(".")
		let l:lineno = line(".")
		s/%HERE%//
		call cursor(l:lineno, l:column)
	endif
endfunction


" Template application. {{{1

" Loads a template for the current buffer, substitutes variables and puts
" cursor at %HERE%. Used to implement the BufNewFile autocommand.
"
function <SID>TLoad()
	if !line2byte( line( '$' ) + 1 ) == -1
		return
	endif

	let l:file_ext = expand("%:e")
	if l:file_ext == ""
		let l:file_ext = expand("%:t")
	endif

	let l:file_dir = <SID>DirName(expand("%:p"))

	let l:depth = exists("g:template_max_depth") ? g:template_max_depth : 0
	let l:tName = "template." . l:file_ext
	let l:tFile = <SID>TFind(l:file_dir, l:tName, l:depth)
	if l:tFile != ""
		" Read template file and expand variables in it.
		execute "0r " . l:tFile
		call <SID>TExpandVars()
		call <SID>TPutCursor()
		setlocal nomodified
	endif
endfunction


" Like the previous one, TLoad(), but intended to be called with an argument
" that either is a filename (so the file is loaded as a template) or
" a template suffix (and the template is searched as usual). Of course this
" makes variable expansion and cursor positioning.
"
function <SID>TLoadCmd(template)
	if filereadable(a:template)
		let l:tFile = a:template
	else
		let l:depth = exists("g:template_max_depth") ? g:template_max_depth : 0
		let l:tName = "template." . a:template
		let l:tFile = <SID>TFind(<SID>DirName(expand("%:p")), l:tName, l:depth)
	endif

	if l:tFile != ""
		execute "0r " . l:tFile
		call <SID>TExpandVars()
		call <SID>TPutCursor()
	endif
endfunction

" Commands {{{1

" Just calls the above function, pass either a filename or a template
" suffix, as explained before =)
"
command -nargs=1 -complete=file Template call <SID>TLoadCmd("<args>")


" vim: fdm=marker

