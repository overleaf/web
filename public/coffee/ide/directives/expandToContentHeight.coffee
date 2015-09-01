define [
	"base"
], (App) ->
	App.directive 'expandToContentHeight', () ->
		return {
			link: (scope, element, attrs) ->
				initialHeight = null
				adjustHeightToContent = () ->
					initialHeight ||= element.height()
					
					# Once expanded, the textarea scrollHeight does not shrink
					# again if lines are removed. So first we'll set the height
					# back to one line so we get an accurate measure of the text
					# height.
					element.height(initialHeight)

					height = element.prop('scrollHeight')
					if attrs.expandToContentHeightMax
						maxHeight = parseInt(attrs.expandToContentHeightMax, 10)
						if height > maxHeight
							height = maxHeight
					element.height(height - 4)
					
				element.bind "keyup", adjustHeightToContent
				element.bind "paste", () ->
					setTimeout adjustHeightToContent, 0
		}