define [
	"base"
], (App) ->
	App.directive 'intercom', () ->
		return (scope, element, attrs) ->
			element.bind "click", (event) ->
				Intercom?("showNewMessage")