define [], () ->

	ENTER = 13
	UP    = 38
	DOWN  = 40
	TAB   = 9
	END   = -1

	class CommandLineEditor

		@init: (scope, editor, rootElement, getValue, setValue, onRun) ->
			commandLine = new CommandLineEditor(scope, editor, rootElement, getValue, setValue, onRun)
			editor._dj_commandLine = commandLine

		constructor: (@scope, @editor, @rootElement, @getValueFn, @setValueFn, @onRunFn) ->
			@history = []
			@cursor = END
			@pendingCommand = ""

			editor.setOption('showLineNumbers', false)
			editor.setOption('showGutter', false)
			editor.setOption('maxLines', 20)
			editor.setOption('highlightActiveLine', false)
			editor.on 'change', () ->
				editor.resize()

			# set up a placeholder text
			# watch for changes to the editor, if the text is empty,
			# add a div with the placeholder text, otherwise remove it
			_updatePlaceholder = () ->
				shouldShow = editor.getValue().length == 0
				existingMessage = editor.renderer.emptyMessageNode
				if (!shouldShow and existingMessage)
					editor.renderer.scroller.removeChild(existingMessage)
					editor.renderer.emptyMessageNode = null
				else if (shouldShow and !existingMessage)
					newMessage = editor.renderer.emptyMessageNode = document.createElement("div")
					newMessage.textContent = 'Command...'
					newMessage.className = 'ace_invisible ace_emptyMessage'
					newMessage.style.padding = "0 8px"
					editor.renderer.scroller.appendChild(newMessage)
			editor.on('input', _updatePlaceholder)
			setTimeout(_updatePlaceholder, 0)

			# patch the up/down navigation in the editor
			# to do history instead
			_navigateDown = editor.navigateDown.bind(editor)
			_navigateUp = editor.navigateUp.bind(editor)

			editor.navigateUp = (times) =>
				if @cursor == END and @history.length > 0
					@savePendingCommand()
					@moveToHistoryEntry(@history.length - 1)
				else if @cursor > 0
					@moveToHistoryEntry(@cursor - 1)
				else
					_navigateUp(times)

			editor.navigateDown = (times) =>
				if @cursor != END and @cursor < @history.length - 1
					@moveToHistoryEntry(@cursor + 1)
				else if @cursor == @history.length - 1
					@moveToHistoryEntry(END)
				else
					_navigateDown(times)

			rootElement.bind "keydown", (event) =>
				@handleKeyDown(event)

			# give the wrapper a glow on focus
			# and show/hide the intercom button
			editorWrapper = rootElement.find('.ace-editor-wrapper')
			editor.on 'focus', () =>
				@scope.$parent.showInterCom(false)
				editorWrapper.addClass('highlight-glow')
			editor.on 'blur', () =>
				@scope.$parent.showInterCom(true)
				editorWrapper.removeClass('highlight-glow')

		handleKeyDown: (event) ->
			if event.which == ENTER and not event.shiftKey
				event.preventDefault()
				@runCommand()

		savePendingCommand: () ->
			@pendingCommand = @getValueFn()

		moveToHistoryEntry: (index) ->
			@cursor = index
			if index == END
				@setValueFn(@pendingCommand)
			else
				@setValueFn(@history[index])
			@editor.clearSelection()

		runCommand: () ->
			@history.push @getValueFn()
			@cursor = END
			@onRunFn()
