SubscriptionLocator = require "./SubscriptionLocator"
LimitationsManager = require "./LimitationsManager"
UserGetter = require "../User/UserGetter"
logger = require "logger-sharelatex"

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
	
	requireSubscription: (req, res, next) ->
		LimitationsManager.userHasSubscriptionOrIsGroupMember req.session.user, (error, hasPaidSubscription, subscription) ->
			return next(error) if error?
			logger.log {hasPaidSubscription, subscription}, "got subscription status"
			if hasPaidSubscription or subscription?
				return next()
			else
				UserGetter.getUser req.session.user._id, { use_case: 1 }, (error, user) ->
					return next(error) if error?
					use_case = user?.use_case 
					if use_case == "teacher"
						res.redirect "/teacher/free_trial"
					else
						res.redirect "/user/subscription/new?planCode=datajoy"