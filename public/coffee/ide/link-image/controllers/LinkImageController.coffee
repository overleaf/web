define [
	"base"
], (App) ->
	App.controller "LinkImageController", ($scope, $modal) ->
		# Keep the scope here rather than in the modal so that we can restore
		# the modal to it's previous state when we reopen it.
		$scope.inputs =
			url: ""
		$scope.output = {}

		$scope.linkImage = (part) ->
			$scope.inputs.path = part.path
			$scope.inputs.url = part.url
			$modal.open {
				templateUrl: "linkImageModalTemplate"
				controller: "LinkImageModalController"
				size: "lg"
				scope: $scope
			}
