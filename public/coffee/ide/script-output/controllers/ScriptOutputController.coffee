define [
	"base"
], (App) ->
	App.controller "ScriptOutputController", ($scope, $http, ide, $anchorScroll, $location, commandRunner, event_tracking) ->
		$scope.status = commandRunner.status
		$scope.cells = commandRunner.CELL_LIST
		$scope.uncompiled = true
		
		$scope.$on "editor:recompile", () ->
			$scope.runSelection()
		
		$scope.runSelection = () ->
			$scope.uncompiled = false
			code   = ide.$scope.editor.selection.lines.join("\n")
			engine = ide.$scope.editor.ace_mode
			commandRunner.executeRequest code, engine
		
		$scope.manualInput = ""
		$scope.runManualInput = () ->
			$scope.uncompiled = false
			code   = $scope.manualInput
			engine = ide.$scope.editor.ace_mode
			commandRunner.executeRequest code, engine
			$scope.manualInput = ""
		
		$scope.stop = () ->
			commandRunner.stop()
		
		$scope.installPackage = (packageName, language) ->
			ide.$scope.$broadcast "installPackage", packageName, language
