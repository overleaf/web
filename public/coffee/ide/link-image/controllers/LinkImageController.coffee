define [
	"base"
], (App) ->
	App.controller "LinkImageController", ($scope, $modal) ->
		# Keep the scope here rather than in the modal so that we can restore
		# the modal to it's previous state when we reopen it.
		$scope.inputs =
			url: ""
		$scope.output = {}

		$scope.linkImage = (url, path, data, content) ->
			# simplify the file extension for svg, jpeg
			path = path.replace(/\.svg\+xml$/, '.svg').replace(/\.jpeg$/, '.jpg')
			$scope.inputs.path = path
			$scope.inputs.url = url
			$scope.inputs.data = data
			$scope.inputs.content = content
			$scope.format = content.format
			if $scope.format in ['image/svg+xml']
				$scope.inputs.base64 = false
			else if $scope.format in ['application/pdf', 'image/png', 'image/jpeg']
				$scope.inputs.base64 = true
			else
				# unknown image format

			$modal.open {
				templateUrl: "linkImageModalTemplate"
				controller: "LinkImageModalController"
				size: "lg"
				scope: $scope
			}
