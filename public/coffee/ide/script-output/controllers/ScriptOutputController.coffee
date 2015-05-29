define [
	"base"
], (App) ->
	App.controller "ScriptOutputController", ($scope, $http, ide, jupyterRunner, event_tracking, localStorage) ->
		$scope.status = jupyterRunner.status
		$scope.cells = jupyterRunner.CELL_LIST
		
		ide.$scope.$watch "editor.ace_mode", () ->
			$scope.engine = ide.$scope.editor.ace_mode
		
		$scope.$on "editor:recompile", () ->
			$scope.runSelection()
		
		$scope.runSelection = () ->
			ide.$scope.$broadcast("editor:gotoNextLine")
			code   = ide.$scope.editor.selection.lines.join("\n")
			engine = $scope.engine
			jupyterRunner.executeRequest code, engine
		
		$scope.runAll = () ->
			engine = $scope.engine
			path = ide.fileTreeManager.getEntityPath(ide.$scope.editor.open_doc)
			if engine == "python"
				code = "%run #{path}"
				jupyterRunner.executeRequest code, engine
			else if engine == "r"
				code = "source('#{path}')"
				jupyterRunner.executeRequest code, engine
			else
				throw new Error("not implemented yet")
		
		$scope.manualInput = ""
		$scope.runManualInput = () ->
			code   = $scope.manualInput
			engine = $scope.engine
			jupyterRunner.executeRequest code, engine
			$scope.manualInput = ""
		
		$scope.stop = () ->
			jupyterRunner.stop()
		
		$scope.restart = () ->
			jupyterRunner.shutdown($scope.engine)
		
		$scope.installPackage = (packageName, language) ->
			ide.$scope.$broadcast "installPackage", packageName, language
		
		$scope.showFormat = (message, format) ->
			message.content.format = format
			localStorage("preferred_format", format)
