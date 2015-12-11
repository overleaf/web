define [
	"ide/editor/directives/aceEditor/auto-complete/SuggestionManager"
	"ide/editor/directives/aceEditor/auto-complete/CustomTextCompleter"
	"ide/editor/directives/aceEditor/auto-complete/KernelCompletionSpinner"
	"ace/ace"
	"ace/ext-language_tools"
], (SuggestionManager, CustomTextCompleter, KernelCompletionSpinner) ->
	Range = ace.require("ace/range").Range

	# Here we force the editor.completer into existence, which usually doesn't get instantiated
	# until it's first used.
	# We then monkey-patch it's showPopup handler with our own, so we can interupt the popup if
	# we know it should not be shown, such as if the cursor is in a comment, or inside a string
	monkeyPatchAutocomplete = (editor) ->
		Autocomplete = ace.require('ace/autocomplete').Autocomplete
		if !editor.completer
			editor.completer = new Autocomplete()

		# keep a reference to the old showPopup, and substitute it
		# with a wrapper function
		_showPopup = editor.completer.showPopup.bind(editor.completer)
		editor.completer.showPopup = (editor) ->
			pos = editor.getCursorPosition()
			current_line = editor.getSession().getLine(pos.row)
			line_to_cursor = current_line.slice(0, pos.column)

			# bail if we are in a comment
			return if line_to_cursor.indexOf('#') >= 0

			# bail if we have unbalanced quotes in this line
			single_quote_count = line_to_cursor.match(/'/g)?.length || 0
			double_quote_count = line_to_cursor.match(/"/g)?.length || 0
			return if (
				single_quote_count > 0 and single_quote_count % 2 == 1 or
				double_quote_count > 0 and double_quote_count % 2 == 1
			)

			# If we have no objections, just continue to the original popup method
			_showPopup(editor)

		return editor.completer

	class AutoCompleteManager
		constructor: (@$scope, @editor) ->
			@suggestionManager = new SuggestionManager()

			@$scope.$watch "autoComplete", (autocomplete) =>
				if autocomplete
					@enable()
				else
					@disable()

			onChange = (change) =>
				@onChange(change)

			@editor.on "changeSession", (e) =>
				e.oldSession.off "change", onChange
				e.session.on "change", onChange

			# HACK: the manual-input editor will never change session,
			# so explcitely add it's on-change handler
			if @editor._dj_name == 'manual_editor'
				@editor.on 'change', onChange

		enable: () ->
			@editor.setOptions({
				enableBasicAutocompletion: true,
				enableSnippets: true,
				enableLiveAutocompletion: false
			})

			# add our own tab handler, so we can trigger autocomplete
			# if we want
			@editor.commands.addCommand {
				name: 'tabComplete'
				bindKey: 'TAB'
				exec: (editor) =>
					pos = editor.getCursorPosition()
					current_line = editor.getSession().getLine(pos.row)
					line_to_cursor = current_line.slice(0, pos.column)
					line_beyond_cursor = current_line.slice(pos.column)
					if line_to_cursor.match(/(\w|\.)$/) and line_beyond_cursor == ''
						setTimeout () =>
							editor.execCommand("startAutocomplete")
						, 0
					else
						editor.indent()
					setTimeout =>
						KernelCompletionSpinner.tryAttach(@$scope, editor)
					, 1
			}

			# set up our completers
			CustomTextCompleter.init(@editor)
			existing_suggestion_manager = _.filter(@editor.completers, (c) -> c instanceof SuggestionManager)[0]
			if !existing_suggestion_manager
				console.log ">> setting suggestion manager"
				@editor.completers.push @suggestionManager

			# on the next tick, monkey-patch the autocompleter
			setTimeout (editor) ->
				monkeyPatchAutocomplete(editor)
			, 0, @editor

		disable: () ->
			@editor.setOptions({
				enableBasicAutocompletion: false,
				enableSnippets: false,
				enableLiveAutocompletion: false
			})

		onChange: (change) ->
			cursorPosition = @editor.getCursorPosition()
			end = change.end
			# Check that this change was made by us, not a collaborator
			# (Cursor is still one place behind)
			if end.row == cursorPosition.row and end.column == cursorPosition.column + 1
				if change.action == "insert"
					range = new Range(end.row, 0, end.row, end.column)
					lineUpToCursor = @editor.getSession().getTextRange(range)

					# fire autocomplete if line ends in a dot like: `some_identifier.`
					if lineUpToCursor.match(/(\w+)\.$/)
						setTimeout () =>
							@editor.execCommand("startAutocomplete")
						, 0
				setTimeout =>
					KernelCompletionSpinner.tryAttach(@$scope, @editor)
				, 1
