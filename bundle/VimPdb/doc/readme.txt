VimPdb Beta
by Yaron Budowski


1. About
2. Features
3. Installation
4. Key Bindings
5. Customizing VimPdb
6. Known Issues

============================

1. About
---------------

VimPdb allows you to debug Python programs like in a standard IDE (Step in/over, toggle breakpoint, etc).


2. Features
-------------

- Highlighting of current debugged line.
- Opening the appropriate debugged file when needed.
- Highlighting of breakpoints.
- Save/Load current session breakpoints in files.
- IDE-Like debugging commands.

3. Installation
----------------

Just drop VimPdb.py and VimPdb.vim into your plugin directory. Make sure the key bindings do not interfere with any existing ones.

4. Key Bindings
-----------------

- F5 - Start/continue debug session of current file.
- Ctrl-F5 - Start debugging and do not pause at first line
- Ctrl-Shift-F5 - Start debugging with a given list of parameters.
- Shift-F5 - Stop the current debug session.
- Ctrl-Alt-Shift-F5 - Restart the current debug session.

- F2 - Toggle breakpoint.
- Ctrl-F2 - Toggle conditional breakpoint
- Shift-F2 - Toggle temporary breakpoint
- Ctrl-Shift-F2 - Clear all breakpoints in current file
- Ctrl-Alt-Shift-F2 - Clear all breakpoints in all files
- F11 - Print condition of conditional breakpoint under the cursor

- F7 - Step into
- F8 - Step over
- Ctrl-F8 - Continue running until reaching a return from function

- F6 - Move cursor to currently debugged line.
- Ctrl-F6 - Change current debugged line to where the cursor is currently placed.

- F9 - Move up in stack frame.
- F10 - Move down in stack frame.

- F12 - Print stack trace

- F3 - Eval a given expression (in the current debug context)
- Ctrl-F3 - Exec a given statement (in the current debug context)

- F4 - Eval the current word under the cursor (in the current debug context)
- Ctrl-F4 - Eval the current WORD under the cursor (in the current debug context)

- <Leader>s - Save current debug session breakpoints to a file.
- <Leader>l - Load saved breakpoints from a file.

5. Customizing VimPdb
-----------------------

VimPdb.vim contains several options which allow the user to customize it:

- stack_entry_format: the format used when printing the stack trace (using F12). Possible format keyword arguments:
	* dir - the directory of the debugged file.
	* filename - the filename of the debugged file.
	* line - the current line number.
	* function - the current function name.
	* args - the arguments passed to the current function.
	* return_value - the return value from the function.
	* source_line - the source code of the current line.
- stack_entries_joiner: when there's more than one line of stack trace, this string is used to join the lines.
- stack_entry_prefix: each stack trace entry line has this as its prefix.
- current_stack_entry_prefix: the current stack trace entry line is prefixed with this string.

- auto_load_breakpoints_file: when this is set to 1, VimPdb will look for a saved breakpoints
  file (default_breakpoints_filename) in the current directory when loading a new debug session.
- auto_save_breakpoints_file: when this is set to 1, VimPdb will save all current session breakpoints into a
  file (default_breakpoints_filename) when exiting Vim.
- default_breakpoints_filename: the filename used when auto_load_breakpoints_file/auto_saved_breakpoints_file are set.

The following highlighting groups can be changed as well:
- PdbCurrentLine: the currently debugged line.
- PdbBreakpoint: a "regular" breakpoint.
- PdbConditionalBreakpoint: a conditional breakpoint.
- PdbTemporaryBreakpoint: a temporary breakpoint.

And of course, default key bindings can be modified.

6. Known Issues
----------------

- Breakpoint lines aren't highlighted properly (through out the line) when there are Python keywords at the beginning of the line.
e.g.: a breakpoint line that starts (with no whitespace) with a "print" will be highlighted only after the "print".
This is due to Vim's coloring precedence (keywords over any other type of match).
Curent line highlighting works fine (due to use of :match instead of :syn match command, which precedes any other
language highlighting). But the problem is that no more than one type of highlighting group can be used simultaneity
with with a :match command.

- Instability of Vim has been reported (freezing/crashing).
This is probably due to the use of another Python thread within the Vim process.
I've tried to make it so that the main Vim process doesn't interact directly with the Python thread (only via a common
command queue). This improved stability, but not entirely.

