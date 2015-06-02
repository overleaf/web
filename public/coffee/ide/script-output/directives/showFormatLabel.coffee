define [
	"base"
], (
	App
) ->
	App.directive "showFormatLabel", () ->
		return {
			restrict: 'E'
			scope: {
				"format": "=format"
			}
			link: (scope, element, attrs) ->
				description = {
					'application/pdf': 'PDF'
					'image/png': 'PNG'
					'image/jpeg': 'JPEG'
					'image/svg+xml': 'SVG'
				}
				scope.description = description[scope.format]
			template: """<span>{{description || format}}</span>"""
		}
