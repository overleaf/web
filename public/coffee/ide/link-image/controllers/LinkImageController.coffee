define [
	"base"
], (App) ->
	App.controller "LinkImageController", ($scope, $modal) ->
		# Keep the scope here rather than in the modal so that we can restore
		# the modal to it's previous state when we reopen it.
		$scope.inputs =
			url: ""
		$scope.output = {}
		
		console.log "LINK IMAGE", $scope, $scope.output

		$scope.linkImage = (url, path, data) ->
			$scope.inputs.path = path
			$scope.inputs.url = url
			$scope.inputs.data = data
			$modal.open {
				templateUrl: "linkImageModalTemplate"
				controller: "LinkImageModalController"
				size: "lg"
				scope: $scope
			}
