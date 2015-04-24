define [
	"base"
	"libs/recurly-3.0.5"
], (App, recurly) ->


	App.factory "MultiCurrencyPricing", () ->
		
		currencyCode = window.recomendedCurrency

		return {
			currencyCode:currencyCode
			plans: 
				USD:
					symbol: "$"
					datajoy:
						monthly: "$20"
						annual: "$240"

				EUR: 
					symbol: "€"
					datajoy:
						monthly: "€19"
						annual: "€228"
						
				GBP:
					symbol: "£"
					datajoy:
						monthly: "£14"
						annual: "£168"
		}
	



	App.controller "PlansController", ($scope, $modal, event_tracking, abTestManager, MultiCurrencyPricing, $http) ->

		$scope.plans = MultiCurrencyPricing.plans
		$scope.currencyCode = MultiCurrencyPricing.currencyCode

		$scope.trial_len = 7
		$scope.planQueryString = '_free_trial_7_days'

		$scope.ui =
			view: "monthly"


		$scope.changeCurreny = (newCurrency)->
			$scope.currencyCode = newCurrency

		$scope.signUpNowClicked = (plan, annual)->
			if $scope.ui.view == "annual"
				plan = "#{plan}_annual"
			
			event_tracking.send 'subscription-funnel', 'sign_up_now_button', plan

		$scope.switchToMonthly = ->
			$scope.ui.view = "monthly"
			event_tracking.send 'subscription-funnel', 'plans-page', 'monthly-prices'
		
		$scope.switchToStudent = ->
			$scope.ui.view = "student"
			event_tracking.send 'subscription-funnel', 'plans-page', 'student-prices'

		$scope.switchToAnnual = ->
			$scope.ui.view = "annual"
			event_tracking.send 'subscription-funnel', 'plans-page', 'student-prices'
			
		$scope.openGroupPlanModal = () ->
			$modal.open {
				templateUrl: "groupPlanModalTemplate"
			}
