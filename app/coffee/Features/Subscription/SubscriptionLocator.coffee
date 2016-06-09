Subscription = require('../../models/Subscription').Subscription
logger = require("logger-sharelatex")
ObjectId = require('mongoose').Types.ObjectId

module.exports = SubscriptionLocator =

	getUsersSubscription: (user_or_id, callback)->
		if user_or_id? and user_or_id._id?
			user_id = user_or_id._id
		else if user_or_id?
			user_id = user_or_id
		logger.log user_id:user_id, "getting users subscription"
		Subscription.findOne admin_id:user_id, (err, subscription)->
			logger.log user_id:user_id, "got users subscription"
			callback(err, subscription)

	getMemberSubscriptions: (user_id, callback) ->
		logger.log user_id: user_id, "getting users group subscriptions"
		Subscription.find(member_ids: user_id).populate("admin_id").exec callback

	getSubscription: (subscription_id, callback)->
		Subscription.findOne _id:subscription_id, callback

	getSubscriptionByMemberIdAndId: (user_id, subscription_id, callback)->
		Subscription.findOne member_ids: user_id, _id:subscription_id, callback
		
	getFreeTrialInfo: (user_id, callback = (error, freeTrialInfo) ->) ->
		# Returns users free trial info, but not if they are in a group, since
		# then their own free trial should not apply.
		SubscriptionLocator.getUsersSubscription user_id, (error, subscription) ->
			return callback(error) if error?
			return callback() if !subscription?
			SubscriptionLocator.getMemberSubscriptions user_id, (error, groupSubscriptions) ->
				return callback(error) if error?
				return callback() if groupSubscriptions.length > 0 # Don't worry about free trial if in group
				return callback null, subscription.freeTrial