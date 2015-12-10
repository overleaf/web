define [
	"base"
], (App) ->

	App.directive 'expandToAceContentHeight', () ->
		return {
			link: (scope, element, attrs) ->
				initialHeight = null
				adjustHeightToContent = () ->
					initialHeight ||= element.height()

					# Once expanded, the textarea scrollHeight does not shrink
					# again if lines are removed. So first we'll set the height
					# back to one line so we get an accurate measure of the text
					# height.
					# element.height(initialHeight)

					aceHeight = parseInt($(element).find('.ace_content')[0].style.height)
					if attrs.expandToContentHeightMax
						maxHeight = parseInt(attrs.expandToAceContentHeightMax, 10)
						if aceHeight > maxHeight
							aceHeight = maxHeight
					element.height(aceHeight - 38)

				element.bind "keyup", adjustHeightToContent
				element.bind "paste", () ->
					setTimeout adjustHeightToContent, 0
				setTimeout adjustHeightToContent, 100
		}


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
