define [
	"base"
], (App) ->
	App.controller "ScriptOutputController", ($scope, $http, ide, $anchorScroll, $location, commandRunner, event_tracking) ->
		reset = () ->
			$scope.files = []
			$scope.output = []
			$scope.running = false
			$scope.error = false
			$scope.timedout = false
			$scope.session_id = Math.random().toString().slice(2)
			$scope.stillIniting = false
			$scope.inited = false
			$scope.stopping = false
		reset()
			
		$scope.uncompiled = true
		
		$scope.$on "editor:recompile", () ->
			$scope.run()

		run_count = 0
		$scope.run = () ->
			return if $scope.currentRun?.running
			
			run_count++
			if run_count == 1
				event_tracking.send("script", "run")
			else if run_count == 5
				event_tracking.send("script", "multiple-run")
			
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
		
		$scope.installPackage = (packageName, language) ->
			ide.$scope.$broadcast "installPackage", packageName, language
