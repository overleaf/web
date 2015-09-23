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
		$scope.isTextWithPreview = (file) ->
			return !file.url? && (!$scope.isImage(file) && !$scope.isVectorWithPreview(file) && !$scope.isCsvWithPreview(file))

		$scope.isSmartPreview = (file) ->
			return $scope.isCsvWithPreview(file) or $scope.isTextWithPreview(file)
	]

	App.controller "SmartPreviewController", ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->
		$scope.state =
			preview: null
			message: 'Generating preview...'

		$scope.file = $scope.$parent.openFile
		$scope.file_id = $scope.file.id

		$scope.setHeight = () ->
			# Behold, a ghastly hack
			guide = document.querySelector('.file-tree-inner')
			table_wrap = document.querySelector('.scroll-container')
			desired_height = guide.offsetHeight - 48
			if table_wrap.offsetHeight > desired_height
				table_wrap.style.height = desired_height + 'px'
				table_wrap.style['max-height'] = desired_height + 'px'

		$scope.getPreview = () =>
			$http.get("/project/#{$scope.project_id}/file/#{$scope.file_id}/preview")
				.success (data) ->
					$scope.state.preview = data
					console.log data
					$timeout($scope.setHeight, 0)
				.error () ->
					$scope.state.message = 'No preview available.'
					$scope.state.preview = null

		$scope.getPreview()
	]
