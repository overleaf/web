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
			if ide.fileTreeManager.multiSelectedCount()
				entities = ide.fileTreeManager.getMultiSelectedEntityChildNodes() 
			else
				entities = [$(ui.draggable).scope().entity]
			for dropped_entity in entities
				ide.fileTreeManager.moveEntity(dropped_entity, rootFolder)
			$scope.$digest()
			# clear highlight explicitly
			$('.file-tree-inner .droppable-hover').removeClass('droppable-hover')
	]
