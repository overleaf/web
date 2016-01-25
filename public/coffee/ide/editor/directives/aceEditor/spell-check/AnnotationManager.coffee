define [
	"ace/ace"
], () ->
	Range = ace.require("ace/range").Range

	class AnnotationManager
		constructor: (@editor) ->
			@annotations = rows: []
			
			@$ace = $(@editor.renderer.container).find(".ace_scroller")
			@$labelEl = $("<div class='annotation-label'></div>")
			@$ace.append(@$labelEl)
			@labelVisible = false
			
			# TODO: Only enable if needed? Mouse moves are common and expensive
			@editor.on "mousemove", (e) =>
				position = @editor.renderer.screenToTextCoordinates(e.clientX, e.clientY)
				e.position = position
				@showAnnotationLabels(position)

		addAnnotation: (annotation) ->
			@_addMarker(annotation)
			@annotations.rows[annotation.row] ||= []
			@annotations.rows[annotation.row].push annotation

		removeAnnotation: (annotation) ->
			for markerId in annotation.markerIds or []
				@editor.getSession().removeMarker(markerId)
			for h, i in @annotations.rows[annotation.row]
				if h == annotation
					@annotations.rows[annotation.row].splice(i, 1)
		
		removeAllAnnotations: () ->
			for row in @annotations.rows or []
				for annotation in row or []
					for markerId in annotation.markerIds or []
						@editor.getSession().removeMarker(markerId)
			@annotations.rows = []
		
		removeWord: (word) ->
			toRemove = []
			for row in @annotations.rows
				for annotation in (row || [])
					if annotation.word == word
						toRemove.push(annotation)
			for annotation in toRemove
				@removeAnnotation annotation

		moveAnnotation: (annotation, position) ->
			@removeAnnotation annotation
			annotation.row = position.row
			annotation.column = position.column
			@addAnnotation annotation

		clearRows: (from, to) ->
			from ||= 0
			to ||= @annotations.rows.length - 1
			for row in @annotations.rows.slice(from, to + 1)
				for annotation in (row || []).slice(0)
					@removeAnnotation annotation

		insertRows: (offset, number) ->
			# rows are inserted after offset. i.e. offset row is not modified
			affectedAnnotations = []
			for row in @annotations.rows.slice(offset)
				affectedAnnotations.push(annotation) for annotation in (row || [])
			for annotation in affectedAnnotations
				@moveAnnotation annotation,
					row: annotation.row + number
					column: annotation.column

		removeRows: (offset, number) ->
			# offset is the first row to delete
			affectedAnnotations = []
			for row in @annotations.rows.slice(offset)
				affectedAnnotations.push(annotation) for annotation in (row || [])
			for annotation in affectedAnnotations
				if annotation.row >= offset + number
					@moveAnnotation annotation,
						row: annotation.row - number
						column: annotation.column
				else
					@removeAnnotation annotation

		findAnnotationWithinRange: (range) ->
			rows = @annotations.rows.slice(range.start.row, range.end.row + 1)
			for row in rows
				for annotation in (row || [])
					if @_doesAnnotationOverlapRange(annotation, range.start, range.end)
						return annotation
			return null

		applyChange: (change) ->
			start = change.start
			end = change.end
			if change.action == "insert"
				if start.row != end.row
					rowsAdded = end.row - start.row
					@insertRows start.row + 1, rowsAdded
				# make a copy since we're going to modify in place
				oldAnnotations = (@annotations.rows[start.row] || []).slice(0)
				for annotation in oldAnnotations
					if annotation.column > start.column
						# insertion was fully before this annotation
						@moveAnnotation annotation,
							row: end.row
							column: annotation.column + (end.column - start.column)
					else if annotation.column + annotation.length >= start.column
						# insertion was inside this annotation
						@removeAnnotation annotation

			else if change.action == "remove"
				if start.row == end.row
					oldAnnotations = (@annotations.rows[start.row] || []).slice(0)
				else
					rowsRemoved = end.row - start.row
					oldAnnotations =
						(@annotations.rows[start.row] || []).concat(
							(@annotations.rows[end.row] || [])
						)
					@removeRows start.row + 1, rowsRemoved

				for annotation in oldAnnotations
					if @_doesAnnotationOverlapRange annotation, start, end
						@removeAnnotation annotation
					else if @_isAnnotationAfterRange annotation, start, end
						@moveAnnotation annotation,
							row: start.row
							column: annotation.column - (end.column - start.column)
		
		_annotationRange: (annotation) ->
			return new Range(
				annotation.row, annotation.column,
				annotation.row, annotation.column + annotation.length
			)

		_doesAnnotationOverlapRange: (annotation, start, end) ->
			annotationIsAllBeforeRange =
				annotation.row < start.row or
				(annotation.row == start.row and annotation.column + annotation.word.length <= start.column)
			annotationIsAllAfterRange =
				annotation.row > end.row or
				(annotation.row == end.row and annotation.column >= end.column)
			!(annotationIsAllBeforeRange or annotationIsAllAfterRange)

		_isAnnotationAfterRange: (annotation, start, end) ->
			return true if annotation.row > end.row
			return false if annotation.row < end.row
			annotation.column >= end.column
			
		_addMarker: (annotation) ->
			console.log "Adding marker for annotation", annotation
			if annotation.type == "spelling"
				@_drawSpellingUnderline(annotation)
			else if annotation.type == "highlight"
				colorScheme = @_getColorScheme(annotation.hue)
				# @labels.push {
				# 	text: annotation.label
				# 	range: new Range(
				# 		annotation.annotation.start.row, annotation.annotation.start.column,
				# 		annotation.annotation.end.row,   annotation.annotation.end.column
				# 	)
				# 	colorScheme: colorScheme
				# }
				@_drawHighlight(annotation, colorScheme)
			else if annotation.type == "strikethrough"
				colorScheme = @_getColorScheme(annotation.hue)
				# @labels.push {
				# 	text: annotation.label
				# 	range: new Range(
				# 		annotation.strikeThrough.start.row, annotation.strikeThrough.start.column,
				# 		annotation.strikeThrough.end.row,   annotation.strikeThrough.end.column
				# 	)
				# 	colorScheme: colorScheme
				# }
				@_drawStrikeThrough(annotation, colorScheme)
			else
				console.error "Unknown annotation type: #{annotation.type}"
		
		_drawSpellingUnderline: (annotation) ->
			annotation.markerIds = [
				@editor.getSession().addMarker @_annotationRange(annotation), "spelling-annotation", null, true
			]
		
		_drawHighlight: (annotation, colorScheme) ->
			annotation.markerIds = [
				@_addMarkerWithCustomStyle(
					@_annotationRange(annotation),
					"annotation highlight",
					false,
					"background-color: #{colorScheme.annotationBackgroundColor}"
				)
			]

		_drawStrikeThrough: (annotation, colorScheme) ->
			lineHeight = @editor.renderer.lineHeight
			annotation.markerIds = [
				@_addMarkerWithCustomStyle(
					@_annotationRange(annotation),
					"annotation strike-through-background",
					false,
					"background-color: #{colorScheme.strikeThroughBackgroundColor}"
				),
				@_addMarkerWithCustomStyle(
					@_annotationRange(annotation),
					"annotation strike-through-foreground",
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
					annotationBackgroundColor: "hsl(#{hue}, 100%, 28%);"
					strikeThroughBackgroundColor: "hsl(#{hue}, 100%, 20%);"
					strikeThroughForegroundColor: "hsl(#{hue}, 100%, 60%);"
				}
			else
				return {
					cursor: "hsl(#{hue}, 70%, 50%)"
					labelBackgroundColor: "hsl(#{hue}, 70%, 50%)"
					annotationBackgroundColor: "hsl(#{hue}, 70%, 85%);"
					strikeThroughBackgroundColor: "hsl(#{hue}, 70%, 95%);"
					strikeThroughForegroundColor: "hsl(#{hue}, 70%, 40%);"
				}

		_isDarkTheme: () ->
			return false
			# TODO: get this working again
			# rgb = @editor.find(".ace_editor").css("background-color");
			# [m, r, g, b] = rgb.match(/rgb\(([0-9]+), ([0-9]+), ([0-9]+)\)/)
			# r = parseInt(r, 10)
			# g = parseInt(g, 10)
			# b = parseInt(b, 10)
			# return r + g + b < 3 * 128
			
		showAnnotationLabels: (position) ->
			annotation = null
			for _annotation in @annotations.rows[position.row] or []
				if _annotation.label? and @_annotationRange(_annotation).contains(position.row, position.column)
					annotation = _annotation
			

			if !annotation?
				# this is the most common path, triggered on mousemove, so
				# for performance only apply setting when it changes
				if @labelVisible
					@labelVisible = false
					@$labelEl.hide()
			else
				coords = @editor.renderer.textToScreenCoordinates(annotation.row, annotation.column)
				
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
				@$labelEl.text(annotation.label)
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
					backgroundColor: @_getColorScheme(annotation.hue).labelBackgroundColor
				})
				@labelVisible = true
