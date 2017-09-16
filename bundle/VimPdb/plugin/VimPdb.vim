"
" VimPdb.vim
"
" Intergrates a Python debugger into Vim in an IDE-like fashion.
"
" Author:
" 	Yaron Budowski
"




"
" Initialization code
"
"

let current_dir = expand("<sfile>:h")
python import sys
exe 'python sys.path.insert(0, r"' . current_dir . '")'
python import VimPdb


function! PdbInitialize()
	" Initializes the VimPdb pluging.

	au BufLeave *.py :call PdbBuffLeave()
	au BufEnter *.py :call PdbBuffEnter()
	au BufEnter *.py :call PdbMapKeyboard()
	au VimLeave *.py :call PdbStopDebug()

	call PdbMapKeyboard()

	let current_dir = expand("<sfile>:h")
	python import sys
	exe 'python sys.path.insert(0, r"' . current_dir . '")'
	python import VimPdb

	python << EOF
import vim
import threading
import time
import re

reload(VimPdb)


# The VimPdb instance used for debugging.
vim_pdb = VimPdb.VimPdb()
vim_pdb.stack_entry_format = vim.eval('g:stack_entry_format')
vim_pdb.stack_entry_prefix = vim.eval('g:stack_entry_prefix')
vim_pdb.current_stack_entry_prefix = vim.eval('g:current_stack_entry_prefix')
vim_pdb.stack_entries_joiner = vim.eval('g:stack_entries_joiner')


def vim_pdb_start_debug(stop_immediately, args):
	global vim_pdb
	vim_pdb.start_debugging(vim.current.buffer.name, stop_immediately, args)


def parse_command_line(line):
	"""Parses command line."""
	args = []
	while (len(line) > 0):
		if (line[0] == '"'):
			next_quotation_mark = line.find('"', 1)
			if (next_quotation_mark == -1):
				# No ending quotation mark found.
				line = line[1:]
				continue

			# Treat anything between the two quotation marks as one argument.
			args.append(line[1:next_quotation_mark])
			line = line[next_quotation_mark + 1:]
			continue

		match = re.search('\s+', line)
		if (not match):
			# No whitespace found - save the argument until the end of the line.
			args.append(line)
			line = ""
			continue
		if (match.start() == 0):
			# Whitespace in the beginning of the line - skip it.
			line = line[match.end():]
			continue

		args.append(line[:match.start()])
		line = line[match.end():]

	return args
EOF

endfunction



"
" Vim event related functions
"

function! PdbBuffLeave()
	" Used when leaving the current buffer - clear all highlighting.

	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('clear_current_line_highlighting')
	vim_pdb.add_queued_method('clear_breakpoints_highlighting')
EOF
endfunction

function! PdbBuffEnter()
	" Used when entering a new buffer - highlighting all breakpoints, etc (if there are any).

	python <<EOF
if (vim_pdb.is_debugged()):
	file('out.txt', 'a').write('BuffEnter\n')
	vim_pdb.add_queued_method('highlight_current_line_for_file', vim.current.buffer.name)
	vim_pdb.add_queued_method('highlight_breakpoints_for_file', vim.current.buffer.name)
EOF
endfunction


"
" Start\Stop debugging functions
"


function! PdbStartDebug(stop_immediately, args)
	" Start a debugging session for the current buffer.
	
	python << EOF
if ((not vim_pdb) or (not vim_pdb.is_debugged())):
	# Start a new VimPdb debugging thread (so Vim won't get halted).
	stop_immediately = bool(int(vim.eval('a:stop_immediately')))
	args = list(vim.eval('a:args'))
	vim_pdb_thread = threading.Thread(target = vim_pdb_start_debug, args = (stop_immediately, args))
	vim_pdb_thread.setDaemon(False)
	vim_pdb_thread.start()
else:
	# Just continue the debugging.
	vim_pdb.add_queued_method('do_continue')
EOF


	if (g:auto_load_breakpoints_file == 1)
		" Load the default breakpoints file at the beginning of the
		" debugging session.
		call PdbLoadSavedBreakpoints(g:default_breakpoints_filename)
	endif
endfunction

function! PdbStartDebugWithArguments()
	" Start a debugging session for the current buffer, with a list of
	" arguments given by the user.
	
	python << EOF
# Get the arguments from the user.
command_line = vim.eval('input("Arguments: ")')

if (command_line is not None):
	# Parse the arguments.
	args = parse_command_line(command_line)

	if (not vim_pdb):
		vim.command('call PdbStartDebug(1, %s)' % (args))
	else:
		# TODO - special case?
		if (vim_pdb.is_debugged()):
			# Stop the existing debugging session.
			vim.command('call PdbStopDebug()')
			vim.command('call PdbInitialize()')

		vim.command('call PdbStartDebug(1, %s)' % (args))

EOF
endfunction


function! PdbStopDebug()
	" Stops an active debugging session.

	if (g:auto_save_breakpoints_file == 1)
		" Save to the default breakpoints file at the end of the
		" debugging session.
		call PdbSaveSavedBreakpoints(g:default_breakpoints_filename)
	endif
	
	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('stop_debugging')

	# Wait until the thread terminates.
	while (vim_pdb_thread.isAlive()):
		time.sleep(0.1)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF


