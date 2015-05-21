define [
	"base"
], (App) ->
	App.controller "ScriptOutputController", ($scope, $http, ide, commandRunner, event_tracking) ->
		$scope.status = commandRunner.status
		$scope.cells = commandRunner.CELL_LIST
		
		ide.$scope.$watch "editor.ace_mode", () ->
			$scope.engine = ide.$scope.editor.ace_mode
		
		$scope.$on "editor:recompile", () ->
			$scope.runSelection()
		
		$scope.runSelection = () ->
			code   = ide.$scope.editor.selection.lines.join("\n")
			engine = $scope.engine
			commandRunner.executeRequest code, engine
		
		$scope.runAll = () ->
			engine = $scope.engine
			path = ide.fileTreeManager.getEntityPath(ide.$scope.editor.open_doc)
			if engine == "python"
				code = "%run #{path}"
				commandRunner.executeRequest code, engine
			else if engine == "r"
				code = "source('#{path}')"
				commandRunner.executeRequest code, engine
			else
				throw new Error("not implemented yet")
		
		$scope.manualInput = ""
		$scope.runManualInput = () ->
			code   = $scope.manualInput
			engine = $scope.engine
			commandRunner.executeRequest code, engine
			$scope.manualInput = ""
		
		$scope.stop = () ->
			commandRunner.stop()
		
		$scope.restart = () ->
			commandRunner.shutdown($scope.engine)
		
		$scope.installPackage = (packageName, language) ->
			ide.$scope.$broadcast "installPackage", packageName, language
