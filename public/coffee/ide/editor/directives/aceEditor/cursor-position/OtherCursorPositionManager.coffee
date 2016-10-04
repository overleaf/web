define [
	"ide/editor/directives/aceEditor/markers/MarkerManager"
], (MarkerManager) ->
	class OtherCursorPositionManager
		constructor: (@$scope, @editor, @element) ->
			@markerManager = new MarkerManager(@editor, enableLabels: true)

			@$scope.$watch "otherCursorMarkers", (markers) =>
				return if !markers?
				@markerManager.removeAllMarkers()
				for marker in markers
					@markerManager.addMarker(marker)