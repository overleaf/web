define [
	"ide/binary-files/controllers/BinaryFileController"
], () ->
	class BinaryFilesManager
		constructor: (@ide, @$scope) ->
			@$scope.$on "entity:selected", (event, entity) =>
				if (@$scope.ui.view != "track-changes" and entity.type in ["file", "output"])
					@openFile(entity)

		openFile: (file) ->
			@$scope.ui.view = "file"
			@$scope.openFile = file
			@$scope.$broadcast 'binary-file:opened', file
