UserGetter = require "../User/UserGetter"
SubscriptionLocator = require "../Subscription/SubscriptionLocator"
Settings = require "settings-sharelatex"

module.exports = AnalyticsMiddlewear =
	injectIntercomDetails: (req, res, next) ->
		user_id = req.session.user._id
		UserGetter.getUser user_id, {
			_id: true
			email: true
			first_name: true
			email: true
			role: true
			institution: true
			signUpDate: true
		}, (error, user) ->
			return next(error) if error?
			SubscriptionLocator.getUsersSubscription user_id, (error, subscription) ->
				return next(error) if error?
				signedUpAt = null
				if user.signUpDate?
					signedUpAt = Math.floor(user.signUpDate.getTime() / 1000)
				freeTrialExpiresAt = null
				if subscription?.freeTrial?.expiresAt?
					freeTrialExpiresAt = Math.floor(subscription.freeTrial?.expiresAt?.getTime() / 1000)
				res.locals.intercom_user = {
					app_id: Settings.analytics?.intercom?.app_id
					email: user.email
					user_id: user._id
					name: user.first_name
					role: user.role
					institution: user.institution
					free_trial_expires_at: freeTrialExpiresAt
					downgraded: subscription?.freeTrial?.downgraded
					signed_up_at: signedUpAt
				}
				next()
				
			