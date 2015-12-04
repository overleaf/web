define [], () ->

	class KernelCompletionSpinner

		@tryAttach: (@$scope) ->
			# early return if we've already got a spinner from a
			# previous run
			if @$scope._autocomplete_spinner
				return

			# get the autocomplete popup, if it exists in the page
			autocomplete = $('.ace_autocomplete')
			if autocomplete.length == 1
				# try to find the spinner (it may already exist)
				spinner = $('.dj_ace_autocomplete_spinner')[0]
				if !spinner
					# patch styles on the autocomplete popup
					ac = autocomplete[0]
					ac.style.position = 'relative'
					ac.style.overflow = 'visible'  # required to make the spinner visible

					# create the spinner elements
					inner = document.createElement('div')
					inner.classList.add('loading')
					inner.style.visibility = 'visible'
					for i in [1..3]
						dot = document.createElement('span')
						dot.textContent = '.'
						inner.appendChild(dot)
					spinner = document.createElement('div')
					spinner.classList.add('dj_ace_autocomplete_spinner')
					spinner.appendChild(inner)

					spinner.style.position = 'absolute'
					spinner.style.bottom = '-20px'
					spinner.style.left = '4px'

					# append the spinner to the autocomplete popup
					$(ac).append(spinner)

					# keep track of how many completion requests are in flight.
					# show/hide the spinner visuals as appropriate
					spinner._request_count = 0
					@$scope.$on 'completion_request:start', () ->
						spinner._request_count++
						if spinner._request_count > 0
							inner.style.visibility = 'visible'

					@$scope.$on 'completion_request:end', () ->
						spinner._request_count--
						if spinner._request_count <= 0
							inner.style.visibility = 'hidden'

				@$scope._autocomplete_spinner = spinner
