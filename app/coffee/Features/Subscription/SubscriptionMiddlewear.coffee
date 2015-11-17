SubscriptionLocator = require "./SubscriptionLocator"

module.exports = SubscriptionMiddlewear =
	loadFreeTrialInfo: (req, res, next) ->
		user_id = req.session.user?._id
		return next() if !user_id?
		SubscriptionLocator.getUsersSubscription user_id, (error, subscription) ->
			return next(error) if error?
			return next() if !subscription?
			res.locals.freeTrial = subscription.freeTrial
			expiresAt = subscription.freeTrial.expiresAt
			if expiresAt?
				DAY = 24 * 60 * 60 * 1000
				res.locals.freeTrial.daysRemaining = Math.floor((expiresAt - new Date()) / DAY) + 1
			next()
		