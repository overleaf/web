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
