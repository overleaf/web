should = require('chai').should()
modulePath = "../../../../app/js/Features/Project/ProjectApiController"
SandboxedModule = require('sandboxed-module')
sinon = require('sinon')
require('chai').should()

describe 'ProjectApiController', ->

	beforeEach ->
		@ProjectDetailsHandler = 
			getDetails : sinon.stub()
		@controller = SandboxedModule.require modulePath, requires:
			"./ProjectDetailsHandler":@ProjectDetailsHandler
			"./ProjectEntityHandler": @ProjectEntityHandler = {}
			"settings-sharelatex": @Settings =
				apis:
					filestore:
						url: "filestore.example.com"
			'logger-sharelatex':
				log:->
		@project_id = "321l3j1kjkjl"
		@req = 
			params: 
				project_id:@project_id
			session:
				destroy:sinon.stub()
		@res = {}
		@projDetails = {name:"something"}
		@next = sinon.stub()


	describe "getProjectDetails", ->
		it "should ask the project details handler for proj details", (done)->
			@ProjectDetailsHandler.getDetails.callsArgWith(1, null, @projDetails)
			@res.json = (data)=>
				@ProjectDetailsHandler.getDetails.calledWith(@project_id).should.equal true
				data.should.deep.equal @projDetails
				done()
			@controller.getProjectDetails @req, @res

		it "should return next if there is an error", ()->
			@ProjectDetailsHandler.getDetails.callsArgWith(1, @error = "error")
			@controller.getProjectDetails @req, @res, @next
			@next.calledWith(@error).should.equal true
	
	describe "getProjectContent", ->
		beforeEach ->
			@res.json = sinon.stub()
			@docs = {
				"/main.tex": { lines: ["hello", "world"]}
			}
			@files = {
				"/image.png": { _id: @file_id = "file-id-123" }
			}
			@ProjectEntityHandler.getAllDocs = sinon.stub().callsArgWith(1, null, @docs)
			@ProjectEntityHandler.getAllFiles = sinon.stub().callsArgWith(1, null, @files)
			@controller.getProjectContent @req, @res, @next
		
		it "should return an array of resources", ->
			@res.json
				.calledWith(content: [
					{ path: "main.tex", content: "hello\nworld" }
					{ path: "image.png", url: "#{@Settings.apis.filestore.url}/project/#{@project_id}/file/#{@file_id}"}
				])
				.should.equal true
				
