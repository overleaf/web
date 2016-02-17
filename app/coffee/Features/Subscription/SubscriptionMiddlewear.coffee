SubscriptionLocator = require "./SubscriptionLocator"
LimitationsManager = require "./LimitationsManager"
UserGetter = require "../User/UserGetter"
{Project} = require "../../models/Project"
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
		SubscriptionMiddlewear._hasSubscriptionOrGroup req.session.user, (error, hasSubscriptionOrGroup) ->
			return next(error) if error?
			res.locals.hasSubscription = hasSubscriptionOrGroup
			return next() if hasSubscriptionOrGroup
			SubscriptionMiddlewear._redirectToSignUp req.session.user, res

	requireSubscriptionOrCollaborators: (req, res, next) ->
		SubscriptionMiddlewear._hasSubscriptionOrGroup req.session.user, (error, hasSubscriptionOrGroup) ->
			return next(error) if error?
			return next() if hasSubscriptionOrGroup
			SubscriptionMiddlewear._hasCollaborators req.session.user, (error, hasCollaborators) ->
				return next(error) if error?
				return next() if hasCollaborators
				SubscriptionMiddlewear._redirectToSignUp req.session.user, res
		
	_hasSubscriptionOrGroup: (user, callback = (error, hasSubscriptionOrGroup) ->) ->
		LimitationsManager.userHasSubscriptionOrIsGroupMember user, (error, hasPaidSubscription, subscription) ->
			return callback(error) if error?
			logger.log {hasPaidSubscription, subscription, user_id: user._id}, "got subscription status"
			return callback null, (hasPaidSubscription or subscription?)
	
	_hasCollaborators: (user, callback = (error, hasCollaborators) ->) ->
		Project.findAllUsersProjects user._id, "_id", (error, ownedProjects, sharedProjects, readOnlyProjects) ->
			return callback(error) if error?
			return callback null, (sharedProjects.length > 0 or readOnlyProjects.length > 0)
		
	_redirectToSignUp: (user, res) ->
		res.redirect "/user/free_trial"
