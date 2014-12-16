define [], () ->
	class AnalyticsManager
		constructor: (@ide, @$scope) ->
			opened = false
			@$scope.$on "project:joined", () =>
				if !opened
					Intercom?('trackEvent', 'opened-project', {
						project_id: @$scope.project._id
						name: @$scope.project.name
					})
				opened = true
				