define [
	"base"
], (App) ->
	App.controller "WidgetsController", ($scope) ->
		$scope.$watch "widgets.context", (context) =>
			if context?.mathMode
				$scope.widgets.math = context.mathMode.content
			else
				$scope.widgets.math = null