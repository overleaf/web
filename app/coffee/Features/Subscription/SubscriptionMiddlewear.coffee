SubscriptionLocator = require "./SubscriptionLocator"
LimitationsManager = require "./LimitationsManager"

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
	
	requireTeacherSubscription: (req, res, next) ->
		if req.session.user.use_case == "teacher"
			LimitationsManager.userHasSubscription req.session.user, (error, hasPaidSubscription, subscription) ->
				return next(error) if error?
				if subscription?
					return next()
				else
					res.redirect "/teacher/free_trial"
		else
			next()