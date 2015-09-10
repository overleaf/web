define [
	"base"
], (App) ->
	App.controller "InputRequestController", ($scope, jupyterRunner) ->
		$scope.sentInput = false

		$scope.replyWithInput = (value) ->
			jupyterRunner.sendInput(value, $scope.engine)
			$scope.sentInput = true
		
		