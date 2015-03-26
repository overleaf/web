define [
	"base"
], (App) ->
	App.controller "InstallPackagesController", ($scope, $modal) ->
		# Keep the scope here rather than in the modal so that we can restore
		# the modal to it's previous state when we reopen it.
		$scope.inputs =
			packageName: ""
			installer: "conda"
		
		$scope.selectedTab =
			python: true
			R: false
		
		$scope.output = {}
	
		$scope.openInstallPackagesModal = () ->
			$modal.open {
				templateUrl: "installPackagesModalTemplate"
				controller: "InstallPackagesModalController"
				size: "lg"
				scope: $scope
			}
