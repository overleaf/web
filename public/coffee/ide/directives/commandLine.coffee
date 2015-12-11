define [
	"base"
], (App) ->
	App.directive 'notcommandLine', () ->
		return {
			scope: {
				ngModel: "="
				onRun: "&"
			},
			link: (scope, element, attrs) ->
				window.history = history = []

				ENTER = 13
				UP = 38
				DOWN = 40

				END = -1
				cursor = END

				# If we scroll up into the history with a command not yet run,
				# save it so we can come back to it.
				pendingCommand = ""
				savePendingCommand = () ->
					pendingCommand = scope.ngModel

				setValue = (val) ->
					scope.$apply () ->
						scope.ngModel = val

				moveToHistoryEntry = (index) ->
					cursor = index
					if index == END
						setValue(pendingCommand)
					else
						setValue(history[index])

				runCommand = () ->
					history.push scope.ngModel
					cursor = END
					scope.onRun()

				element.bind "keydown", (event) ->
					if event.which == ENTER and not event.shiftKey
						event.preventDefault()
						runCommand()
					else if event.which == UP
						event.preventDefault()
						if cursor == END and history.length > 0
							savePendingCommand()
							moveToHistoryEntry(history.length - 1)
						else if cursor > 0
							moveToHistoryEntry(cursor - 1)
					else if event.which == DOWN
						event.preventDefault()
						if cursor != END and cursor < history.length - 1
							moveToHistoryEntry(cursor + 1)
						else if cursor == history.length - 1
							moveToHistoryEntry(END)
		}
