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
		
		$scope.manualInput = ""
		$scope.runManualInput = () ->
			code   = $scope.manualInput
			engine = $scope.engine
			commandRunner.executeRequest code, engine
			$scope.manualInput = ""
		
		$scope.stop = () ->
			commandRunner.stop()
		
		$scope.installPackage = (packageName, language) ->
			ide.$scope.$broadcast "installPackage", packageName, language
