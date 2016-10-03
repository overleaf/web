define [
	"ace/ace"
	"ide/editor/directives/aceEditor/markers/MarkerManager"
], (_, MarkerManager) ->
	Range = ace.require("ace/range").Range

	class DiffManager
		constructor: (@$scope, @editor, @element) ->
			@markerManager = new MarkerManager(@editor)

			@$scope.$watch "diff", (diff) =>
				return if !diff? or !diff.text?
				@editor.setValue(diff.text, -1)
				session = @editor.getSession()
				session.setUseWrapMode(true)
				@markerManager.removeAllMarkers()
				for highlight in diff.highlights
					@markerManager.addMarker(highlight)

			@$scope.gotoHighlightBelow = () =>
				return if !@firstHiddenHighlightAfter?
				@editor.scrollToLine(@firstHiddenHighlightAfter.end.row, true, false)

			@$scope.gotoHighlightAbove = () =>
				return if !@lastHiddenHighlightBefore?
				@editor.scrollToLine(@lastHiddenHighlightBefore.start.row, true, false)
		# 
		# redrawMarkers: () ->
		# 	@_clearMarkers()
		# 	@_clearLabels()
		# 
		# 	for marker in @$scope.highlights or []
		# 		do (marker) =>
		# 			colorScheme = @_getColorScheme(marker.hue)
		# 			if marker.cursor?
		# 				@labels.push {
		# 					text: marker.label
		# 					range: new Range(
		# 						marker.cursor.row, marker.cursor.column,
		# 						marker.cursor.row, marker.cursor.column + 1
		# 					)
		# 					colorScheme: colorScheme
		# 					snapToStartOfRange: true
		# 				}
		# 				@_drawCursor(marker, colorScheme)
		# 			else if marker.highlight?
		# 				@labels.push {
		# 					text: marker.label
		# 					range: new Range(
		# 						marker.highlight.start.row, marker.highlight.start.column,
		# 						marker.highlight.end.row,   marker.highlight.end.column
		# 					)
		# 					colorScheme: colorScheme
		# 				}
		# 				@_drawHighlight(marker, colorScheme)
		# 			else if marker.strikeThrough?
		# 				@labels.push {
		# 					text: marker.label
		# 					range: new Range(
		# 						marker.strikeThrough.start.row, marker.strikeThrough.start.column,
		# 						marker.strikeThrough.end.row,   marker.strikeThrough.end.column
		# 					)
		# 					colorScheme: colorScheme
		# 				}
		# 				@_drawStrikeThrough(marker, colorScheme)
		# 
		# 	@updateShowMoreLabels()
		# 
		# showMarkerLabels: (position) ->
		# 	labelToShow = null
		# 	for label in @labels or []
		# 		if label.range.contains(position.row, position.column)
		# 			labelToShow = label
		# 
		# 	if !labelToShow?
		# 		# this is the most common path, triggered on mousemove, so
		# 		# for performance only apply setting when it changes
		# 		if @$scope?.markerLabel?.show != false
		# 			@$scope.$apply () =>
		# 				@$scope.markerLabel.show = false
		# 	else
		# 		$ace = $(@editor.renderer.container).find(".ace_scroller")
		# 		# Move the label into the Ace content area so that offsets and positions are easy to calculate.
		# 		$ace.append(@element.find(".marker-label"))
		# 
		# 		if labelToShow.snapToStartOfRange
		# 			coords = @editor.renderer.textToScreenCoordinates(labelToShow.range.start.row, labelToShow.range.start.column)
		# 		else
		# 			coords = @editor.renderer.textToScreenCoordinates(position.row, position.column)
		# 
		# 		offset = $ace.offset()
		# 		height = $ace.height()
		# 		coords.pageX = coords.pageX - offset.left
		# 		coords.pageY = coords.pageY - offset.top
		# 
		# 		if coords.pageY > @editor.renderer.lineHeight * 2
		# 			top    = "auto"
		# 			bottom = height - coords.pageY
		# 		else
		# 			top    = coords.pageY + @editor.renderer.lineHeight
		# 			bottom = "auto"
		# 
		# 		# Apply this first that the label has the correct width when calculating below
		# 		@$scope.$apply () =>
		# 			@$scope.markerLabel.text = labelToShow.text
		# 			@$scope.markerLabel.show = true
		# 
		# 		$label = @element.find(".marker-label")
		# 
		# 		if coords.pageX + $label.outerWidth() < $ace.width()
		# 			left  = coords.pageX
		# 			right = "auto"
		# 		else
		# 			right = 0
		# 			left = "auto"
		# 
		# 		@$scope.$apply () =>
		# 			@$scope.markerLabel = {
		# 				show:   true
		# 				left:   left
		# 				right:  right
		# 				bottom: bottom
		# 				top:    top
		# 				backgroundColor: labelToShow.colorScheme.labelBackgroundColor
		# 				text:   labelToShow.text
		# 			}
		# 
		# updateShowMoreLabels: () ->
		# 	return if !@$scope.navigateHighlights
		# 	setTimeout () =>
		# 		firstRow = @editor.getFirstVisibleRow()
		# 		lastRow  = @editor.getLastVisibleRow()
		# 		highlightsBefore = 0
		# 		highlightsAfter = 0
		# 		@lastHiddenHighlightBefore = null
		# 		@firstHiddenHighlightAfter = null
		# 		for marker in @$scope.highlights or []
		# 			range = marker.highlight or marker.strikeThrough
		# 			continue if !range?
		# 			if range.start.row < firstRow
		# 				highlightsBefore += 1
		# 				@lastHiddenHighlightBefore = range
		# 			if range.end.row > lastRow
		# 				highlightsAfter += 1
		# 				@firstHiddenHighlightAfter ||= range
		# 
		# 		@$scope.$apply =>
		# 			@$scope.updateLabels = {
		# 				highlightsBefore: highlightsBefore
		# 				highlightsAfter:  highlightsAfter
		# 			}
		# 	, 100
		# 
		# scrollToFirstHighlight: () ->
		# 	for marker in @$scope.highlights or []
		# 		range = marker.highlight or marker.strikeThrough
		# 		continue if !range?
		# 		@editor.scrollToLine(range.start.row, true, false)
		# 		break
		# 
		# _clearMarkers: () ->
		# 	for marker_id in @markerIds
		# 		@editor.getSession().removeMarker(marker_id)
		# 	@markerIds = []
		# 
		# _clearLabels: () ->
		# 	@labels = []
		# 
		# _drawCursor: (marker, colorScheme) ->
		# 	@markerIds.push @editor.getSession().addMarker new Range(
		# 		marker.cursor.row, marker.cursor.column,
		# 		marker.cursor.row, marker.cursor.column + 1
		# 	), "marker remote-cursor", (html, range, left, top, config) ->
		# 		div = """
		# 			<div
		# 				class='remote-cursor custom ace_start'
		# 				style='height: #{config.lineHeight}px; top:#{top}px; left:#{left}px; border-color: #{colorScheme.cursor};'
		# 			>
		# 				<div class="nubbin" style="bottom: #{config.lineHeight}px; background-color: #{colorScheme.cursor};"></div>
		# 			</div>
		# 		"""
		# 		html.push div
		# 	, true
		# 
		# _drawHighlight: (marker, colorScheme) ->
		# 	@_addMarkerWithCustomStyle(
		# 		new Range(
		# 			marker.highlight.start.row, marker.highlight.start.column,
		# 			marker.highlight.end.row,   marker.highlight.end.column
		# 		),
		# 		"marker highlight",
		# 		false,
		# 		"background-color: #{colorScheme.highlightBackgroundColor}"
		# 	)
		# 
		# _drawStrikeThrough: (marker, colorScheme) ->
		# 	lineHeight = @editor.renderer.lineHeight
		# 	@_addMarkerWithCustomStyle(
		# 		new Range(
		# 			marker.strikeThrough.start.row, marker.strikeThrough.start.column,
		# 			marker.strikeThrough.end.row,   marker.strikeThrough.end.column
		# 		),
		# 		"marker strike-through-background",
		# 		false,
		# 		"background-color: #{colorScheme.strikeThroughBackgroundColor}"
		# 	)
		# 	@_addMarkerWithCustomStyle(
		# 		new Range(
		# 			marker.strikeThrough.start.row, marker.strikeThrough.start.column,
		# 			marker.strikeThrough.end.row,   marker.strikeThrough.end.column
		# 		),
		# 		"marker strike-through-foreground",
		# 		true,
		# 		"""
		# 			height: #{Math.round(lineHeight/2) + 2}px;
		# 			border-bottom: 2px solid #{colorScheme.strikeThroughForegroundColor};
		# 		"""
		# 	)
		# 
		# _addMarkerWithCustomStyle: (range, klass, foreground, style) ->
		# 	if foreground?
		# 		markerLayer = @editor.renderer.$markerBack
		# 	else
		# 		markerLayer = @editor.renderer.$markerFront
		# 
		# 	@markerIds.push @editor.getSession().addMarker range, klass, (html, range, left, top, config) ->
		# 		if range.isMultiLine()
		# 			markerLayer.drawTextMarker(html, range, klass, config, style)
		# 		else
		# 			markerLayer.drawSingleLineMarker(html, range, "#{klass} ace_start", config, 0, style)
		# 	, foreground
		# 
		# _getColorScheme: (hue) ->
		# 	if @_isDarkTheme()
		# 		return {
		# 			cursor: "hsl(#{hue}, 70%, 50%)"
		# 			labelBackgroundColor: "hsl(#{hue}, 70%, 50%)"
		# 			highlightBackgroundColor: "hsl(#{hue}, 100%, 28%);"
		# 			strikeThroughBackgroundColor: "hsl(#{hue}, 100%, 20%);"
		# 			strikeThroughForegroundColor: "hsl(#{hue}, 100%, 60%);"
		# 		}
		# 	else
		# 		return {
		# 			cursor: "hsl(#{hue}, 70%, 50%)"
		# 			labelBackgroundColor: "hsl(#{hue}, 70%, 50%)"
		# 			highlightBackgroundColor: "hsl(#{hue}, 70%, 85%);"
		# 			strikeThroughBackgroundColor: "hsl(#{hue}, 70%, 95%);"
		# 			strikeThroughForegroundColor: "hsl(#{hue}, 70%, 40%);"
		# 		}
		# 
		# _isDarkTheme: () ->
		# 	rgb = @element.find(".ace_editor").css("background-color");
		# 	[m, r, g, b] = rgb.match(/rgb\(([0-9]+), ([0-9]+), ([0-9]+)\)/)
		# 	r = parseInt(r, 10)
		# 	g = parseInt(g, 10)
		# 	b = parseInt(b, 10)
		# 	return r + g + b < 3 * 128
