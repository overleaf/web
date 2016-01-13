async = require("async")
_ = require("underscore")
Subscription = require('../../models/Subscription').Subscription
SubscriptionLocator = require("./SubscriptionLocator")
UserFeaturesUpdater = require("./UserFeaturesUpdater")
PlansLocator = require("./PlansLocator")
Settings = require("settings-sharelatex")
logger = require("logger-sharelatex")
ObjectId = require('mongoose').Types.ObjectId	
ReferalAllocator = require("../Referal/ReferalAllocator")

oneMonthInSeconds = 60 * 60 * 24 * 30

module.exports =
	startFreeTrial: (adminUser_id, planCode, expiresAt, groupPlan, callback) ->
		self = @
		logger.log {adminUser_id, planCode, groupPlan, expiresAt}, "starting free trial"
		SubscriptionLocator.getUsersSubscription adminUser_id, (error, subscription)->
			return callback(error) if error?
			if subscription?
				# HACK: If the user already has a paid subscription this will overwrite the planCode
				logger.log {adminUser_id, planCode, expiresAt, groupPlan}, "subscription already exists, updating to free trial anyway"
				self._startFreeTrial subscription, planCode, expiresAt, groupPlan, callback
			else
				logger.log {adminUser_id, planCode, expiresAt, groupPlan}, "subscription already exists, updating to free trial anyway"
				self._createNewSubscription adminUser_id, (error, subscription)->
					return callback(error) if error?
					self._startFreeTrial subscription, planCode, expiresAt, groupPlan, callback

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
		searchOps = 
			admin_id: adminUser_id
		insertOperation = 
			"$addToSet": {member_ids:user_id}
		Subscription.findAndModify searchOps, insertOperation, (err, subscription)->
			UserFeaturesUpdater.updateFeatures user_id, subscription.planCode, callback

	removeUserFromGroup: (adminUser_id, user_id, callback)->
		searchOps = 
			admin_id: adminUser_id
		removeOperation = 
			"$pull": {member_ids:user_id}
		Subscription.update searchOps, removeOperation, ->
			UserFeaturesUpdater.updateFeatures user_id, Settings.defaultPlanCode, callback

	_startFreeTrial: (subscription, planCode, expiresAt, groupPlan, callback) ->
		subscription.freeTrial.expiresAt = expiresAt
		subscription.freeTrial.planCode = planCode
		subscription.freeTrial.allowed = false
		subscription.planCode = planCode
		subscription.groupPlan = !!groupPlan
		subscription.save (error) ->
			return callback(error) if error?
			UserFeaturesUpdater.updateFeatures subscription.admin_id, planCode, callback

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
			jobs.push (cb)-> ReferalAllocator.assignBonus subscription.admin_id, cb
			async.series jobs, callback


