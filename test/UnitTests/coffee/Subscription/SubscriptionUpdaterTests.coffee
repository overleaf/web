SandboxedModule = require('sandboxed-module')
should = require('chai').should()
sinon = require 'sinon'
modulePath = "../../../../app/js/Features/Subscription/SubscriptionUpdater"
assert = require("chai").assert
ObjectId = require('mongoose').Types.ObjectId
tk = require "timekeeper"	

describe "Subscription Updater", ->

	beforeEach ->
		@recurlySubscription = 
			uuid: "1238uoijdasjhd"
			plan:
				plan_code: "kjhsakjds"
		@adminUser = 
			_id:"5208dd34438843e2db000007"
		@otherUserId = "5208dd34438842e2db000005"
		@allUserIds = ["13213", "dsadas", "djsaiud89"]
		@subscription = subscription =
			admin_id: @adminUser._id
			members_id: @allUserIds
			freeTrial:{}
			plan_code:"student_or_something"
			save: sinon.stub().callsArgWith(0)
			remove: sinon.stub().callsArg(0)

		@updateStub = sinon.stub().callsArgWith(2, null)
		@findAndModifyStub = sinon.stub().callsArgWith(2, null, @subscription)
		@SubscriptionModel = class
			constructor: (opts)-> 
				subscription.admin_id = opts.admin_id
				return subscription
		@SubscriptionModel.update = @updateStub
		@SubscriptionModel.findAndModify = @findAndModifyStub

		@SubscriptionLocator = 
			getUsersSubscription: sinon.stub()
			
		@Settings = 
			freeTrialPlanCode: "collaborator"
			defaultPlanCode: "personal"

		@UserFeaturesUpdater =
			updateFeatures : sinon.stub().callsArgWith(2)

		@PlansLocator =
			findLocalPlanInSettings: sinon.stub().returns({})

		@callback = sinon.stub()

		tk.freeze(new Date())
		@SubscriptionUpdater = SandboxedModule.require modulePath, requires:
			'../../models/Subscription': Subscription:@SubscriptionModel
			'./UserFeaturesUpdater': @UserFeaturesUpdater
			'./SubscriptionLocator': @SubscriptionLocator
			'./PlansLocator': @PlansLocator
			"logger-sharelatex": log:->
			'settings-sharelatex': @Settings
			"mongoose": Types: ObjectId: ObjectId
			
	afterEach ->
		tk.reset()

	describe "syncSubscription", ->
		it "should update the subscription if the user already is admin of one", (done)->
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, @subscription)
			@SubscriptionUpdater._updateSubscription = sinon.stub().callsArgWith(2)
			@SubscriptionUpdater._createNewSubscription = sinon.stub()

			@SubscriptionUpdater.syncSubscription @recurlySubscription, @adminUser._id, (err)=>
				@SubscriptionLocator.getUsersSubscription.calledWith(@adminUser._id).should.equal true
				@SubscriptionUpdater._updateSubscription.called.should.equal true
				@SubscriptionUpdater._updateSubscription.calledWith(@recurlySubscription, @subscription).should.equal true
				done()


	describe "_updateSubscription", ->

		it "should update the subscription with token etc when not expired", (done)->
			@SubscriptionUpdater._updateSubscription @recurlySubscription, @subscription, (err)=>
				@subscription.recurlySubscription_id.should.equal @recurlySubscription.uuid
				@subscription.planCode.should.equal @recurlySubscription.plan.plan_code

				@subscription.freeTrial.allowed.should.equal true
				assert.equal(@subscription.freeTrial.expiresAt, undefined)
				assert.equal(@subscription.freeTrial.planCode, undefined)
				@subscription.save.called.should.equal true
				@UserFeaturesUpdater.updateFeatures.calledWith(@adminUser._id, @recurlySubscription.plan.plan_code).should.equal true
				done()

		it "should remove the recurlySubscription_id when expired", (done)->
			@recurlySubscription.state = "expired"

			@SubscriptionUpdater._updateSubscription @recurlySubscription, @subscription, (err)=>
				assert.equal(@subscription.recurlySubscription_id, undefined)
				@subscription.save.called.should.equal true
				@UserFeaturesUpdater.updateFeatures.calledWith(@adminUser._id, @Settings.defaultPlanCode).should.equal true
				done()

		it "should update all the users features", (done)->
			@SubscriptionUpdater._updateSubscription @recurlySubscription, @subscription, (err)=>
				@UserFeaturesUpdater.updateFeatures.calledWith(@adminUser._id, @recurlySubscription.plan.plan_code).should.equal true
				@UserFeaturesUpdater.updateFeatures.calledWith(@allUserIds[0], @recurlySubscription.plan.plan_code).should.equal true
				@UserFeaturesUpdater.updateFeatures.calledWith(@allUserIds[1], @recurlySubscription.plan.plan_code).should.equal true
				@UserFeaturesUpdater.updateFeatures.calledWith(@allUserIds[2], @recurlySubscription.plan.plan_code).should.equal true
				done()

		it "should set group to true and save how many members can be added to group", (done)->
			@PlansLocator.findLocalPlanInSettings.withArgs(@recurlySubscription.plan.plan_code).returns({groupPlan:true, membersLimit:5})
			@SubscriptionUpdater._updateSubscription @recurlySubscription, @subscription, (err)=>
				@subscription.membersLimit.should.equal 5
				@subscription.groupPlan.should.equal true
				done()

		it "should not set group to true or set groupPlan", (done)->
			@SubscriptionUpdater._updateSubscription @recurlySubscription, @subscription, (err)=>
				assert.notEqual @subscription.membersLimit, 5
				assert.notEqual @subscription.groupPlan, true
				done()

	describe "_createNewSubscription", ->
		it "should create a new subscription then update the subscription", (done)->
			@SubscriptionUpdater._createNewSubscription @adminUser._id, =>
				@subscription.admin_id.should.equal @adminUser._id
				@subscription.freeTrial.allowed.should.equal false
				@subscription.save.called.should.equal true
				done()

	describe "addUserToGroup", ->
		beforeEach ->
			@SubscriptionUpdater.destroyFreeTrial = sinon.stub().callsArg(1)

		it "should add the users id to the group as a set", (done)->
			@SubscriptionUpdater.addUserToGroup @adminUser._id, @otherUserId, =>
				searchOps = 
					admin_id: @adminUser._id
				insertOperation = 
					"$addToSet": {member_ids:@otherUserId}
				@findAndModifyStub.calledWith(searchOps, insertOperation).should.equal true
				done()

		it "should update the users features", (done)->
			@SubscriptionUpdater.addUserToGroup @adminUser._id, @otherUserId, =>
				@UserFeaturesUpdater.updateFeatures.calledWith(@otherUserId, @subscription.planCode).should.equal true
				done()
				
		it "should destroy any free trial subscription that exists", (done) ->	
			@SubscriptionUpdater.addUserToGroup @adminUser._id, @otherUserId, =>
				@SubscriptionUpdater.destroyFreeTrial.calledWith(@otherUserId).should.equal true
				done()

	describe "removeUserFromGroup", ->
		it "should pull the users id from the group", (done)->
			@SubscriptionUpdater.removeUserFromGroup @adminUser._id, @otherUserId, =>
				searchOps = 
					admin_id:@adminUser._id
				removeOperation = 
					"$pull": {member_ids:@otherUserId}
				@updateStub.calledWith(searchOps, removeOperation).should.equal true
				done()

		it "should update the users features", (done)->
			@SubscriptionUpdater.removeUserFromGroup @adminUser._id, @otherUserId, =>
				@UserFeaturesUpdater.updateFeatures.calledWith(@otherUserId, @Settings.defaultPlanCode).should.equal true
				done()

	describe "createFreeTrialIfNoSubscription", ->
		beforeEach ->
			@SubscriptionLocator.getUsersSubscription = sinon.stub()
			@SubscriptionLocator.getMemberSubscriptions = sinon.stub()
			@SubscriptionUpdater._createNewSubscription = sinon.stub().callsArgWith(1, null, @subscription)
			
		describe "without a subscription", ->
			beforeEach ->
				@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, null)
				@SubscriptionLocator.getMemberSubscriptions.callsArgWith(1, null, [])
				@SubscriptionUpdater.createFreeTrialIfNoSubscription @user_id = "user-id", @plan_code = "plan-code", 30, @callback
				
			it "should create the new subscription", ->
				@SubscriptionUpdater._createNewSubscription
					.calledWith(@user_id)
					.should.equal true
					
			it "should set the subscription free trial plan code", ->
				@subscription.freeTrial.planCode.should.equal @plan_code
				
			it "should set the subscription expiresAt date to 30 days time", ->
				expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
				@subscription.freeTrial.expiresAt.toString().should.equal expiresAt.toString()
				
			it "should save the subscription", ->
				@subscription.save.called.should.equal true
				
			it "should update the user features", ->
				@UserFeaturesUpdater.updateFeatures
					.calledWith(@user_id, @plan_code)
					.should.equal true
					
			it "should return the callback", ->
				@callback.called.should.equal true
				
		describe "with a subscription", ->
			beforeEach ->
				@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, @subscription)
				@SubscriptionLocator.getMemberSubscriptions.callsArgWith(1, null, [])
				@SubscriptionUpdater.createFreeTrialIfNoSubscription @user_id = "user-id", @plan_code = "plan-code", 30, @callback
				
			it "should not create new subscription", ->
				@SubscriptionUpdater._createNewSubscription
					.called.should.equal false
					
			it "should return the callback", ->
				@callback.called.should.equal true
				
		describe "with a group subscription", ->
			beforeEach ->
				@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, null)
				@SubscriptionLocator.getMemberSubscriptions.callsArgWith(1, null, [@subscription])
				@SubscriptionUpdater.createFreeTrialIfNoSubscription @user_id = "user-id", @plan_code = "plan-code", 30, @callback
				
			it "should not create new subscription", ->
				@SubscriptionUpdater._createNewSubscription
					.called.should.equal false
					
			it "should return the callback", ->
				@callback.called.should.equal true
			
			
	describe "downgradeFreeTrialIfExpired", ->
		beforeEach ->
			@user_id = "user-id"
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, @subscription)
			
		describe "with expired trial", ->
			beforeEach ->
				@subscription.freeTrial =
					expiresAt: new Date(Date.now() - 1000)
					downgraded: false
				@SubscriptionUpdater.downgradeFreeTrialIfExpired @user_id, @callback

			it "should mark the subscription as downgraded", ->
				@subscription.freeTrial.downgraded.should.equal true
				
			it "should save the subscription", ->
				@subscription.save.called.should.equal true
				
			it "should downgrade the user's features", ->
				@UserFeaturesUpdater.updateFeatures
					.calledWith(@user_id, @Settings.defaultPlanCode)
					.should.equal true
			
			it "should call the callback", ->
				@callback.called.should.equal true

		describe "with already downgraded trial", ->
			beforeEach ->
				@subscription.freeTrial =
					expiresAt: new Date(Date.now() - 1000)
					downgraded: true
				@SubscriptionUpdater.downgradeFreeTrialIfExpired @user_id, @callback
			
			it "should not save any changes", ->
				@subscription.save.called.should.equal false
				@UserFeaturesUpdater.updateFeatures.called.should.equal false
		
			it "should call the callback", ->
				@callback.called.should.equal true
			
		describe "with current trial", ->
			beforeEach ->
				@subscription.freeTrial =
					expiresAt: new Date(Date.now() + 1000)
					downgraded: false
				@SubscriptionUpdater.downgradeFreeTrialIfExpired @user_id, @callback
			
			it "should not save any changes", ->
				@subscription.save.called.should.equal false
				@UserFeaturesUpdater.updateFeatures.called.should.equal false
		
			it "should call the callback", ->
				@callback.called.should.equal true
	
	describe "destroyFreeTrial", ->
		beforeEach ->
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, @subscription)
			
		describe "with a free trial", ->
			beforeEach -> 
				@subscription.freeTrial.expiresAt = new Date()
				@SubscriptionUpdater.destroyFreeTrial @user_id, @callback
				
			it "should get the subscription", ->
				@SubscriptionLocator.getUsersSubscription
					.calledWith(@user_id)
					.should.equal true
					
			it "should destroy the subscription", ->
				@subscription.remove.called.should.equal true
		
			it "should call the callback", ->
				@callback.called.should.equal true
				
		describe "without a free trial", ->
			beforeEach -> 
				@SubscriptionUpdater.destroyFreeTrial @user_id, @callback

			it "should not destroy the subscription", ->
				@subscription.remove.called.should.equal false
		
			it "should call the callback", ->
				@callback.called.should.equal true