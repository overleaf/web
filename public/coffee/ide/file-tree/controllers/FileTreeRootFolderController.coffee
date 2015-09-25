define [
	"base"
], (App) ->
	App.controller "FileTreeRootFolderController", ["$scope", "ide", "$http", "$rootScope", ($scope, ide, $http, $rootScope) ->
		rootFolder = $scope.rootFolder

		loadOutputFiles = () ->
			$http.get "/project/#{$scope.project_id}/output"
				.success (files) ->
					$rootScope.$broadcast 'updateOutputFiles', files.outputFiles

		$scope.$on 'reload-output-files', () ->
			loadOutputFiles()

		$scope.$on 'project:joined', () ->
			loadOutputFiles()

		loadOutputFiles()

		$scope.onDrop = (events, ui) ->
			source = $(ui.draggable).scope().entity
			return if !source?
			ide.fileTreeManager.moveEntity(source, rootFolder)
	]
