define [], () ->

	# This class represents our '...' spinner that we show below the ace autocomplete popup.
	# The tryAttach static-method is where most of the magic happens. It searches the page for
	# a '.ace_autocomple' element, and if found builds the the spinner dom elements and
	# inserts them into the page.
	# All state is kept in singleton instance of this class, and that instance is cached
	# on the $scope object. Further calls to tryAttach for that editor will have no effect.
	class KernelCompletionSpinner

		constructor: (@$scope, @editor) ->
			@spinner_element = null
			@request_count = 0

		@buildSpinnerElement: () ->
			# create the inner div and dot elements
			inner = document.createElement('div')
			inner.classList.add('loading')
			for i in [1..3]
				dot = document.createElement('span')
				dot.textContent = '.'
				inner.appendChild(dot)

			# create a new spinner_element div
			spinner_element = document.createElement('div')
			spinner_element.classList.add("dj_ace_autocomplete_spinner")
			spinner_element.appendChild(inner)

			spinner_element.style.position = 'absolute'
			spinner_element.style.bottom = '-20px'
			spinner_element.style.right = '4px'
			spinner_element.style.visibility = 'visible'

			return spinner_element

		# static method: attempt to find the ace_autocomplete element
		# for the given editor and attach our
		# spinner graphic to it, keeping it's state in an instance of
		# this class, caching that single instance in $scope._autocomplete_spinners
		@tryAttach: ($scope, editor) ->
			# init an object to keep references to spinners for each editor
			$scope._autocomplete_spinners ||= {}

			# early return if we've already got a spinner from a
			# previous run
			if $scope._autocomplete_spinners[editor._dj_name]
				return

			# get the autocomplete popup for this editor, if it exists in the page
			autocomplete = editor?.completer?.popup?.renderer?.container
			if autocomplete

				# new spinner object, which will track state for
				# the spinner graphic
				spinner = new KernelCompletionSpinner($scope, editor)

				# patch styles on the autocomplete popup.
				# required to make the spinner visible beyond the edge of
				# the popup
				autocomplete.style.overflow = 'visible'

				# append spinner element (graphic) to the autocomplete popup
				spinner_element = KernelCompletionSpinner.buildSpinnerElement()
				$(autocomplete).append(spinner_element)

				# keep track of how many completion requests are in flight.
				# show/hide the spinner graphic as appropriate
				$scope.$on 'completion_request:start', () ->
					spinner.request_count++
					if spinner.request_count > 0
						spinner_element.style.visibility = 'visible'

				$scope.$on 'completion_request:end', () ->
					spinner.request_count--
					if spinner.request_count <= 0
						spinner_element.style.visibility = 'hidden'

				spinner.spinner_element = spinner_element
				$scope._autocomplete_spinners[editor._dj_name] = spinner
