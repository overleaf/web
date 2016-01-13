define [
	"base"
], (App) ->
	App.controller "FreeTrialController", ($scope, $http) ->
		$scope.userInfoForm =
			first_name: ""
			institution: ""
			class_size: ""
		$scope.status =
			inflight: false
			error: false
		
		$scope.submit = () ->
			console.log "Updating user details"
			$scope.status.inflight = true
			$scope.status.error = false
			$http
				.post "/user/settings", {
					_csrf: window.csrfToken,
					first_name: $scope.userInfoForm.first_name
					institution: $scope.userInfoForm.institution
					class_size: $scope.userInfoForm.class_size
				}
				.success () ->
					$http
						.post "/user/subscription/free_trial", {
							_csrf: window.csrfToken,
							planCode: "teacher"
						}
						.success () ->
							window.location = "/project"
						.error () ->
							$scope.status.inflight = false
							$scope.status.error = true
				.error () ->
					$scope.status.inflight = false
					$scope.status.error = true
