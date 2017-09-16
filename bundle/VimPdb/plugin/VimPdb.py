"""
	VimPdb.py

	Pdb simulation within Vim (in an IDE like fashion).

	Author:
		Yaron Budowski
"""
import bdb
import vim
import time
import sys
import os



class PdbIDE(bdb.Bdb):
	"""Simulates a Python debugger in an IDE-like mode (unlike PDB, which acts as a command-line console debugger)."""

	#
	# Constants
	#


	# The number of seconds to wait in the wait_in_debug() waiting loop.
	PAUSE_DEBUG_WAIT_TIME = 0.2

	# Various messages displayed to the user.
	MESSAGE_NOT_IN_DEBUG_MODE = 'Error: Debugging not started yet'
	MESSAGE_STARTING_DEBUG = 'Starting debugging...'
	MESSAGE_PROGRAM_ENDED = 'Program ended. Restart debug to rerun program'
	MESSAGE_ALREADY_AT_OLDEST_FRAME = 'Error: Already at oldest stack frame'
	MESSAGE_ALREADY_AT_NEWEST_FRAME = 'Error: Already at newest stack frame'
	MESSAGE_PROGRAM_ENDED_VIA_SYS_EXIT = 'Program ended via sys.exit(). Exit status: %d'
	MESSAGE_PROGRAM_ENDED_UNCAUGHT_EXCEPTION = 'Program ended due to an uncaught exception.'
	MESSAGE_NO_CONDITIONAL_BREAKPOINT = 'Error: No conditional breakpoint in current line'
	MESSAGE_BREAKPOINT_CONDITION = 'Breakpoint Condition: %s'
	MESSAGE_JUMP_ONLY_AT_BOTTOM_FRAME = 'Error: Can only jump to line within the bottom stack frame'
	MESSAGE_JUMP_ONLY_IN_CURRENT_FILE = 'Error: Can only jump to line within the currently debugged file'

	# Breakpoint types (used when saving\loading breakpoints from files).
	BREAKPOINT_TYPE_REGULAR = 'regular'
	BREAKPOINT_TYPE_TEMPORARY = 'temporary'
	BREAKPOINT_TYPE_CONDITIONAL = 'conditional'
	BREAKPOINT_TYPES = [BREAKPOINT_TYPE_REGULAR, BREAKPOINT_TYPE_CONDITIONAL, BREAKPOINT_TYPE_TEMPORARY]



	def __init__(self):
		# Initialize the parent Bdb class.
		bdb.Bdb.__init__(self)

		# Used so we won't pause until the main script is loaded completely.
		self.wait_for_script_start = False
		self.main_filename = None

		# Used in wait_in_debug method (method doesn't return until pause_debug == False).
		self.pause_debug = False

		# Current debugged filename & line.
		self.current_filename = None
		self.current_line = -1

		# Current debugged frame.
		self.current_frame = None

		self.current_stack_index = 0
		self.stack = []


		# A queue of Bdb methods to run. This is used when VimPdb methods (as opposed to Bdb methods) are called directly
		# from the Vim file (VimPdb.vim) - these methods (such as do_toggle_breakpoint) use this queue to call Bdb methods
		# (such as set_break) indirectly - it's done this way so the Bdb methods will be called from this instance's thread,
		# and not from the Vim thread (which is the main thread). If the Bdb methods were called directly, it would screw up Python
		# and Vim, and Vim will sometimes freeze\crash.
		# The run_queued_methods method goes through this queue and executes the commands in it: each item is a list of
		# function name and parameters.
		self.methods_to_run = []

		# The return value of the last method.
		self.last_method_return_value = None

		


	def start_debugging(self, filename, stop_immediately = True, args = []):
		"""Starts a debug session for a file. If stop_immediately is set, session is paused on the first line of program."""
		self.print_message(self.MESSAGE_STARTING_DEBUG)
		new_globals = { '__name__': '__main__' }
		new_locals = new_globals

		self.wait_for_script_start = True # So we won't break before we reach the first line of the script being debugged.
		self.stop_immediately = stop_immediately
		self.main_filename = self.canonic(filename)

		self.current_filename = self.main_filename
		self.current_line = 1


		# Highlight the breakpoints.
		self.highlight_breakpoints(self.main_filename, *self.get_breakpoints_for_file(self.main_filename))

		# Replace main directory with running script's directory in front of module search path.
		sys.path[0] = os.path.dirname(self.main_filename)

		try:
			# Set command line arguments.
			sys.argv = [self.main_filename] + args
			# Run the script.
			statement = 'execfile(r"%s")' % (self.main_filename)
			self.run(statement, globals = new_globals, locals = new_locals)

			# Program ended.
			self.print_message(self.MESSAGE_PROGRAM_ENDED)
			self.clear_current_line_highlighting()
			self.clear_breakpoints_highlighting()
		except SystemExit:
			self.print_message(self.MESSAGE_PROGRAM_ENDED_VIA_SYS_EXIT % (sys.exc_info()[1]))
			self.clear_current_line_highlighting()
			self.clear_breakpoints_highlighting()
		except:
			self.print_message(self.MESSAGE_PROGRAM_ENDED_UNCAUGHT_EXCEPTION)
			raise
			self.clear_current_line_highlighting()
			self.clear_breakpoints_highlighting()


	def stop_debugging(self):
		"""Stops the debugging session."""
		if (not self.is_debugged()):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		self.quitting = True


	#
	# Debugging methods
	#


	def do_continue(self):
		"""Continues the deugging session until reaching a breakpoint, etc."""
		if (self.current_frame is None):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		self.set_continue()
		self.pause_debug = False

	def do_continue_until_return(self):
		"""Continues running until returning from the current frame."""
		if (self.current_frame is None):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		self.set_return(self.current_frame)
		self.pause_debug = False

	def do_step_into(self):
		"""Does step into."""
		if (self.current_frame is None):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		self.set_step()
		self.pause_debug = False

	def do_step_over(self):
		"""Does step over (doesn't enter any functions in between)."""
		if (self.current_frame is None):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		self.set_next(self.current_frame)
		self.pause_debug = False

	def do_move_up_in_stack_frame(self):
		"""Moves up one level in the stack frame."""
		if (not self.is_debugged()):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		if (self.current_stack_index <= 2):
			self.print_message(self.MESSAGE_ALREADY_AT_OLDEST_FRAME)
			return

		self.current_stack_index -= 1
		self.current_frame = self.stack[self.current_stack_index][0]

		self.goto_current_line(self.current_frame)

	def do_move_down_in_stack_frame(self):
		"""Moves down one level in the stack frame."""
		if (not self.is_debugged()):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		if (self.current_stack_index + 1== len(self.stack)):
			self.print_message(self.MESSAGE_ALREADY_AT_NEWEST_FRAME)
			return

		self.current_stack_index += 1
		self.current_frame = self.stack[self.current_stack_index][0]

		self.goto_current_line(self.current_frame)


	def do_toggle_breakpoint(self, filename, line_number, condition = None, temporary = False):
		"""Sets\unsets a breakpoint."""
		if (not self.is_debugged()):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		if (not self.is_code_line(filename, line_number)):
			# Not a code line.
			return

		# First, prepare a list of all available breakpoints for this file.
		breakpoints = self.get_file_breaks(filename)[:] # Make a copy so we won't be affected by changes.

		if (line_number in breakpoints):
			# Unset breakpoint.
			self.clear_break(filename, line_number)
		else:
			# Set the breakpoint.
			self.set_break(filename, line_number, int(temporary), condition)

		# Re-Highlight the breakpoints.
		self.highlight_breakpoints(filename, *self.get_breakpoints_for_file(filename))

	def do_print_breakpoint_condition(self, filename, line_number):
		"""Prints the condition of a breakpoint at the specified line number."""
		if (not self.is_debugged()):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		# First, prepare a list of all available breakpoints for this file.
		conditional_breakpoints = self.get_conditional_breakpoints(filename)

		if (line_number not in conditional_breakpoints):
			self.print_message(self.MESSAGE_NO_CONDITIONAL_BREAKPOINT)
			return

		breakpoint_instances = self.get_breaks(filename, line_number)

		for breakpoint in breakpoint_instances:
			if (breakpoint.cond):
				self.print_message(self.MESSAGE_BREAKPOINT_CONDITION % (breakpoint.cond))
				return


	def do_clear_all_breakpoints(self, filename = None):
		"""Clears all breakpoints. If filename is specified, only breakpoints for that filename are cleared."""

		if (filename is None):
			self.clear_all_breaks()
			# Re-Highlight the breakpoints.
			self.highlight_breakpoints(filename, *self.get_breakpoints_for_file(filename))
			return

		# Get all breakpoints for specified file.
		file_breaks = self.get_file_breaks(filename)

		for line_number in file_breaks:
			self.clear_break(filename, line_number)

		# Re-Highlight the breakpoints.
		self.highlight_breakpoints(filename, *self.get_breakpoints_for_file(filename))

	def do_clear(self, breakpoint_number):
		"""Clears a specified breakpoint by number."""
		self.clear_bpbynumber(breakpoint_number)
		# Re-Highlight the breakpoints.
		self.highlight_breakpoints(self.current_filename, *self.get_breakpoints_for_file(self.current_filename))


	def do_eval(self, expression):
		"""Evaluates an expression in the current debugging context."""
		if (self.current_frame is None):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		try:
			value = eval(expression, self.current_frame.f_globals, self.current_frame.f_locals)
			self.print_message(value)
		except:
			(exc_type, value, traceback) = sys.exc_info()

			if (not isinstance(exc_type, str)):
				exc_type_name = exc_type.__name__
			else:
				exc_type_name = exc_type

			self.print_message('%s: %s' % (exc_type_name, value))

	def do_exec(self, statement):
		"""Executes a statement in the current debugging context."""
		if (self.current_frame is None):
			self.print_message(self.MESSAGE_NOT_IN_DEBUG_MODE)
			return

		exec_locals = self.current_frame.f_locals
		exec_globals = self.current_frame.f_locals

		try:
			code = compile(statement + '\n', '<stdin>', 'single')
			exec code in exec_globals, exec_locals
		except:
			(exc_type, value, traceback) = sys.exc_info()

			if (not isinstance(exc_type, str)):
				exc_type_name = exc_type.__name__
			else:
				exc_type_name = exc_type

			self.print_message('%s: %s' % (exc_type_name, value))


	def do_jump(self, filename, line_number):
		"""Jumps to a specified line in the currently debugged file."""
		if (self.current_stack_index + 1 != len(self.stack)):
			self.print_message(self.MESSAGE_JUMP_ONLY_AT_BOTTOM_FRAME)
			return

		if (self.canonic(filename) != self.current_filename):
			self.print_message(self.MESSAGE_JUMP_ONLY_IN_CURRENT_FILE)
			return

		try:
			self.current_frame.f_lineno = line_number
			self.stack[self.current_stack_index] = (self.stack[self.current_stack_index][0], line_number)

			self.goto_current_line(self.current_frame)
		except ValueError, exc:
			self.print_message('Error: %s' % (exc))


	def do_print_stack_trace(self):
		"""Prints the stack trace."""

		output_stack_traces = []

		# Prepare the stack trace string.
		for current_stack_frame in self.stack[2:]: # Skip the first two entries (which aren't really part of the debugged code)
			(frame, line_number) = current_stack_frame

			if (frame is self.current_frame):
				output_stack_traces.append(self.current_stack_entry_prefix + self.format_stack_entry(current_stack_frame))
			else:
				output_stack_traces.append(self.stack_entry_prefix + self.format_stack_entry(current_stack_frame))


		final_stack_trace = self.stack_entries_joiner.join(output_stack_traces)

		self.print_message('Stack Trace:\n' + final_stack_trace)
	

	def goto_current_line(self, frame, display = True):
		"""Moves the cursor to the currently debugged line, in the appropriate file. If display == False, don't highlight or move the cursor."""
		if (not self.is_debugged()):
			return

		# Get the line number & filename.
		line_number = frame.f_lineno
		filename = self.canonic(frame.f_code.co_filename)

		self.current_filename = filename
		self.current_line = line_number

		if (display):
			# Load the file for editing (even if the file is not currently opened).
			self.open_file(filename)
			self.set_cursor_position(self.current_line, 0)
			self.highlight_current_line(self.current_filename, self.current_line)


	#
	# Queue related methods
	#


	def add_queued_method(self, function_name, *parameters):
		"""Adds a method to the methods to run queue. It will be called indirectly by run_queued_methods"""
		self.methods_to_run.append([function_name, parameters])
	

	def run_queued_methods(self):
		"""Executes any methods queued for execution. Used so that the methods will be executed from this instance's
		thread context (and not from the main Vim thread)."""

		while (len(self.methods_to_run) > 0):
			# Get the next method to run.
			method_to_run = self.methods_to_run[0]
			self.methods_to_run = self.methods_to_run[1:]

			(function_name, parameters) = method_to_run

			if (not hasattr(self, function_name)):
				# Function doesn't exist.
				raise
				# TODO
				#continue

			# Run the function.
			function_pointer = getattr(self, function_name)
			self.last_method_return_value = function_pointer(*parameters)

	def wait_in_debug(self, frame, traceback = None):
		"""Loops as long as self.pause_debug is True."""

		# Save the current frame, etc.
		(self.stack, self.current_stack_index) = self.get_stack(frame, traceback)
		self.current_frame = self.stack[self.current_stack_index][0]

		self.goto_current_line(frame)

		while ((self.pause_debug) and (not self.quitting)):
			time.sleep(self.PAUSE_DEBUG_WAIT_TIME)

			# Run any queued methods.
			self.run_queued_methods()

		self.pause_debug = True


	#
	# Saving\Restoring breakpoints methods
	#


	def is_breakpoint_enabled(self, filename, line):
		"""Returns True if a breakpoint is enabled at the specified filename & line. False otherwise."""

		if (self.get_breaks(filename, line)):
			return True
		else:
			return False
	

	def highlight_breakpoints_for_file(self, filename):
		"""Highlights breakpoints for a given filename."""

		self.highlight_breakpoints(self.canonic(filename), *self.get_breakpoints_for_file(self.canonic(filename)))

	def highlight_current_line_for_file(self, filename):
		"""Highlights current line for a given filename."""

		canonic_filename = self.canonic(filename)
		if (self.current_filename != canonic_filename):
			# The given filename is not the currently debugged file.
			return

		self.highlight_current_line(canonic_filename, self.current_line)



	def get_breakpoints(self):
		"""Returns a list of active breakpoints."""
		file_breakpoints = self.get_all_breaks()

		returned_breakpoints = []
		for filename in file_breakpoints.keys():
			for line_number in file_breakpoints[filename]:
				for breakpoint in self.get_breaks(filename, line_number):
					new_breakpoint = {}
					new_breakpoint['filename'] = filename
					new_breakpoint['line'] = breakpoint.line
					
					if (breakpoint.cond):
						new_breakpoint['type'] = self.BREAKPOINT_TYPE_CONDITIONAL
						new_breakpoint['condition'] = breakpoint.cond
					elif (breakpoint.temporary):
						new_breakpoint['type'] = self.BREAKPOINT_TYPE_TEMPORARY
					else:
						new_breakpoint['type'] = self.BREAKPOINT_TYPE_REGULAR

					returned_breakpoints.append(new_breakpoint)

		return returned_breakpoints


	def set_breakpoints(self, breakpoints):
		"""Sets\Adds breakpoints from a list of breakpoints."""

		for breakpoint in breakpoints:
			condition = None
			temporary = False

			if (breakpoint['type'] == self.BREAKPOINT_TYPE_CONDITIONAL):
				condition = breakpoint['condition']
			elif (breakpoint['type'] == self.BREAKPOINT_TYPE_TEMPORARY):
				temporary = True

			# Set the breakpoint
			self.set_break(breakpoint['filename'], breakpoint['line'], int(temporary), condition)

		# Re-highlight all of the breakpoints.
		self.highlight_breakpoints(self.get_active_filename(), *self.get_breakpoints_for_file(self.get_active_filename()))

	def load_breakpoints_from_file(self, filename):
		"""Loads breakpoints from a file."""

		if (not os.path.exists(filename)):
			self.print_message('Error: File "%s" does not exist!' % (filename))
			return
		
		new_breakpoints = []

		# First, clear all breakpoints.
		#self.do_clear_all_breakpoints()

		breakpoints_file = open(filename, 'rb')

		# Load the breakpoints from the given file.
		index = 0
		for line in breakpoints_file.xreadlines():
			line = line.strip()
			index += 1

			if (len(line) == 0):
				continue

			breakpoint_properties = line.split('\t')

			if ((len(breakpoint_properties) < 3) or (len(breakpoint_properties) > 4)):
				self.print_message('Error: Invalid line #%d at file "%s"' % (index, filename))
				return

			(breakpoint_filename, breakpoint_line, breakpoint_type) = breakpoint_properties[:3]
			breakpoint_type = breakpoint_type.lower()
			try:
				breakpoint_line = int(breakpoint_line)
			except ValueError:
				self.print_message('Error: Invalid breakpoint line number in line #%d at file "%s"' % (index, filename))
				return

			if (breakpoint_type not in self.BREAKPOINT_TYPES):
				self.print_message('Error: Invalid breakpoint type in line #%d at file "%s"' % (index, filename))
				return

			if ((breakpoint_type == self.BREAKPOINT_TYPE_CONDITIONAL) and (len(breakpoint_properties) != 4)):
				self.print_message('Error: Missing/invalid breakpoint condition in line #%d at file "%s"' % (index, filename))
				return

			condition = None
			temporary = False

			if (breakpoint_type == self.BREAKPOINT_TYPE_CONDITIONAL):
				condition = breakpoint_properties[3]
			elif (breakpoint_type == self.BREAKPOINT_TYPE_TEMPORARY):
				temporary = True

			new_breakpoint = {}
			new_breakpoint['filename'] = breakpoint_filename
			new_breakpoint['line'] = breakpoint_line
			new_breakpoint['type'] = breakpoint_type
			new_breakpoint['condition'] = condition
			new_breakpoint['temporary'] = temporary

			new_breakpoints.append(new_breakpoint)

		breakpoints_file.close()

		# Set the loaded breakpoints.
		self.set_breakpoints(new_breakpoints)


	def save_breakpoints_to_file(self, filename):
		"""Saves all active breakpoints to a file."""

		breakpoints_file = open(filename, 'wb')

		breakpoints = self.get_breakpoints()

		for breakpoint in breakpoints:
			line = '%s\t%s\t%s' % (breakpoint['filename'], breakpoint['line'], breakpoint['type'])
			if (breakpoint['type'] == self.BREAKPOINT_TYPE_CONDITIONAL):
				line += '\t' + breakpoint['condition']

			breakpoints_file.write(line + '\n')

		breakpoints_file.close()


	#
	# Helper methods
	#


	def is_debugged(self):
		"""Checks whether or not there active debugging currently enabled."""
		#if ((not hasattr(self, 'quitting')) or (self.quitting) or (not self.current_frame)):
		if ((not hasattr(self, 'quitting')) or (self.quitting)):
			return False
		else:
			return True


	def is_exit_frame(self, frame):
		"""Tests whether or not the current frame is of the exit frame."""

		if (self.canonic(frame.f_code.co_filename) == '<string>'):
			return True
		else:
			return False


	def get_conditional_breakpoints(self, filename):
		"""Returns a list of line numbers with conditional breakpoints for a given filename."""

		conditional_breakpoints = []

		# First, get the line numbers which have breakpoints set in them.
		file_breaks = self.get_file_breaks(filename)

		for line_number in file_breaks:
			breakpoint_instances = self.get_breaks(filename, line_number)

			for breakpoint in breakpoint_instances:
				if (breakpoint.cond):
					# Found a conditional breakpoint - add it to the list.
					conditional_breakpoints.append(line_number)

		return conditional_breakpoints

	def get_temporary_breakpoints(self, filename):
		"""Returns a list of line numbers with temporary breakpoints for a given filename."""

		temporary_breakpoints = []

		# First, get the line numbers which have breakpoints set in them.
		file_breaks = self.get_file_breaks(filename)

		for line_number in file_breaks:
			breakpoint_instances = self.get_breaks(filename, line_number)

			for breakpoint in breakpoint_instances:
				if (breakpoint.temporary):
					# Found a temporary breakpoint - add it to the list.
					temporary_breakpoints.append(line_number)

		return temporary_breakpoints


	def get_breakpoints_for_file(self, filename):
		"""Returns a tuple of (regular_breakpoints, conditional_breakpoints, temporary_breakpoints) for
		a given filename."""

		regular_breakpoints = self.get_file_breaks(filename)[:] # Make a copy so we won't be affected by changes.
		conditional_breakpoints = self.get_conditional_breakpoints(filename)
		temporary_breakpoints = self.get_temporary_breakpoints(filename)

		# Remove any breakpoints which appear in the regular_breakpoints list, and are actually
		# conditional or temporary breakpoints.
		for breakpoint in regular_breakpoints:
			if ((breakpoint in conditional_breakpoints) or (breakpoint in temporary_breakpoints)):
				regular_breakpoints.remove(breakpoint)

		return (regular_breakpoints, conditional_breakpoints, temporary_breakpoints)
	

	def is_code_line(self, filename, line):
		"""Returns True if the given line is a code line; False otherwise.
		Warning: not comprehensive enough."""
		import linecache

		source_line = linecache.getline(self.canonic(filename), line)

		if (not source_line):
			return False

		source_line = source_line.strip()

		if ((len(source_line) == 0) or (source_line[0] == '#') or
				(source_line[:3] == '"""') or (source_line[:3] == "'''")):
			return False

		return True





	#
	# Overridden Bdb methods
	#


	def format_stack_entry(self, stack_frame):
		"""Formats the stack frame into a printable string."""
		import linecache

		(frame, line_number) = stack_frame

		filename = self.canonic(frame.f_code.co_filename)
		(directory, filename) = os.path.split(filename)

		if (frame.f_code.co_name):
			function_name = frame.f_code.co_name
		else:
			function_name = '<lambda>'

		if ('__args__' in frame.f_locals.keys()):
			args = frame.f_locals['__args__']
		else:
			args = ''

		if ('__return__' in frame.f_locals.keys()):
			return_value = '-> %s' % (frame.f_locals['__return__'])
		else:
			return_value = ''

		source_line = linecache.getline(filename, line_number)
		if (not source_line):
			source_line = ''
		else:
			source_line = source_line.strip()

		stack_entry_string = self.stack_entry_format % (
				{'filename': filename, 'dir': directory, 'line': line_number, 'function': function_name,
					'args': args, 'return_value': return_value, 'source_line': source_line})

		return stack_entry_string



	def user_call(self, frame, args):
		if ((self.wait_for_script_start) or (self.quitting)):
			# Haven't reached the start of the script yet.
			return
		if (self.stop_here(frame)):
			# Change the cursor position to the currently debugged line.
			self.wait_in_debug(frame)


	def user_line(self, frame):
		"""Called when we stop or break at this line."""

		if (self.quitting):
			return
		if (self.wait_for_script_start):
			if ((self.main_filename != self.canonic(frame.f_code.co_filename)) or (frame.f_lineno <= 0)):
				# Haven't reached the start of the script yet.
				return

			# Reached the start of the main script being debugged.
			self.wait_for_script_start = False

			if (not self.stop_immediately):
				# Debugging should start without pausing immediately.
				self.set_continue()
				self.pause_debug = False
			else:
				self.pause_debug = True

		# Move to the current line being debugged.

		self.wait_in_debug(frame)

	def user_return(self, frame, return_value):
		"""Called when a return trap is set here."""

		if (self.quitting):
			return

		if (self.is_exit_frame(frame)):
			# It's the last frame.
			self.print_message(self.MESSAGE_PROGRAM_ENDED)
			self.clear_current_line_highlighting()
			self.clear_breakpoints_highlighting()
			return


		frame.f_locals['__return__'] = return_value

		self.pause_debug = False
		self.wait_in_debug(frame)

	def user_exception(self, frame, (exc_type, exc_value, exc_traceback)):
		"""Called if an exception occurs, but only if we are to stop at or just below this level."""
		if (self.quitting):
			return

		frame.f_locals['__exception__'] = exc_type, exc_value

		if (type(exc_type) == type('')):
			exc_type_name = exc_type
		else:
			exc_type_name = exc_type.__name__

		if (self.is_exit_frame(frame)):
			# It's the last frame.
			self.print_message(self.MESSAGE_PROGRAM_ENDED)
			self.clear_current_line_highlighting()
			self.clear_breakpoints_highlighting()
			return

		self.print_message("%s: %s" % (exc_type_name, exc_value))

		self.wait_in_debug(frame)


	#
	# Methods to be overridden by the editor-specific child class.
	#



	def print_message(self, message):
		"""Prints a message to the editor console"""
		raise NotImplementedError()

	def set_cursor_position(self, row, column):
		"""Sets the cursor position for the current editor window."""
		raise NotImplementedError()

	def highlight_breakpoints(self, filename, regular_breakpoints, conditional_breakpoints, temporary_breakpoints):
		"""Highlights the active breakpoints in the given file."""
		raise NotImplementedError()

	def highlight_current_line(self, filename, line):
		"""Highlights the current debugged line."""
		raise NotImplementedError()

	def clear_current_line_highlighting(self):
		"""Clears the highlighting of the current debugged line."""
		raise NotImplementedError()

	def clear_breakpoints_highlighting(self):
		"""Clears the highlighting for the breakpoints."""
		raise NotImplementedError()

	def open_file(self, filename):
		"""Opens a file for editing."""
		raise NotImplementedError()

	def get_active_filename(self):
		"""Returns the filename of the active window."""
		raise NotImplementedError()


