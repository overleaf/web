define [
	"base"
], (App) ->
	App.controller "FreeTrialModalController", ($scope, abTestManager)->
		$scope.startFreeTrial = (source) ->
			ga?('send', 'event', 'subscription-funnel', 'upgraded-free-trial', source)
			window.open("/user/subscription/new?planCode=datajoy")
			$scope.startedFreeTrial = true