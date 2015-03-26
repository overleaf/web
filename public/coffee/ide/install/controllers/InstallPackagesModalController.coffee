define [
	"base"
], (App) ->
	App.controller "InstallPackagesModalController", ($scope, $modalInstance, $timeout, commandRunner) ->
		$modalInstance.opened.then () ->
			$timeout () ->
				$scope.$broadcast "open"
			, 200
		
		$scope.install = (autoStart) ->
			return if $scope.inputs.packageName == ""
			$scope.installedPackage = $scope.inputs.packageName
			
			# Don't clear the name on autostart so it's still clear what is going on.
			if !autoStart
				$scope.inputs.packageName = ""

			env = {}
			if $scope.selectedTab.python
				if $scope.inputs.installer == "conda"
					command = [
						"sudo", "conda", "install", "--yes", "--quiet", $scope.installedPackage
					]
				else if $scope.inputs.installer == "pip"
					command = [
						"sudo", "pip", "install", $scope.installedPackage
					]
					env.HOME = "/usr/local"
				else
					console.error "Unknown installer: ", $scope.inputs.installer
					return
			else if $scope.selectedTab.R
				command = [
					"sudo", "Rscript", "-e", "install.packages('#{$scope.installedPackage}')"
				]
			else
				console.error "Unknown tab!", $scope.selectedTab
				return

			$scope.output.currentRun = commandRunner.run {
				compiler: "command",
				command: command
				env: env
			}
		
		if $scope.autoStart
			$scope.install(true)
	
		$scope.stop = () ->
			return if !$scope.output.currentRun?
			commandRunner.stop($scope.output.currentRun)
		
		$scope.help = () ->
			if $scope.installedPackage?
				message = "I'm having trouble installing the '#{$scope.installedPackage}' package."
			else
				message = "I'm having trouble installing a package. (please tell us which one!)"
			Intercom?('showNewMessage', message)
