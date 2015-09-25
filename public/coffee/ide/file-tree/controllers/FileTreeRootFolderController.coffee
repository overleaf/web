define [
	"base"
], (App) ->
	App.controller "FileTreeRootFolderController", ["$scope", "ide", "$http", ($scope, ide, $http) ->
		rootFolder = $scope.rootFolder

		# loadOutputFiles = () ->
		# 	$http.get "/project/#{$scope.project_id}/output"
		# 		.success (files) ->
		# 			console.log $scope.loadOutputFiles
		# 			$scope.project.outputFiles = files?.outputFiles

		# $scope.$on 'reload-output-files', () ->
		# 	loadOutputFiles()

		# loadOutputFiles()

		$scope.onDrop = (events, ui) ->
			source = $(ui.draggable).scope().entity
			return if !source?
			ide.fileTreeManager.moveEntity(source, rootFolder)
	]
