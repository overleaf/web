UserGetter = require "../User/UserGetter"
SubscriptionLocator = require "../Subscription/SubscriptionLocator"
Settings = require "settings-sharelatex"

module.exports = AnalyticsMiddlewear =
	injectIntercomDetails: (req, res, next) ->
		if !req.session.user?
			return next()

		user_id = req.session.user._id
		UserGetter.getUser user_id, {
			_id: true
			email: true
			first_name: true
			email: true
			role: true
			institution: true
			use_case: true
		}, (error, user) ->
			return next(error) if error?
			SubscriptionLocator.getUsersSubscription user_id, (error, subscription) ->
				return next(error) if error?
				res.locals.intercom_user = {
					app_id: Settings.analytics?.intercom?.app_id
					email: user.email
					user_id: user._id
					name: user.first_name
					role: user.role
					institution: user.institution
					use_case: user.use_case
					plan_code: subscription?.planCode
					free_trial_expires_at: subscription?.freeTrial?.expiresAt
				}
				next()
				
			