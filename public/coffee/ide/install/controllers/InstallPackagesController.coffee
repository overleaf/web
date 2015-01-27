define [
	"base"
], (App, LogParser) ->
	App.controller "InstallPackagesController", ($scope, $modal) ->
		$scope.openInstallPackagesModal = () ->
			$modal.open {
				templateUrl: "installPackagesModalTemplate"
				size: "lg"
			}
			