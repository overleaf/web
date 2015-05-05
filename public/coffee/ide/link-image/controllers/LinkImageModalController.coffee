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
			request = $http.post "/project/#{ide.$scope.project_id}/link", {
				path: $scope.inputs.path
				_csrf: window.csrfToken
			}
			request.success (data, status, headers, config) ->
				console.log "success", data, status, headers, config
				$scope.generating = false
				$scope.output.url = data?.link
				$scope.$broadcast "generate-link-done"
			request.error  (data, status, headers, config) ->
				console.log "error", data, status, headers, config
				$scope.generating = false
				$scope.error = true
