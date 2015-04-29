define [], () ->
	class AnalyticsManager
		constructor: (@ide, @$scope) ->
			opened = false
			@$scope.$on "project:joined", () =>
				if !opened
					@ide.event_tracking.send('project', 'opened', {
						project_id: @$scope.project._id
						name: @$scope.project.name
					})
				opened = true
				