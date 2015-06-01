define [
	"base"
], (App) ->
	App.controller "LinkImageModalController", ($scope, $modalInstance, $timeout, $http, ide) ->
		$modalInstance.opened.then () ->
			$timeout () ->
				$scope.$broadcast "open"
			, 200

		$scope.generateLink = () ->
			return if $scope.inputs.path == ""
			$scope.generating = true
			delete $scope.error
			options = {
				path: $scope.inputs.path
				_csrf: window.csrfToken
			}
			if $scope.inputs.base64
				options.base64 = $scope.inputs.data
			else
				options.data = $scope.inputs.data.toString() # for SVG need to convert $sce untrusted value to string
			request = $http.post "/project/#{ide.$scope.project_id}/link", options
			request.success (data, status, headers, config) ->
				$scope.generating = false
				$scope.output.url ?= {}
				$scope.output.url[$scope.format] = data?.link
				$scope.$broadcast "generate-link-done"
			request.error  (data, status, headers, config) ->
				$scope.generating = false
				$scope.error = true
