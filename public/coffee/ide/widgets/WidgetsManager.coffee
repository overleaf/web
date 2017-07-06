define [
	"ide/widgets/controllers/WidgetsController"
], () ->
	class WidgetsManager
		constructor: (@ide, @$scope) ->
			@$scope.widgets =
				context: {}
