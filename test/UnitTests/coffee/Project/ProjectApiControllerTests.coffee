should = require('chai').should()
modulePath = "../../../../app/js/Features/Project/ProjectApiController"
SandboxedModule = require('sandboxed-module')
sinon = require('sinon')
require('chai').should()

describe 'Project api controller', ->

	beforeEach ->
		@ProjectDetailsHandler = 
			getDetails : sinon.stub()
		@TagsHandler =
			getAllTags: sinon.stub()
		@ProjectModel =
			findAllUsersProjects: sinon.stub()
		@ProjectController = 
			_buildProjectList: sinon.stub()
		@controller = SandboxedModule.require modulePath, requires:
			"./ProjectDetailsHandler":@ProjectDetailsHandler
			"../Tags/TagsHandler":@TagsHandler
			"../../models/Project": Project:@ProjectModel
			"./ProjectController": @ProjectController
			'logger-sharelatex':
				log:->
		@res = {}

	describe "getProjectDetails", ->
	
		beforeEach ->
			@project_id = "321l3j1kjkjl"
			@req = 
				params: 
					project_id:@project_id
				session:
					destroy:sinon.stub()
			@projDetails = {name:"something"}

		it "should ask the project details handler for proj details", (done)->
			@ProjectDetailsHandler.getDetails.callsArgWith(1, null, @projDetails)
			@res.json = (data)=>
				@ProjectDetailsHandler.getDetails.calledWith(@project_id).should.equal true
				data.should.deep.equal @projDetails
				done()
			@controller.getProjectDetails @req, @res

		it "should send a 500 if there is an error", (done)->
			@ProjectDetailsHandler.getDetails.callsArgWith(1, "error")
			@res.send = (resCode)=>
				resCode.should.equal 500
				done()
			@controller.getProjectDetails @req, @res

		it "should destroy the session", (done)->
			@ProjectDetailsHandler.getDetails.callsArgWith(1, null, @projDetails)
			@res.json = (data)=>
				@req.session.destroy.called.should.equal true
				done()
			@controller.getProjectDetails @req, @res
			
	describe "getProjectList", ->
	
		beforeEach ->
			@req = 
				params: 
					[]
				session:
					destroy:sinon.stub()
				user:
					_id:null
					
			@tags = [{name:1, project_ids:["1","2","3"]}, {name:2, project_ids:["a","1"]}, {name:3, project_ids:["a", "b", "c", "d"]}]
			@projects = [{lastUpdated:1, _id:1, owner_ref: "user-1"}, {lastUpdated:2, _id:2, owner_ref: "user-2"}]
			@collaborations = [{lastUpdated:5, _id:5, owner_ref: "user-1"}]
			@readOnly = [{lastUpdated:3, _id:3, owner_ref: "user-1"}]
			@allProjects = @projects.concat @collaborations.concat @readOnly

			@TagsHandler.getAllTags.callsArgWith(1, null, @tags, {})
			@ProjectModel.findAllUsersProjects.callsArgWith(2, null, @projects, @collaborations, @readOnly)
	
		it "should send the tags", (done)->
			@res.json = (data)=>
				data.tags.length.should.equal @tags.length
				done()
			@controller.getProjectList @req, @res

		it "should send the projects", (done)->
			@ProjectController._buildProjectList.returns(@allProjects)
			@res.json = (data)=>
				data.projects.length.should.equal (@projects.length + @collaborations.length + @readOnly.length)
				done()
			@controller.getProjectList @req, @res
			