endfunction

function! PdbRestartDebug()
	" Restarts a debugging session.
	call PdbStopDebug()
	call PdbStartDebug(1, [])
endfunction


"
" Saving\Loading breakpoints methods
"


function! PdbLoadSavedBreakpoints(...)
	" Loads saved breakpoints from a file.

	python <<EOF
if (vim_pdb.is_debugged()):
	if (int(vim.eval('a:0')) == 0):
		filename = vim.eval('input("Filename: ")')
	else:
		filename = vim.eval('a:1')

	if (filename is not None):
		vim_pdb.add_queued_method('load_breakpoints_from_file', filename)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE

EOF
endfunction


function! PdbSaveSavedBreakpoints(...)
	" Saves saved breakpoints to a file.

	python <<EOF
if (vim_pdb.is_debugged()):
	if (int(vim.eval('a:0')) == 0):
		filename = vim.eval('input("Filename: ")')
	else:
		filename = vim.eval('a:1')

	if (filename is not None):
		vim_pdb.add_queued_method('save_breakpoints_to_file', filename)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE

EOF
endfunction




"
" Deubgging methods
"


function! PdbContinue()
	" Continues a debugging session.

	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('do_continue')
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction

function! PdbStepInto()
	" Performs a step into

	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('do_step_into')
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction

function! PdbStepOver()
	" Performs a step over

	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('do_step_over')
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction

function! PdbContinueUntilReturn()
	" Performs continue until returning

	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('do_continue_until_return')
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction


function! PdbJumpToCurrentLine()
	" Jumps to the specified current line.

	python <<EOF
if (vim_pdb.is_debugged()):
	line_number = int(vim.eval('line(".")'))
	vim_pdb.add_queued_method('do_jump', vim.current.buffer.name, line_number)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction


function! PdbMoveUpInStackFrame()
	" Moves up one level in the stack frame.

	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('do_move_up_in_stack_frame')
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction

function! PdbMoveDownInStackFrame()
	" Moves down one level in the stack frame.

	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('do_move_down_in_stack_frame')
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction


function! PdbToggleBreakpointOnCurrentLine()
	" Toggles breakpoint on the current line.

	python << EOF
if (vim_pdb.is_debugged()):
	line_number = int(vim.eval('line(".")'))
	vim_pdb.add_queued_method('do_toggle_breakpoint', vim.current.buffer.name, line_number)
	vim_pdb.add_queued_method('highlight_breakpoints_for_file', vim.current.buffer.name)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction

function! PdbToggleConditionalBreakpointOnCurrentLine()
	" Toggles a conditional breakpoint on the current line.

	python << EOF
if (vim_pdb.is_debugged()):
	line_number = int(vim.eval('line(".")'))

	if ((not vim_pdb.run_method_and_return_output('is_breakpoint_enabled', vim.current.buffer.name, line_number)) and
		(vim_pdb.run_method_and_return_output('is_code_line', vim.current.buffer.name, line_number))):
		condition = vim.eval('input("Condition: ")')

		if ((condition is not None) and (len(condition.strip()) > 0)):
			vim_pdb.add_queued_method('do_toggle_breakpoint', vim.current.buffer.name, line_number, condition.strip())
	else:
		condition = None
		vim_pdb.add_queued_method('do_toggle_breakpoint', vim.current.buffer.name, line_number, condition)

else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction

function! PdbToggleTemporaryBreakpointOnCurrentLine()
	" Toggles a temporary breakpoint on the current line.

	python << EOF
if (vim_pdb.is_debugged()):
	line_number = int(vim.eval('line(".")'))
	vim_pdb.add_queued_method('do_toggle_breakpoint', vim.current.buffer.name, line_number, None, True)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction



function PdbClearAllBreakpointsInCurrentFile()
	" Clears all breakpoints in the current file.

	python << EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('do_clear_all_breakpoints', vim.current.buffer.name)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction

function PdbClearAllBreakpoints()
	" Clears all breakpoints in all files.

	python << EOF
if (vim_pdb.is_debugged()):
	vim_pdb.add_queued_method('do_clear_all_breakpoints')
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction


function! PdbPrintBreakpointConditionOnCurrentLine()
	" Prints the condition of the conditional breakpoint in the current line.

	python << EOF
if (vim_pdb.is_debugged()):
	line_number = int(vim.eval('line(".")'))

	print vim_pdb.run_method('do_print_breakpoint_condition', vim.current.buffer.name, line_number)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction



function! PdbEvalCurrentWord()
	" Evals the word currently under the cursor.

	python <<EOF
if (vim_pdb.is_debugged()):
	current_word = vim.eval('expand("<cword>")')

	if ((current_word is not None) and (len(current_word.strip()) > 0)):
		vim_pdb.run_method('do_eval', current_word)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction

function! PdbEvalCurrentWORD()
	" Evals the WORD currently under the cursor.

	python <<EOF
