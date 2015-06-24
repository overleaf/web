define [
	"base"
], (App) ->
	App.controller "InstallPackagesModalController", ($scope, $modalInstance, $timeout, commandRunner, event_tracking) ->
		$modalInstance.opened.then () ->
			$timeout () ->
				$scope.$broadcast "open"
			, 200
		
		$scope.install = (autoStart) ->
			return if $scope.inputs.packageName == ""
			$scope.installedPackage = $scope.inputs.packageName
			
			event_tracking.send("package", "install", {
				name: $scope.installedPackage
			})

			# Don't clear the name on autostart so it's still clear what is going on.
			if !autoStart
				$scope.inputs.packageName = ""

			options = {}
			if $scope.selectedTab.python
				if $scope.inputs.pythonInstaller == "conda"
					options = {
						compiler: "command"
						command: [
							"sudo", "conda", "install", "--yes", "--quiet", $scope.installedPackage
						]
					}
				else if $scope.inputs.pythonInstaller == "pip"
					options = {
						compiler: "command"
						command: [
							"sudo", "pip", "install", $scope.installedPackage
						]
						env: {
							HOME: "/usr/local"
						}
					}
				else
					console.error "Unknown python installer: ", $scope.inputs.pythonInstaller
					return
			else if $scope.selectedTab.R
				if $scope.inputs.rInstaller == "install.packages"
					options = {
						compiler: "command"
						command: [
							"sudo", "Rscript", "-e", "install.packages('#{$scope.installedPackage}')"
						]
					}
				else if $scope.inputs.rInstaller == "apt-get"
					options = {
						compiler: "apt-get-install"
						package: "r-cran-#{$scope.installedPackage.toLowerCase()}"
						env: {
							DEBIAN_FRONTEND: "noninteractive"
						}
					}
				else if $scope.inputs.rInstaller == "git"
					options = {
						compiler: "command"
						command: [
							"sudo", "Rscript", "-e", "library(devtools); install_github('#{$scope.installedPackage}')"
						]
					}
				else
					console.error "Unknown R installer: ", $scope.inputs.rInstaller
					return
			else
				console.error "Unknown tab!", $scope.selectedTab
				return

			options.timeout = 360
			options.parseErrors = false

			$scope.output.currentRun = commandRunner.run options

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
