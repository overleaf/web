define [
	"base"
], (App) ->
	App.controller "ScriptOutputController", ($scope, $http, ide, jupyterRunner, event_tracking, localStorage) ->
		$scope.status = jupyterRunner.status
		$scope.cells = jupyterRunner.CELL_LIST
		
		ide.$scope.$watch "editor.ace_mode", () ->
			$scope.engine = ide.$scope.editor.ace_mode
		
		$scope.$on "editor:run-line", () ->
			$scope.runSelection()
		
		$scope.$on "editor:run-all", () ->
			$scope.runAll()
		
		run_count = 0
		trackRun = () ->
			run_count++
			if run_count == 1
				event_tracking.send("script", "run")
			else if run_count == 5
				event_tracking.send("script", "multiple-run")
		
		$scope.runSelection = () ->
			ide.$scope.$broadcast("flush-changes")
			trackRun()
			ide.$scope.$broadcast("editor:gotoNextLine")
			code   = ide.$scope.editor.selection.lines.join("\n")
			engine = $scope.engine
			jupyterRunner.executeRequest code, engine
		
		$scope.runAll = () ->
			ide.$scope.$broadcast("flush-changes")
			trackRun()
			engine = $scope.engine
			path = ide.fileTreeManager.getEntityPath(ide.$scope.editor.open_doc)
			if engine == "python"
				code = "%run #{path}"
				jupyterRunner.executeRequest code, engine
			else if engine == "r"
				code = "source('#{path}', print.eval=TRUE)"
				jupyterRunner.executeRequest code, engine
			else
				throw new Error("not implemented yet")

		$scope.manualInput = ""
		$scope.runManualInput = () ->
			code   = $scope.manualInput
			engine = $scope.engine
			jupyterRunner.executeRequest code, engine
			$scope._scrollOutput()
			$scope.manualInput = ""

		$scope._scrollOutput = () ->
			try
				container = document.querySelector('.jupyter-output-inner')
				container.scrollTop = container.scrollHeight
			catch error
				console.log error

		$scope.stop = () ->
			jupyterRunner.stop()
		
		$scope.restart = () ->
			jupyterRunner.shutdown($scope.engine)
		
		$scope.installPackage = (packageName, language) ->
			ide.$scope.$broadcast "installPackage", packageName, language
		
		$scope.showFormat = (message, format) ->
			message.content.format = format
			localStorage("preferred_format", format)
