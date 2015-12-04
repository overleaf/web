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

	stripUnwantedText =  (original_text) ->
		_.reduce(
			[
				/#(.*)$/m         # remove comments
				/('|").*\1/mg      # remove string contents
			]
			(text, re) -> text.replace(re, ' ')
			original_text
		)

	# this is mostly a replica of ace/autocomplete/text_completer,
	# except it ignores text within comments as best it can
	class CustomLocalCompleter
		splitRegex: /[^a-zA-Z_0-9\$\-\u00C0-\u1FFF\u2C00-\uD7FF\w]+/
		getWordIndex: (doc, pos) ->
			textBefore = doc.getTextRange(Range.fromPoints({row: 0, column:0}, pos))
			textBefore = stripUnwantedText(textBefore)
			return textBefore.split(@splitRegex).length - 1

		wordDistance: (doc, pos) ->
			prefixPos = @getWordIndex(doc, pos)
			words = stripUnwantedText(doc.getValue()).split(@splitRegex)
			wordScores = Object.create(null)

			currentWord = words[prefixPos]

			words.forEach((word, idx) ->
				if (!word || word == currentWord)
					return
				distance = Math.abs(prefixPos - idx)
				score = words.length - distance
				if (wordScores[word])
					wordScores[word] = Math.max(score, wordScores[word])
				else
					wordScores[word] = score;
			)
			return wordScores

		getCompletions: (editor, session, pos, prefix, callback) ->
			window._s = session
			wordScore = @wordDistance(session, pos, prefix)
			wordList = Object.keys(wordScore)
			callback(null, wordList.map((word) ->
					{
							caption: word,
							value: word,
							score: wordScore[word],
							meta: "local"
					}
			))

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
					setTimeout =>
						@_attachSpinner(@$scope)
					, 1
			}
			# find the completer responsible for the 'local' suggestions and replace it with ours
			local_index = null
			for completer, i in @editor.completers
				if completer.getCompletions.toString().indexOf('wordDistance(') >= 0
					local_index = i
					break
			if local_index
				@editor.completers.splice(local_index, 1, new CustomLocalCompleter())

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
					console.log line_to_cursor
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

		_attachSpinner: (scope) ->
			# early return if we've already got a spinner from a
			# previous run
			if scope._autocomplete_spinner
				return

			# get the autocomplete popup, if it exists in the page
			autocomplete = $('.ace_autocomplete')
			if autocomplete.length == 1
				# try to find the spinner (it may already exist)
				spinner = $('.dj_ace_autocomplete_spinner')[0]
				if !spinner
					# patch styles on the autocomplete popup
					ac = autocomplete[0]
					ac.style.position = 'relative'
					ac.style.overflow = 'visible'  # required to make the spinner visible

					# create the spinner elements
					inner = document.createElement('div')
					inner.classList.add('loading')
					inner.style.visibility = 'visible'
					for i in [1..3]
						dot = document.createElement('span')
						dot.textContent = '.'
						inner.appendChild(dot)
					spinner = document.createElement('div')
					spinner.classList.add('dj_ace_autocomplete_spinner')
					spinner.appendChild(inner)

					spinner.style.position = 'absolute'
					spinner.style.bottom = '-20px'
					spinner.style.left = '4px'

					# append the spinner to the autocomplete popup
					$(ac).append(spinner)

					# keep track of how many completion requests are in flight.
					# show/hide the spinner visuals as appropriate
					spinner._request_count = 0
					scope.$on 'completion_request:start', () ->
						spinner._request_count++
						if spinner._request_count > 0
							inner.style.visibility = 'visible'

					scope.$on 'completion_request:end', () ->
						spinner._request_count--
						if spinner._request_count <= 0
							inner.style.visibility = 'hidden'

				scope._autocomplete_spinner = spinner


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
			setTimeout =>
				@_attachSpinner(@$scope)
			, 1
