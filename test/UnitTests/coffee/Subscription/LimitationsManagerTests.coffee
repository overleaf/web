SandboxedModule = require('sandboxed-module')
sinon = require('sinon')
require('chai').should()
modulePath = require('path').join __dirname, '../../../../app/js/Features/Subscription/LimitationsManager'
Settings = require("settings-sharelatex")
tk = require "timekeeper"

describe "LimitationsManager", ->
	beforeEach ->
		@project = { _id: "project-id" }
		@user = { _id: "user-id", features:{} }
		@Project =
			findById: (project_id, fields, callback) =>
				if project_id == @project_id
					callback null, @project
				else
					callback null, null
		@User =
			findById: (user_id, callback) =>
				if user_id == @user.id
					callback null, @user
				else
					callback null, null

		@SubscriptionLocator =
			getUsersSubscription: sinon.stub()

		tk.freeze(new Date())
		@LimitationsManager = SandboxedModule.require modulePath, requires:
			'../../models/Project' : Project: @Project
			'../../models/User' : User: @User
			'./SubscriptionLocator':@SubscriptionLocator
			'settings-sharelatex' : @Settings = {}
			'logger-sharelatex':log:->
				
	afterEach ->
		tk.reset()

	describe "allowedNumberOfCollaboratorsInProject", ->
		describe "when the project is owned by a user without a subscription", ->
			beforeEach ->
				@Settings.defaultPlanCode = collaborators: 23
				delete @user.features
				@callback = sinon.stub()
				@LimitationsManager.allowedNumberOfCollaboratorsInProject(@project_id, @callback)

			it "should return the default number", ->
				@callback.calledWith(null, @Settings.defaultPlanCode.collaborators).should.equal true

		describe "when the project is owned by a user with a subscription", ->
			beforeEach ->
				@user.features =
					collaborators: 21
				@callback = sinon.stub()
				@LimitationsManager.allowedNumberOfCollaboratorsInProject(@project_id, @callback)

			it "should return the number of collaborators the user is allowed", ->
				@callback.calledWith(null, @user.features.collaborators).should.equal true
	
	describe "currentNumberOfCollaboratorsInProject", ->
		beforeEach ->
			@project.collaberator_refs = ["one", "two"]
			@project.readOnly_refs = ["three"]
			@callback = sinon.stub()
			@LimitationsManager.currentNumberOfCollaboratorsInProject(@project_id, @callback)

		it "should return the total number of collaborators", ->
			@callback.calledWith(null, 3).should.equal true

	describe "isCollaboratorLimitReached", ->
		beforeEach ->
			sinon.stub @LimitationsManager,
					   "currentNumberOfCollaboratorsInProject",
					   (project_id, callback) => callback(null, @current_number)
			sinon.stub @LimitationsManager,
					   "allowedNumberOfCollaboratorsInProject",
					   (project_id, callback) => callback(null, @allowed_number)
			@callback = sinon.stub()

		describe "when the project has fewer collaborators than allowed", ->
			beforeEach ->
				@current_number = 1
				@allowed_number = 2
				@LimitationsManager.isCollaboratorLimitReached(@project_id, @callback)

			it "should return false", ->
				@callback.calledWith(null, false).should.equal true

		describe "when the project has more collaborators than allowed", ->
			beforeEach ->
				@current_number = 3
				@allowed_number = 2
				@LimitationsManager.isCollaboratorLimitReached(@project_id, @callback)

			it "should return true", ->
				@callback.calledWith(null, true).should.equal true

		describe "when the project has infinite collaborators", ->
			beforeEach ->
				@current_number = 100
				@allowed_number = -1
				@LimitationsManager.isCollaboratorLimitReached(@project_id, @callback)

			it "should return false", ->
				@callback.calledWith(null, false).should.equal true


	describe "userHasSubscription", ->
		beforeEach ->
			@SubscriptionLocator.getUsersSubscription = sinon.stub()

		it "should return true if the recurly token is set", (done)->
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, recurlySubscription_id : "1234")
			@LimitationsManager.userHasSubscription @user, (err, hasSubscription)->
				hasSubscription.should.equal true
				done()

		it "should return false if the recurly token is not set", (done)->
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, {})
			@subscription = {}
			@LimitationsManager.userHasSubscription @user, (err, hasSubscription)->
				hasSubscription.should.equal false
				done()

		it "should return false if the subscription is undefined", (done)->
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1)
			@LimitationsManager.userHasSubscription @user, (err, hasSubscription)->
				hasSubscription.should.equal false
				done()

		it "should return the subscription", (done)->
			stubbedSubscription = {freeTrial:{}, token:""}
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, stubbedSubscription)
			@LimitationsManager.userHasSubscription @user, (err, hasSubOrIsGroupMember, subscription)->
				subscription.should.deep.equal stubbedSubscription
				done()
				
	describe "userIsMemberOfGroupSubscription", ->
		beforeEach ->
			@SubscriptionLocator.getMemberSubscriptions = sinon.stub()

		it "should return false if there are no groups subcriptions", (done)->
			@SubscriptionLocator.getMemberSubscriptions.callsArgWith(1, null, [])
			@LimitationsManager.userIsMemberOfGroupSubscription @user, (err, isMember)->
				isMember.should.equal false
				done()

		it "should return true if there are no groups subcriptions", (done)->
			@SubscriptionLocator.getMemberSubscriptions.callsArgWith(1, null, subscriptions = ["mock-subscription"])
			@LimitationsManager.userIsMemberOfGroupSubscription @user, (err, isMember, retSubscriptions)->
				isMember.should.equal true
				retSubscriptions.should.equal subscriptions
				done()

	describe "userHasSubscriptionOrIsGroupMember", ->
		beforeEach ->
			@LimitationsManager.userIsMemberOfGroupSubscription = sinon.stub()
			@LimitationsManager.userHasSubscription = sinon.stub()

		it "should return true if both are true", (done)->
			@LimitationsManager.userIsMemberOfGroupSubscription.callsArgWith(1, null, true)
			@LimitationsManager.userHasSubscription.callsArgWith(1, null, true)
			@LimitationsManager.userHasSubscriptionOrIsGroupMember @user, (err, hasSubOrIsGroupMember)->
				hasSubOrIsGroupMember.should.equal true
				done()

		it "should return true if one is true", (done)->
			@LimitationsManager.userIsMemberOfGroupSubscription.callsArgWith(1, null, true)
			@LimitationsManager.userHasSubscription.callsArgWith(1, null, false)
			@LimitationsManager.userHasSubscriptionOrIsGroupMember @user, (err, hasSubOrIsGroupMember)->
				hasSubOrIsGroupMember.should.equal true
				done()

		it "should return true if other is true", (done)->
			@LimitationsManager.userIsMemberOfGroupSubscription.callsArgWith(1, null, false)
			@LimitationsManager.userHasSubscription.callsArgWith(1, null, true)
			@LimitationsManager.userHasSubscriptionOrIsGroupMember @user, (err, hasSubOrIsGroupMember)->
				hasSubOrIsGroupMember.should.equal true
				done()

		it "should return false if both are false", (done)->
			@LimitationsManager.userIsMemberOfGroupSubscription.callsArgWith(1, null, false)
			@LimitationsManager.userHasSubscription.callsArgWith(1, null, false)
			@LimitationsManager.userHasSubscriptionOrIsGroupMember @user, (err, hasSubOrIsGroupMember)->
				hasSubOrIsGroupMember.should.equal false
				done()
				
	describe "hasGroupMembersLimitReached", ->

		beforeEach ->
			@user_id = "12312"
			@subscription =
				membersLimit: 2
				member_ids: ["", ""]

		it "should return true if the limit is hit", (done)->
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, @subscription)
			@LimitationsManager.hasGroupMembersLimitReached @user_id, (err, limitReached)->
				limitReached.should.equal true
				done()

		it "should return false if the limit is not hit", (done)->
			@subscription.membersLimit = 3
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, @subscription)
			@LimitationsManager.hasGroupMembersLimitReached @user_id, (err, limitReached)->
				limitReached.should.equal false
				done()
				
		it "should return true if the limit has been exceded", (done)->
			@subscription.membersLimit = 0
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, @subscription)
			@LimitationsManager.hasGroupMembersLimitReached @user_id, (err, limitReached)->
				limitReached.should.equal true
				done()
				
	describe "userHasFreeTrial", ->
		beforeEach ->
			@subscription =
				freeTrial: {}
			@SubscriptionLocator.getUsersSubscription.callsArgWith(1, null, @subscription)
			@callback = sinon.stub()

		describe "with free trial which is active", ->
			beforeEach ->
				@subscription.freeTrial =
					expiresAt: new Date(Date.now() + @offset = (6.3 * 24 * 60 * 60 * 1000)) # 6.3 days in future
					downgraded: true
				@LimitationsManager.userHasFreeTrial @user.id, @callback
				
			it "should callback the callback with hasFreeTrial = true, timeRemaining, downgraded = true", ->
				@callback.calledWith(null, true, @offset, true).should.equal true

		describe "with free trial which is downgraded", ->
			beforeEach ->
				@subscription.freeTrial =
					expiresAt: new Date() - 1000
					downgraded: true
				@LimitationsManager.userHasFreeTrial @user.id, @callback
				
			it "should callback the callback with hasFreeTrial = true, downgraded = true", ->
				@callback.calledWith(null, true, -1000, true).should.equal true
	
		describe "without free trial", ->
			beforeEach ->
				@subscription.freeTrial =
					expiresAt: null
					downgraded: false
				@LimitationsManager.userHasFreeTrial @user.id, @callback
				
			it "should callback the callback with hasFreeTrial = false, downgraded = false", ->
				@callback.calledWith(null, false, -1, false).should.equal true
			
		describe "with no subscription object", ->
			beforeEach ->
				@SubscriptionLocator.getUsersSubscription = sinon.stub().callsArg(1)
				@LimitationsManager.userHasFreeTrial @user.id, @callback
				
			it "should callback the callback with hasFreeTrial = false, downgraded = false", ->
				@callback.calledWith(null, false, -1, false).should.equal true