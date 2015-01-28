define [
	"base"
], (App) ->
	App.controller "FreeTrialModalController", ($scope, abTestManager)->

		buttonColorBuckets = [
			{ bucketName:"red", btnClass:"primary"}
			{ bucketName:"blue", btnClass:"info"}
		]

		buttonColorBucket = abTestManager.getABTestBucket "button_color", buttonColorBuckets
		abTestManager.processTestWithStep("button_color", buttonColorBucket.bucketName, 0)
		$scope.buttonClass = "btn-#{buttonColorBucket.btnClass}"


		$scope.startFreeTrial = (source) ->
			window.open("/user/subscription/new?planCode=datajoy")
			$scope.startedFreeTrial = true