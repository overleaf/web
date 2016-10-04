define [
	"ace/ace"
	"ide/editor/directives/aceEditor/markers/MarkerManager"
], (_, MarkerManager) ->
	Range = ace.require("ace/range").Range

	class DiffManager
		constructor: (@$scope, @editor, @element) ->
			@markerManager = new MarkerManager(@editor, enableLabels: true)

			@$scope.$watch "diff", (diff) =>
				return if !diff? or !diff.text?
				@editor.setValue(diff.text, -1)
				session = @editor.getSession()
				session.setUseWrapMode(true)
				@markerManager.removeAllMarkers()
				for marker in diff.markers
					@markerManager.addMarker(marker)
				setTimeout () =>
					@updateShowMoreLabels()
					@scrollToFirstHighlight()
				, 10

			@$scope.updateLabels = {
				updatesAbove: 0
				updatesBelow: 0
			}

			onChangeScrollTop = () =>
				@updateShowMoreLabels()

			@editor.getSession().on "changeScrollTop", onChangeScrollTop
			@editor.on "changeSession", (e) =>
				e.oldSession?.off "changeScrollTop", onChangeScrollTop
				e.session.on "changeScrollTop", onChangeScrollTop

			@$scope.gotoHighlightBelow = () =>
				return if !@firstHiddenHighlightAfterRow?
				@editor.scrollToLine(@firstHiddenHighlightAfterRow, true, false)

			@$scope.gotoHighlightAbove = () =>
				return if !@lastHiddenHighlightBeforeRow?
				@editor.scrollToLine(@lastHiddenHighlightBeforeRow, true, false)

		updateShowMoreLabels: () ->
			return if !@$scope.diff?
			setTimeout () =>
				firstRow = @editor.getFirstVisibleRow()
				lastRow  = @editor.getLastVisibleRow()
				updatesBefore = 0
				updatesAfter = 0
				@lastHiddenHighlightBefore = null
				@firstHiddenHighlightAfter = null
				for marker in @$scope.diff.markers or []
					if marker.row < firstRow
						updatesBefore += 1
						@lastHiddenHighlightBeforeRow = marker.row
					if marker.row > lastRow
						updatesAfter += 1
						@firstHiddenHighlightAfterRow ||= marker.row
		
				@$scope.$apply =>
					@$scope.updateLabels = { updatesBefore, updatesAfter }
			, 100
		
		scrollToFirstHighlight: () ->
			for marker in @$scope.diff.markers or []
				@editor.scrollToLine(marker.row, true, false)
				break