if (vim_pdb.is_debugged()):
	current_word = vim.eval('expand("<cWORD>")')

	if ((current_word is not None) and (len(current_word.strip()) > 0)):
		vim_pdb.run_method('do_eval', current_word)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction

function! PdbEvalExpression()
	" Evals an expression given by the user.

	python <<EOF
if (vim_pdb.is_debugged()):
	expression = vim.eval('input("Eval Expression: ")')
	if (expression is not None):
		vim_pdb.run_method('do_eval', expression)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction


function! PdbExecStatement()
	" Execs a statement given by the user.

	python <<EOF
if (vim_pdb.is_debugged()):
	statement = vim.eval('input("Exec Statement: ")')
	if (statement is not None):
		vim_pdb.run_method('do_exec', statement)
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction


function! PdbPrintStackTrace()
	" Prints the current stack trace.
	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.run_method('do_print_stack_trace')
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction



function! PdbSetFocusToCurrentDebugLine()
	" Moves the cursor to the currently debugged line.
	python <<EOF
if (vim_pdb.is_debugged()):
	vim_pdb.set_cursor_to_current_line()
else:
	print VimPdb.VimPdb.MESSAGE_NOT_IN_DEBUG_MODE
EOF
endfunction



" ==========
" EDIT HERE
" ==========



"
" Line highlighting
"


highlight PdbCurrentLine guibg=DarkGreen
highlight PdbBreakpoint guibg=DarkRed
highlight PdbConditionalBreakpoint guibg=Purple
highlight PdbTemporaryBreakpoint guibg=SlateBlue


function! PdbMapKeyboard()
	"
	" Keyboard shortcuts
	"

	map <buffer> <silent> <F5> :call PdbStartDebug(1, [])<CR>
	" Start debug and don't pause immediately.
	map <buffer> <silent> <C-F5> :call PdbStartDebug(0, [])<CR>
	map <buffer> <silent> <C-S-F5> :call PdbStartDebugWithArguments()<CR>
	map <buffer> <silent> <S-F5> :call PdbStopDebug()<CR>
	map <buffer> <silent> <C-A-S-F5> :call PdbRestartDebug()<CR>

	map <buffer> <silent> <LocalLeader>L :call PdbLoadSavedBreakpoints()<CR>
	map <buffer> <silent> <LocalLeader>S :call PdbSaveSavedBreakpoints()<CR>

	map <buffer> <silent> <F7> :call PdbStepInto()<CR>
	map <buffer> <silent> <F8> :call PdbStepOver()<CR>
	map <buffer> <silent> <C-F8> :call PdbContinueUntilReturn()<CR>

	map <buffer> <silent> <F9> :call PdbMoveUpInStackFrame()<CR>
	map <buffer> <silent> <F10> :call PdbMoveDownInStackFrame()<CR>

	map <buffer> <silent> <F6> :call PdbSetFocusToCurrentDebugLine()<CR>
	map <buffer> <silent> <C-F6> :call PdbJumpToCurrentLine()<CR>

	map <buffer> <silent> <F2> :call PdbToggleBreakpointOnCurrentLine()<CR>
	map <buffer> <silent> <C-F2> :call PdbToggleConditionalBreakpointOnCurrentLine()<CR>
	map <buffer> <silent> <S-F2> :call PdbToggleTemporaryBreakpointOnCurrentLine()<CR>
	map <buffer> <silent> <C-S-F2> :call PdbClearAllBreakpointsInCurrentFile()<CR>
	map <buffer> <silent> <C-A-S-F2> :call PdbClearAllBreakpoints()<CR>

	map <buffer> <silent> <F11> :call PdbPrintBreakpointConditionOnCurrentLine()<CR>

	map <buffer> <silent> <F4> :call PdbEvalCurrentWord()<CR>
	map <buffer> <silent> <C-F4> :call PdbEvalCurrentWORD()<CR>

	map <buffer> <silent> <F3> :call PdbEvalExpression()<CR>
	map <buffer> <silent> <C-F3> :call PdbExecStatement()<CR>

	map <buffer> <silent> <F12> :call PdbPrintStackTrace()<CR>
endfunction


" The format string for displaying a stack entry.
let g:stack_entry_format = "%(dir)s\\%(filename)s (%(line)d): %(function)s(%(args)s) %(return_value)s %(source_line)s"
" The string used to join stack entries together.
let g:stack_entries_joiner = " ==>\n"
" The prefix to each stack entry - 'regular' and current stack entry.
let g:stack_entry_prefix = "  "
let g:current_stack_entry_prefix = "* "

" Should VimPdb look for saved breakpoints file when starting a debug session?
let g:auto_load_breakpoints_file = 0
" Should VimPdb save the breakpoints file when stopping the debug session?
let g:auto_save_breakpoints_file = 0
" The name of the default saved breakpoints file (in the currently debugged directory).
" Used when auto_load_breakpoints_file/auto_save_breakpoints_file are turned on.
let g:default_breakpoints_filename = "bplist.vpb"



"
" Main code
"


call PdbInitialize()

