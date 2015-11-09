define [
	"base"
], (App) ->
	App.controller "FreeTrialModalController", ($scope, abTestManager, event_tracking)->

		$scope.buttonClass = "btn-primary"

		$scope.startFreeTrial = (source) ->
			event_tracking.send("free-trial", "clicked-#{source}")
			window.open("/user/subscription/new?planCode=datajoy")
			$scope.startedFreeTrial = true
		
		$scope.recordFreeTrialShown = (source) ->
			event_tracking.send("free-trial", "shown-#{source}")