class VimPdb(PdbIDE):
	"""Integrates the Pdb IDE into Vim."""

	#
	# Constants
	#


	# The Vim group name used for highlighting the currently debugged line.
	CURRENT_LINE_GROUP = 'PdbCurrentLineTemp'
	USER_DEFINED_CURRENT_LINE_GROUP = 'PdbCurrentLine'
	# The Vim group name used for highlighting the breakpoint line.
	BREAKPOINT_GROUP = 'PdbBreakpoint'
	# The Vim group name used for highlighting the conditional breakpoint line.
	CONDITIONAL_BREAKPOINT_GROUP = 'PdbConditionalBreakpoint'
	# The Vim group name used for highlighting the temporary breakpoint line.
	TEMPORARY_BREAKPOINT_GROUP = 'PdbTemporaryBreakpoint'



	def __init__(self):
		# Initialize the parent PdbIDE class.
		PdbIDE.__init__(self)

		# The output buffer used when print_message() is called.
		self.output_buffer = None
		self.save_to_output_buffer = False


	#
	# Overridden methods, which implement the editor-specific functionalities.
	#


	def print_message(self, message):
		"""Prints a message to the Vim console."""
		if (self.save_to_output_buffer):
			self.output_buffer = message
		else:
			print message

	def set_cursor_position(self, row, column):
		"""Sets the cursor position for the current Vim buffer."""
		# Move to the right line.
		self.normal_command('%dG' % (row))
		# Move to the right column.
		self.normal_command('0%dl' % (column))
	
	def highlight_breakpoints(self, filename, regular_breakpoints, conditional_breakpoints, temporary_breakpoints):
		"""Highlights the active breakpoints in the given file."""
		self.clear_breakpoints_highlighting()

		self._set_lines_highlighting(regular_breakpoints, self.BREAKPOINT_GROUP)
		self._set_lines_highlighting(conditional_breakpoints, self.CONDITIONAL_BREAKPOINT_GROUP)
		self._set_lines_highlighting(temporary_breakpoints, self.TEMPORARY_BREAKPOINT_GROUP)


	def highlight_current_line(self, filename, line):
		"""Highlights the current debugged line."""

		if (self.canonic(vim.current.buffer.name) != filename):
			# Current buffer isn't the last debugged filename.
			return

		self.command(r'highlight link %s %s' % (self.CURRENT_LINE_GROUP, self.USER_DEFINED_CURRENT_LINE_GROUP))
		self.command(r'match %s "\%%%dl.\+"' % (self.CURRENT_LINE_GROUP, line))

	def clear_current_line_highlighting(self):
		"""Clears the highlighting of the current debugged line."""

		self.command(r'highlight link %s NONE' % (self.CURRENT_LINE_GROUP))
	

	def clear_breakpoints_highlighting(self):
		"""Clears the highlighting for the breakpoints."""

		self.command(r'syntax clear %s' % (self.BREAKPOINT_GROUP))
		self.command(r'syntax clear %s' % (self.CONDITIONAL_BREAKPOINT_GROUP))
		self.command(r'syntax clear %s' % (self.TEMPORARY_BREAKPOINT_GROUP))


	def open_file(self, filename):
		"""Opens a file for editing."""

		if (self.canonic(vim.current.buffer.name) != filename):
			vim_filename = filename.replace(' ', r'\ ')
			self.command('e ' + filename)

	def get_active_filename(self):
		"""Returns the filename of the active buffer."""
		return vim.current.buffer.name.replace(r'\ ', ' ')


	def set_cursor_to_current_line(self):
		"""Moves the cursor to the current debugged line."""

		self.open_file(self.current_filename)
		self.set_cursor_position(self.current_line, 0)

	

	#
	# Queue related methods
	#


	def run_method(self, function_name, *parameters):
		"""Runs a method (using add_queued_method) and waits for its output; then prints it onto the screen."""

		self.output_buffer = None
		self.save_to_output_buffer = True
		self.add_queued_method(function_name, *parameters)

		while (self.output_buffer == None):
			time.sleep(self.PAUSE_DEBUG_WAIT_TIME)

		self.save_to_output_buffer = False
		self.print_message(self.output_buffer)

	def run_method_and_return_output(self, function_name, *parameters):
		"""Runs a method (using add_queued_method) and waits for it to finish running;
		then returns its return value."""

		self.save_to_output_buffer = False
		self.last_method_return_value = None
		self.add_queued_method(function_name, *parameters)

		while (self.last_method_return_value == None):
			time.sleep(self.PAUSE_DEBUG_WAIT_TIME)

		return self.last_method_return_value



	#
	# Helper methods
	#


	def normal_command(self, command):
		"""Runs a command in normal mode."""
		self.command('normal ' + command)

	def command(self, command):
		"""Runs a Vim (ex-mode) command"""
		vim.command(command)


	def _set_lines_highlighting(self, line_numbers, group_name):
		"""Sets highlighting for a group of line numbers (given a group name)."""

		for line_number in line_numbers:
			self.command(r'syntax match %s "\%%%dl.\+"' % (group_name, line_number))

		# Old method - doesn't work for line #1, and when the previous line ends with a quotation mark
		# of the end of a string, for example.

		# Highlight each group of lines.
		#for line_range in line_ranges:
		#	self.command(r'syntax region %s start="\%%%dl$" end="\%%%dl.\+"' %
		#			(group_name, line_range['start'] - 1, line_range['end']))

