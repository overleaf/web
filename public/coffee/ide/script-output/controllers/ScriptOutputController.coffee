define [
	"base"
], (App) ->
	App.controller "ScriptOutputController", ($scope, $http, ide, $anchorScroll, $location, commandRunner) ->
		$scope.needToUpgrade = ($scope.project.features.compileTimeout == 0)
		$scope.uncompiled = true
		
		$scope.$on "editor:recompile", () ->
			$scope.run()

		$scope.run = () ->
			return if $scope.currentRun?.running
			return if $scope.needToUpgrade
			
			$scope.uncompiled = false
			
			compiler = "python"
			extension = $scope.editor.open_doc.name.split(".").pop()?.toLowerCase()
			if extension == "r"
				compiler = "r"
			rootDoc_id = $scope.editor.open_doc_id

			$scope.currentRun = commandRunner.run {rootDoc_id, compiler}
		
		$scope.stop = () ->
			return if !$scope.currentRun?
			commandRunner.stop $scope.currentRun
