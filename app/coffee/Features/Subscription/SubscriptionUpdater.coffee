async = require("async")
_ = require("underscore")
Subscription = require('../../models/Subscription').Subscription
SubscriptionLocator = require("./SubscriptionLocator")
UserFeaturesUpdater = require("./UserFeaturesUpdater")
PlansLocator = require("./PlansLocator")
Settings = require("settings-sharelatex")
logger = require("logger-sharelatex")
ObjectId = require('mongoose').Types.ObjectId	

oneMonthInSeconds = 60 * 60 * 24 * 30

module.exports = SubscriptionUpdater =

	syncSubscription: (recurlySubscription, adminUser_id, callback) ->
		self = @
		logger.log adminUser_id:adminUser_id, recurlySubscription:recurlySubscription, "syncSubscription, creating new if subscription does not exist"
		SubscriptionLocator.getUsersSubscription adminUser_id, (err, subscription)->
			if subscription?
				logger.log  adminUser_id:adminUser_id, recurlySubscription:recurlySubscription, "subscription does exist"
				self._updateSubscription recurlySubscription, subscription, callback
			else
				logger.log  adminUser_id:adminUser_id, recurlySubscription:recurlySubscription, "subscription does not exist, creating a new one"
				self._createNewSubscription adminUser_id, (err, subscription)->
					self._updateSubscription recurlySubscription, subscription, callback

	addUserToGroup: (adminUser_id, user_id, callback)->
		logger.log adminUser_id:adminUser_id, user_id:user_id, "adding user into mongo subscription"
		SubscriptionUpdater.destroyFreeTrial user_id, (error) ->
			return callback(error) if error?
			searchOps = 
				admin_id: adminUser_id
			insertOperation = 
				"$addToSet": {member_ids:user_id}
			Subscription.findAndModify searchOps, insertOperation, (error, subscription)->
				return callback(error) if error?
				UserFeaturesUpdater.updateFeatures user_id, subscription.planCode, callback

	removeUserFromGroup: (adminUser_id, user_id, callback)->
		searchOps = 
			admin_id: adminUser_id
		removeOperation = 
			"$pull": {member_ids:user_id}
		Subscription.update searchOps, removeOperation, ->
			UserFeaturesUpdater.updateFeatures user_id, Settings.defaultPlanCode, callback

	createFreeTrialIfNoSubscription: (user_id, plan_code, length_in_days, callback = (error, subscription) ->) ->
		# We can't check using LimitationsManager.userHasSubscriptionOrIsGroupMember
		# because that only checks for *paid* subscriptions, not existing free trials.
		# We only want to start a free trial if there is no existing subscription object
		# at all (or group membership).
		SubscriptionLocator.getUsersSubscription user_id, (error, subscription) ->
			return callback(error) if error?
			return callback() if subscription?
			SubscriptionLocator.getMemberSubscriptions user_id, (error, groupSubscriptions = []) ->
				return callback(error) if error?
				return callback() if groupSubscriptions.length > 0
				logger.log {user_id, plan_code, length_in_days}, "starting free trial for user"
				SubscriptionUpdater._createNewSubscription user_id, (error, subscription) ->
					return callback(error) if error?
					subscription.freeTrial.planCode = plan_code
					subscription.freeTrial.expiresAt = new Date(Date.now() + length_in_days * 24 * 60 * 60 * 1000)
					subscription.save (error) ->
						return callback(error) if error?
						UserFeaturesUpdater.updateFeatures user_id, plan_code, callback
				
	downgradeFreeTrialIfExpired: (user_id, callback = (error) ->) ->
		SubscriptionLocator.getUsersSubscription user_id, (error, subscription) ->
			return callback(error) if error?
			freeTrial = subscription?.freeTrial
			return callback() if !freeTrial?
			# Downgrade if past expiry date and not already downgraded
			if !freeTrial.downgraded and freeTrial.expiresAt? and freeTrial.expiresAt < new Date()
				subscription.freeTrial.downgraded = true
				subscription.save (error) ->
					return callback(error) if error?
					UserFeaturesUpdater.updateFeatures user_id, Settings.defaultPlanCode, callback
			else
				callback()
	
	destroyFreeTrial: (user_id, callback = (error) ->) ->
		logger.log {user_id}, "destroying user free trial subscription if it exists"
		SubscriptionLocator.getUsersSubscription user_id, (error, subscription) ->
			return callback(error) if error?
			# Don't destroy groupPlan free trials, since this is called when adding oneself
			# to a group plan, and that would destroy if it was a free trial.
			isFreeTrial = subscription?.freeTrial?.expiresAt? and !subscription.groupPlan
			return callback() if !isFreeTrial
			subscription.remove callback

	_createNewSubscription: (adminUser_id, callback)->
		logger.log adminUser_id:adminUser_id, "creating new subscription"
		subscription = new Subscription(admin_id:adminUser_id)
		subscription.freeTrial.allowed = false
		subscription.save (err)->
			callback err, subscription

	_updateSubscription: (recurlySubscription, subscription, callback)->
		logger.log recurlySubscription:recurlySubscription, subscription:subscription, "updaing subscription"
		plan = PlansLocator.findLocalPlanInSettings(recurlySubscription.plan.plan_code)
		if recurlySubscription.state == "expired"
			subscription.recurlySubscription_id = undefined
			subscription.planCode = Settings.defaultPlanCode
		else
			subscription.recurlySubscription_id = recurlySubscription.uuid
			subscription.freeTrial.expiresAt = undefined
			subscription.freeTrial.planCode = undefined
			subscription.freeTrial.allowed = true
			subscription.planCode = recurlySubscription.plan.plan_code
		if plan.groupPlan
			subscription.groupPlan = true
			subscription.membersLimit = plan.membersLimit
		subscription.save ->
			allIds = _.union subscription.members_id, [subscription.admin_id]
			jobs = allIds.map (user_id)->
				return (cb)->
					UserFeaturesUpdater.updateFeatures user_id, subscription.planCode, cb
			async.parallel jobs, callback


