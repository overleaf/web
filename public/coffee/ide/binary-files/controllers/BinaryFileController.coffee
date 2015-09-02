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

	App.controller "CsvPreviewController", ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->
		$scope.state =
			preview: null
			message: 'Generating preview...'

		$scope.file_id = $scope.$parent.openFile.id

		$scope.setHeight = () ->
			# Behold, a ghastly hack
			guide = document.querySelector('.file-tree-inner')
			table_wrap = document.querySelector('.scroll-container')
			desired_height = guide.offsetHeight - 50
			if table_wrap.offsetHeight > desired_height
				table_wrap.style.height = desired_height + 'px'
				table_wrap.style['max-height'] = desired_height + 'px'


		$scope.getPreview = () =>
			$http.get("/project/#{$scope.project_id}/file/#{$scope.file_id}/preview/csv")
				.success (data) ->
					console.log ">> success"
					$scope.state.preview = data
					$timeout($scope.setHeight, 0)
				.error () ->
					console.log ">> failure"
					$scope.state.message = 'No preview available.'
					$scope.state.preview = null

		$scope.getPreview()
	]
