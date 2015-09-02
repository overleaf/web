define [
	"base"
], (App) ->
	App.controller "BinaryFileController", ["$scope", ($scope) ->
		$scope.extension = extension = (file) ->
			return file.name.split(".").pop()?.toLowerCase()
		$scope.isImage = (file) ->
			return ['png', 'jpg', 'jpeg', 'gif'].indexOf(extension(file)) > -1
		$scope.isVectorWithPreview = (file) ->
			# only binary files stored in mongo have previews, not output
			# file on clsi
			return !file.url? && ['pdf', 'eps'].indexOf(extension(file)) > -1
		$scope.isCsvWithPreview = (file) ->
			return !file.url? && ['csv'].indexOf(extension(file)) > -1
	]

	App.controller "CsvPreviewController", ['$scope', '$http', ($scope, $http) ->
		$scope.state =
			preview: null
			message: 'Generating preview...'

		$scope.file_id = $scope.$parent.openFile.id

		$scope.getPreview = () =>
			$http.get("/project/#{$scope.project_id}/file/#{$scope.file_id}/preview/csv")
				.success (data) ->
					console.log ">> success"
					$scope.state.preview = data
				.error () ->
					console.log ">> failure"
					$scope.state.message = 'No preview available.'
					$scope.state.preview = null

		$scope.getPreview()
	]
