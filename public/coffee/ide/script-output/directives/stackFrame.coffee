define [
	"base"
	"ide/pdf/controllers/PdfController"
], (
	App
) ->
	App.directive "stackFrame", () ->
		return {
			restrict: 'E'
			controller: "PdfLogEntryController"  # for openInEditor function
			scope: {
				"error": "=error"
			}
			template: """{{error.message}} <span ng-if="error.file">at <a href="\#" ng-click="openInEditor(error)">{{error.file}}\#{{error.line}}</a></span>
			"""
		}
