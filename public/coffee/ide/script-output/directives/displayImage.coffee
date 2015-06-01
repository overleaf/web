define [
	"base"
], (
	App
) ->
	App.directive "displayImage", () ->
		return {
			restrict: 'E'
			scope: {
				"format": "=format"
				"data": "=data"
			}
			template: """
				<img class="image" ng-if="format == 'image/png'" ng-src="data:image/png;base64,{{data['image/png']}}" download="output.png">
				<img class="image" ng-if="format == 'image/jpeg'" ng-src="data:image/jpeg;base64,{{data['image/jpeg']}}" download="output.jpeg">
				<span class="image" ng-if="format == 'image/svg+xml'" ng-bind-html="data['image/svg+xml']"></span>
				<div class="iframe-wrapper" ng-if="format == 'application/pdf'"><iframe ng-src="{{data['application/pdf+url']}}" download="output.pdf"></div>
			"""
		}
