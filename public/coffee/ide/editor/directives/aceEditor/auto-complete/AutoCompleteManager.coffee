define [
	"ide/editor/directives/aceEditor/auto-complete/SuggestionManager"
	"ide/editor/directives/aceEditor/auto-complete/CustomTextCompleter"
	"ide/editor/directives/aceEditor/auto-complete/KernelCompletionSpinner"
	"ide/editor/directives/aceEditor/auto-complete/Snippets"
	"ace/ace"
	"ace/ext-language_tools"
], (SuggestionManager, CustomTextCompleter, KernelCompletionSpinner, Snippets) ->
	Range = ace.require("ace/range").Range

	getLastCommandFragment = (lineUpToCursor) ->
		if m = lineUpToCursor.match(/(\\[^\\ ]+)$/)
			return m[1]
		else
			return null

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

		enable: () ->
			@editor.setOptions({
				enableBasicAutocompletion: true,
				enableSnippets: true,
				enableLiveAutocompletion: true
			})
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
						KernelCompletionSpinner.tryAttach(@$scope)
					, 1
			}

			CustomTextCompleter.init(@editor)
			@editor.completers.push @suggestionManager

			# Force the editor.completer into existence,
			# then override it's showPopup handler with our own
			setTimeout (editor) ->
				Autocomplete = ace.require('ace/autocomplete').Autocomplete
				if !editor.completer
					editor.completer = new Autocomplete()

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

					# or just continue to the original popup method
					_showPopup(editor)

			, 0, @editor

			window._e = @editor

		disable: () ->
			@editor.setOptions({
				enableBasicAutocompletion: false,
				enableSnippets: false
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
					commandFragment = getLastCommandFragment(lineUpToCursor)

					if commandFragment? and commandFragment.length > 2
						setTimeout () =>
							@editor.execCommand("startAutocomplete")
						, 0

					# fire autocomplete if line ends in `some_identifier.`
					if lineUpToCursor.match(/(\w+)\.$/)
						setTimeout () =>
							@editor.execCommand("startAutocomplete")
						, 0
			setTimeout =>
				KernelCompletionSpinner.tryAttach(@$scope)
			, 1
