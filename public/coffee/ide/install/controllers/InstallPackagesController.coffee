define [
	"base"
], (App) ->
	App.controller "InstallPackagesController", ($scope, $modal) ->
		# Keep the scope here rather than in the modal so that we can restore
		# the modal to it's previous state when we reopen it.
		$scope.inputs =
			packageName: ""
			pythonInstaller: "conda"
			rInstaller: "apt-get"
		
		$scope.selectedTab =
			python: true
			R: false
		
		$scope.output = {}
	
		$scope.openInstallPackagesModal = (autoStart) ->
			$scope.autoStart = !!autoStart
			$modal.open {
				templateUrl: "installPackagesModalTemplate"
				controller: "InstallPackagesModalController"
				size: "lg"
				scope: $scope
			}
		
		$scope.$on "installPackage", (e, packageName, language) ->
			$scope.inputs.packageName = packageName
			if language == "python"
				$scope.selectedTab.python = true
				$scope.selectedTab.R = false
			else if language == "R"
				$scope.selectedTab.python = false
				$scope.selectedTab.R = true
			$scope.openInstallPackagesModal(true)