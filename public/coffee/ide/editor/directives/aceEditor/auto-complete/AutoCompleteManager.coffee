define [
	"ide/editor/directives/aceEditor/auto-complete/SuggestionManager"
	"ide/editor/directives/aceEditor/auto-complete/Snippets"
	"ace/ace"
	"ace/ext-language_tools"
], (SuggestionManager, Snippets) ->
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

			# HACK: modified ace Autocomplete completer, with a less-bad changeTimer
			#   necessary to ensure autocomplete works consistently, even if many characters
			#   are typed within the timeout window.
			ac = ace.require('ace/autocomplete')
			lang = ace.require('ace/lib/lang')
			patched_completer = new ac.Autocomplete()
			patched_completer.changeTimer = lang.delayedCall(
				(() -> this.updateCompletions()).bind(patched_completer) # NOTE: not passing `true` to updateCompletions
			)
			@editor.completer = patched_completer
			# /HACK

			console.log "ENABLE auto complete"

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
			}

			@editor.completers = [@suggestionManager]

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
					# console.log ">> onChange: #{lineUpToCursor} - #{commandFragment}"

					if commandFragment? and commandFragment.length > 2
						setTimeout () =>
							@editor.execCommand("startAutocomplete")
						, 0

					# fire autocomplete if line ends in `some_identifier.`
					if lineUpToCursor.match(/(\w+)\.$/)
						setTimeout () =>
							@editor.execCommand("startAutocomplete")
						, 0
					window._e = @editor
