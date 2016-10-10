define [
	"ace/ace"
], () ->
	Range = ace.require("ace/range").Range

	class MarkerManager
		constructor: (@editor, opts = {enableLabels: false}) ->
			@markers = rows: []
			
			@$ace = $(@editor.renderer.container).find(".ace_scroller")
			@$labelEl = $("<div class='marker-label'></div>")
			@$ace.append(@$labelEl)
			@labelVisible = false

			onChange = (e) =>
				if !@editor.initing
					@applyChange(e)

			@editor.on "changeSession", (e) =>
				e.oldSession?.getDocument().off "change", onChange
				e.session.getDocument().on "change", onChange
			@editor.getSession().getDocument().on "change", onChange

			if opts.enableLabels
				@editor.on "mousemove", (e) =>
					position = @editor.renderer.screenToTextCoordinates(e.clientX, e.clientY)
					e.position = position
					@showMarkerLabels(position)
			
			@editor.renderer.on "themeChange", (e) =>
				setTimeout () =>
					@redrawMarkers()
				, 0

		addMarker: (marker) ->
			@_addMarker(marker)
			@markers.rows[marker.row] ||= []
			@markers.rows[marker.row].push marker

		removeMarker: (marker) ->
			sl_console.log "[removeMarker]", marker
			@_clearMarker(marker)
			for a, i in @markers.rows[marker.row]
				if a == marker
					@markers.rows[marker.row].splice(i, 1)
		
		removeAllMarkers: () ->
			for row in @markers.rows or []
				for marker in row or []
					@_clearMarker(marker)
			@markers.rows = []
		
		removeMarkersMatching: (callback = (marker) ->) ->
			toRemove = []
			for row in @markers.rows
				for marker in (row || [])
					if callback(marker)
						toRemove.push(marker)
			for marker in toRemove
				@removeMarker marker

		moveMarker: (marker, position) ->
			@removeMarker marker
			marker.row = position.row
			marker.column = position.column
			@addMarker marker
		
		redrawMarkers: () ->
			for row in @markers.rows
				for marker in (row || [])
					@_clearMarker(marker)
					@_addMarker(marker)

		clearRows: (from, to) ->
			sl_console.log "[clearRows]", from, to
			from ||= 0
			to ||= @markers.rows.length - 1
			for row in @markers.rows.slice(from, to + 1)
				for marker in (row || []).slice(0)
					@removeMarker marker

		insertRows: (offset, number) ->
			# rows are inserted after offset. i.e. offset row is not modified
			affectedMarkers = []
			for row in @markers.rows.slice(offset)
				affectedMarkers.push(marker) for marker in (row || [])
			for marker in affectedMarkers
				@moveMarker marker,
					row: marker.row + number
					column: marker.column

		removeRows: (offset, number) ->
			# offset is the first row to delete
			affectedMarkers = []
			for row in @markers.rows.slice(offset)
				affectedMarkers.push(marker) for marker in (row || [])
			for marker in affectedMarkers
				if marker.row >= offset + number
					@moveMarker marker,
						row: marker.row - number
						column: marker.column
				else
					@removeMarker marker

		findMarkerWithinRange: (range) ->
			rows = @markers.rows.slice(range.start.row, range.end.row + 1)
			for row in rows
				for marker in (row || [])
					if @_doesMarkerOverlapRange(marker, range.start, range.end)
						return marker
			return null

		applyChange: (change) ->
			start = change.start
			end = change.end
			if change.action == "insert"
				if start.row != end.row
					rowsAdded = end.row - start.row
					@insertRows start.row + 1, rowsAdded
				# make a copy since we're going to modify in place
				oldMarkers = (@markers.rows[start.row] || []).slice(0)
				for marker in oldMarkers
					if marker.column > start.column
						# insertion was fully before this marker
						@moveMarker marker,
							row: end.row
							column: marker.column + (end.column - start.column)
					else if marker.column + marker.length >= start.column
						# insertion was inside this marker
						@removeMarker marker

			else if change.action == "remove"
				if start.row == end.row
					oldMarkers = (@markers.rows[start.row] || []).slice(0)
				else
					rowsRemoved = end.row - start.row
					oldMarkers =
						(@markers.rows[start.row] || []).concat(
							(@markers.rows[end.row] || [])
						)
					@removeRows start.row + 1, rowsRemoved

				for marker in oldMarkers
					if @_doesMarkerOverlapRange marker, start, end
						@removeMarker marker
					else if @_isMarkerAfterRange marker, start, end
						@moveMarker marker,
							row: start.row
							column: marker.column - (end.column - start.column)
		
		_markerRange: (marker) ->
			return new Range(
				marker.row, marker.column,
				marker.row, marker.column + marker.length
			)

		_doesMarkerOverlapRange: (marker, start, end) ->
			markerIsAllBeforeRange =
				marker.row < start.row or
				(marker.row == start.row and marker.column + marker.length <= start.column)
			markerIsAllAfterRange =
				marker.row > end.row or
				(marker.row == end.row and marker.column >= end.column)
			!(markerIsAllBeforeRange or markerIsAllAfterRange)

		_isMarkerAfterRange: (marker, start, end) ->
			return true if marker.row > end.row
			return false if marker.row < end.row
			marker.column >= end.column
			
		_addMarker: (marker) ->
			sl_console.log "[_addMarker]", marker
			if marker.type == "spelling"
				@_drawSpellingUnderline(marker)
			else if marker.type == "highlight"
				colorScheme = @_getColorScheme(marker.hue)
				@_drawHighlight(marker, colorScheme)
			else if marker.type == "strikethrough"
				colorScheme = @_getColorScheme(marker.hue)
				@_drawStrikeThrough(marker, colorScheme)
			else if marker.type == "cursor"
				colorScheme = @_getColorScheme(marker.hue)
				@_drawCursor(marker, colorScheme)
			else
				console.error "Unknown marker type: #{marker.type}"
		
		_clearMarker: (marker) ->
			for markerId in marker.markerIds or []
				@editor.getSession().removeMarker(markerId)
		
		_drawSpellingUnderline: (marker) ->
			marker.markerIds = [
				@editor.getSession().addMarker @_markerRange(marker), "spelling-marker", null, true
			]
		
		_drawCursor: (marker, colorScheme) ->
			marker.markerIds = [
				@editor.getSession().addMarker new Range(
					marker.row, marker.column,
					marker.row, marker.column + 1
				), "annotation remote-cursor", (html, range, left, top, config) ->
					div = """
						<div
							class='remote-cursor custom ace_start'
							style='height: #{config.lineHeight}px; top:#{top}px; left:#{left}px; border-color: #{colorScheme.cursor};'
						>
							<div class="nubbin" style="bottom: #{config.lineHeight}px; background-color: #{colorScheme.cursor};"></div>
						</div>
					"""
					html.push div
				, true
			]

		_drawHighlight: (marker, colorScheme) ->
			marker.markerIds = [
				@_addMarkerWithCustomStyle(
					@_markerRange(marker),
					"marker highlight",
					false,
					"background-color: #{colorScheme.markerBackgroundColor}"
				)
			]

		_drawStrikeThrough: (marker, colorScheme) ->
			lineHeight = @editor.renderer.lineHeight
			marker.markerIds = [
				@_addMarkerWithCustomStyle(
					@_markerRange(marker),
					"marker strike-through-background",
					false,
					"background-color: #{colorScheme.strikeThroughBackgroundColor}"
				),
				@_addMarkerWithCustomStyle(
					@_markerRange(marker),
					"marker strike-through-foreground",
					true,
					"""
						height: #{Math.round(lineHeight/2) + 2}px;
						border-bottom: 2px solid #{colorScheme.strikeThroughForegroundColor};
					"""
				)
			]

		_addMarkerWithCustomStyle: (range, klass, foreground, style) ->
			if foreground?
				markerLayer = @editor.renderer.$markerBack
			else
				markerLayer = @editor.renderer.$markerFront

			return @editor.getSession().addMarker range, klass, (html, range, left, top, config) ->
				if range.isMultiLine()
					markerLayer.drawTextMarker(html, range, klass, config, style)
				else
					markerLayer.drawSingleLineMarker(html, range, "#{klass} ace_start", config, 0, style)
			, foreground

		_getColorScheme: (hue) ->
			if @_isDarkTheme()
				return {
					cursor: "hsl(#{hue}, 70%, 50%)"
					labelBackgroundColor: "hsl(#{hue}, 70%, 50%)"
					markerBackgroundColor: "hsl(#{hue}, 100%, 28%);"
					strikeThroughBackgroundColor: "hsl(#{hue}, 100%, 20%);"
					strikeThroughForegroundColor: "hsl(#{hue}, 100%, 60%);"
				}
			else
				return {
					cursor: "hsl(#{hue}, 70%, 50%)"
					labelBackgroundColor: "hsl(#{hue}, 70%, 50%)"
					markerBackgroundColor: "hsl(#{hue}, 70%, 85%);"
					strikeThroughBackgroundColor: "hsl(#{hue}, 70%, 95%);"
					strikeThroughForegroundColor: "hsl(#{hue}, 70%, 40%);"
				}

		_isDarkTheme: () ->
			rgb = $(@editor.renderer.container).css("background-color");
			[m, r, g, b] = rgb.match(/rgb\(([0-9]+), ([0-9]+), ([0-9]+)\)/)
			r = parseInt(r, 10)
			g = parseInt(g, 10)
			b = parseInt(b, 10)
			return r + g + b < 3 * 128
			
		showMarkerLabels: (position) ->
			marker = null
			for _marker in @markers.rows[position.row] or []
				if _marker.label? and @_markerRange(_marker).contains(position.row, position.column)
					marker = _marker
			

			if !marker?
				# this is the most common path, triggered on mousemove, so
				# for performance only apply setting when it changes
				if @labelVisible
					@labelVisible = false
					@$labelEl.hide()
			else
				coords = @editor.renderer.textToScreenCoordinates(marker.row, marker.column)
				
				offset = @$ace.offset()
				height = @$ace.height()
				coords.pageX = coords.pageX - offset.left
				coords.pageY = coords.pageY - offset.top
				
				if coords.pageY > @editor.renderer.lineHeight * 2
					top    = "auto"
					bottom = height - coords.pageY
				else
					top    = coords.pageY + @editor.renderer.lineHeight
					bottom = "auto"
				
				# Set this first so that the label has the correct width when calculating below
				@$labelEl.text(marker.label)
				@$labelEl.show()
								
				if coords.pageX + @$labelEl.outerWidth() < @$ace.width()
					left  = coords.pageX
					right = "auto"
				else
					right = 0
					left = "auto"
				
				@$labelEl.css({
					position: "absolute"
					left:   left
					right:  right
					bottom: bottom
					top:    top
					backgroundColor: @_getColorScheme(marker.hue).labelBackgroundColor
				})
				@labelVisible = true
