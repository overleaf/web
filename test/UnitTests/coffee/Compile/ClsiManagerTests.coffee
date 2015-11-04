sinon = require('sinon')
chai = require('chai')
should = chai.should()
expect = chai.expect
modulePath = "../../../../app/js/Features/Compile/ClsiManager.js"
SandboxedModule = require('sandboxed-module')

describe "ClsiManager", ->
	beforeEach ->
		@ClsiManager = SandboxedModule.require modulePath, requires:
			"settings-sharelatex": @settings =
				apis:
					filestore:
						url: "filestore.example.com"
						secret: "secret"
					clsi:
						url: "http://clsi.example.com"
					clsi_priority:
						url: "https://clsipremium.example.com"
			"../../models/Project": Project: @Project = {}
			"../Project/ProjectEntityHandler": @ProjectEntityHandler = {}
			"logger-sharelatex": @logger = { log: sinon.stub(), error: sinon.stub() }
			"request": @request = {}
		@project_id = "project-id"
		@request_id = "mock-session-123"
		@callback = sinon.stub()

	describe "sendRequest", ->
		beforeEach ->
			@ClsiManager._buildRequest = sinon.stub().callsArgWith(3, null, @request = "mock-request")

		describe "with a successful compile", ->
			beforeEach ->
				@ClsiManager._postToClsi = sinon.stub().callsArgWith(3, null, {
					compile:
						status: @status = "success"
						outputFiles: [{
							url: "#{@settings.apis.clsi.url}/project/#{@project_id}/output/output.pdf"
							type: "pdf"
							build: 1234
						},{
							url: "#{@settings.apis.clsi.url}/project/#{@project_id}/output/output.log"
							type: "log"
							build: 1234
						}]
						output: @output = "mock output"
				})
				@ClsiManager.sendRequest @project_id, @request_id, {compileGroup:"standard"}, @callback

			it "should build the request", ->
				@ClsiManager._buildRequest
					.calledWith(@project_id, @request_id)
					.should.equal true

			it "should send the request to the CLSI", ->
				@ClsiManager._postToClsi
					.calledWith(@project_id, @request, "standard")
					.should.equal true

			it "should call the callback with the status and output files", ->
				outputFiles = [{
					path: "output.pdf"
					type: "pdf"
					build: 1234
				},{
					path: "output.log"
					type: "log"
					build: 1234
				}]
				@callback.calledWith(null, @status, outputFiles, @output).should.equal true

		describe "with a failed compile", ->
			beforeEach ->
				@ClsiManager._postToClsi = sinon.stub().callsArgWith(3, null, {
					compile:
						status: @status = "failure"
				})
				@ClsiManager.sendRequest @project_id, @request_id, {}, @callback
			
			it "should call the callback with a failure statue", ->
				@callback.calledWith(null, @status).should.equal true

	describe "deleteAuxFiles", ->
		beforeEach ->
			@request.del = sinon.stub().callsArg(1)
			
		describe "with the standard compileGroup", ->
			beforeEach ->
				@ClsiManager.deleteAuxFiles @project_id, {compileGroup: "standard"}, @callback

			it "should call the delete method in the standard CLSI", ->
				@request.del
					.calledWith("#{@settings.apis.clsi.url}/project/#{@project_id}")
					.should.equal true

			it "should call the callback", ->
				@callback.called.should.equal true
				
		describe "with the priority compileGroup", ->
			beforeEach ->
				@ClsiManager.deleteAuxFiles @project_id, {compileGroup: "priority"}, @callback

			it "should call the delete method in the CLSI", ->
				@request.del
					.calledWith("#{@settings.apis.clsi_priority.url}/project/#{@project_id}")
					.should.equal true

	describe "_buildRequest", ->
		beforeEach ->
			@project =
				_id: @project_id
				compiler: @compiler = "latex"
				rootDoc_id: "mock-doc-id-1"

			@docs = {
				"/main.tex": @doc_1 = {
					name: "main.tex"
					_id: "mock-doc-id-1"
					lines: ["Hello", "world"]
				},
				"/chapters/chapter1.tex": @doc_2 = {
					name: "chapter1.tex"
					_id: "mock-doc-id-2"
					lines: [
						"Chapter 1"
					]
				}
			}

			@files = {
				"/images/image.png": @file_1 = {
					name: "image.png"
					_id:  "mock-file-id-1"
					created: new Date()
				}
			}

			@Project.findById = sinon.stub().callsArgWith(2, null, @project)
			@ProjectEntityHandler.getAllDocs = sinon.stub().callsArgWith(1, null, @docs)
			@ProjectEntityHandler.getAllFiles = sinon.stub().callsArgWith(1, null, @files)

		describe "with a valid project", ->
			beforeEach (done) ->
				options = {
					timeout:    @timeout = 42
					memory:     @memory = 1024
					processes:  @processes = 57
					cpu_shares: @cpu_shares = 456
				}
				@ClsiManager._buildRequest @project_id, @request_id, options, (error, request) =>
					@request = request
					done()

			it "should get the project with the required fields", ->
				@Project.findById
					.calledWith(@project_id, {compiler:1, rootDoc_id: 1})
					.should.equal true

			it "should get all the docs", ->
				@ProjectEntityHandler.getAllDocs
					.calledWith(@project_id)
					.should.equal true

			it "should get all the files", ->
				@ProjectEntityHandler.getAllFiles
					.calledWith(@project_id)
					.should.equal true

			it "should build up the CLSI request", ->
				expect(@request).to.deep.equal(
					compile:
						request_id: @request_id
						options:
							compiler: @compiler
							command: undefined
							env: undefined
							package: undefined
							timeout : @timeout
							memory:     @memory
							processes:  @processes
							cpu_shares: @cpu_shares
							imageName: undefined
						rootResourcePath: "main.tex"
						resources: [{
							path:    "main.tex"
							content: @doc_1.lines.join("\n")
						}, {
							path:    "chapters/chapter1.tex"
							content: @doc_2.lines.join("\n")
						}, {
							path: "images/image.png"
							url:  "#{@settings.apis.filestore.url}/project/#{@project_id}/file/#{@file_1._id}"
							modified: @file_1.created.getTime()
						}]
				)


		describe "when root doc override is valid", ->
			beforeEach (done) ->
				@ClsiManager._buildRequest @project_id, @request_id, {rootDoc_id:"mock-doc-id-2"}, (error, request) =>
					@request = request
					done()

			it "should change root path", ->
				@request.compile.rootResourcePath.should.equal "chapters/chapter1.tex"


		describe "when root doc override is invalid", ->
			beforeEach (done) ->
				@ClsiManager._buildRequest @project_id, @request_id, {rootDoc_id:"invalid-id"}, (error, request) =>
					@request = request
					done()

			it "should fallback to default root doc", ->
				@request.compile.rootResourcePath.should.equal "main.tex"



		describe "when the project has an invalid compiler", ->
			beforeEach (done) ->
				@project.compiler = "context"
				@ClsiManager._buildRequest @project_id, @request_id, null, (error, request) =>
					@request = request
					done()

			it "should set the compiler to pdflatex", ->
				@request.compile.options.compiler.should.equal "pdflatex"

		# Not applicable in datajoy:
		# we don't want it to be a problem if we just want to run a standalone command (i.e. conda install PACKAGE)
		#
		# describe "when there is no valid root document", ->
		# 	beforeEach (done) ->
		# 		@project.rootDoc_id = "not-valid"
		# 		@ClsiManager._buildRequest @project, @request_id, null, (@error, @request) =>
		# 			done()
			
		# 	it "should return an error", ->
		# 		expect(@error).to.exist
				
		describe "with a python file as the root doc", ->
			beforeEach (done) ->
				@project =
					_id: @project_id
					compiler: @compiler = "latex"
					rootDoc_id: "mock-doc-id-1"
				@docs = {
					"/main.py": @doc_1 = {
						name: "main.py"
						_id: "mock-doc-id-1"
						lines: ["Hello", "world"]
					}
				}
				@files = {}

				@Project.findById = sinon.stub().callsArgWith(2, null, @project)
				@ProjectEntityHandler.getAllDocs = sinon.stub().callsArgWith(1, null, @docs)
				@ProjectEntityHandler.getAllFiles = sinon.stub().callsArgWith(1, null, @files)
				
				@ClsiManager._buildRequest @project, @request_id, null, (@error, @request) =>
					done()
					
			it "should set the compiler to python", ->
				@request.compile.options.compiler.should.equal "python"


	describe '_postToClsi', ->
		beforeEach ->
			@req = { mock: "req" }

		describe "successfully", ->
			beforeEach ->
				@request.post = sinon.stub().callsArgWith(1, null, {statusCode: 204}, @body = { mock: "foo" })
				@ClsiManager._postToClsi @project_id, @req, "standard", @callback

			it 'should send the request to the CLSI', ->
				url = "#{@settings.apis.clsi.url}/project/#{@project_id}/compile"
				@request.post.calledWith({
					url: url
					json: @req
					jar: false
				}).should.equal true

			it "should call the callback with the body and no error", ->
				@callback.calledWith(null, @body).should.equal true

		describe "when the CLSI returns an error", ->
			beforeEach ->
				@request.post = sinon.stub().callsArgWith(1, null, {statusCode: 500}, @body = { mock: "foo" })
				@ClsiManager._postToClsi @project_id, @req, "standard", @callback

			it "should call the callback with the body and the error", ->
				@callback.calledWith(new Error("CLSI returned non-success code: 500"), @body).should.equal true

		describe "when the compiler is priority", ->
			beforeEach ->
				@request.post = sinon.stub().callsArgWith(1, null, {statusCode: 500}, @body = { mock: "foo" })
				@ClsiManager._postToClsi @project_id, @req, "priority", @callback

			it "should use the clsi_priority url", ->
				url = "#{@settings.apis.clsi_priority.url}/project/#{@project_id}/compile"
				@request.post.calledWith({
					url: url
					json: @req
					jar: false
				}).should.equal true
	
	describe "sendJupyterRequest", ->
		beforeEach ->
			@limits = {mock: "limits"}
			@request_id = "message-123"
			@engine = "python"
			@msg_type = "execute_request"
			@content = {mock: "Content"}
			@resources = ["mock", "resources"]
			@request.post = sinon.stub().callsArgWith(1, null, {statusCode: 204}, @body = { mock: "foo" })
			@ClsiManager._buildResources = sinon.stub().callsArgWith(1, null, @resources)
			@ClsiManager.sendJupyterRequest @project_id, @request_id, @engine, @msg_type, @content, @limits, @callback
		
		it "should get the project resources", ->
			@ClsiManager._buildResources
				.calledWith(@project_id)
				.should.equal true
		
		it "should send a request to the CLSI", ->
			@request.post
				.calledWith({
					url: "#{@settings.apis.clsi.url}/project/#{@project_id}/request"
					json: {
						msg_type: @msg_type
						content: @content,
						request_id: @request_id,
						engine: @engine,
						limits: @limits,
						resources: @resources
					}
					jar: false
				})
				.should.equal true
		
		it "should call the callback", ->
			@callback.called.should.equal true

	describe "sendJupyterReply", ->
		beforeEach ->
			@engine = "python"
			@msg_type = "execute_request"
			@content = {mock: "Content"}
			@resources = ["mock", "resources"]
		
		describe "with a successful response", ->
			beforeEach ->
				@request.post = sinon.stub().callsArgWith(1, null, {statusCode: 204}, @body = { mock: "foo" })
				@ClsiManager.sendJupyterReply @project_id, @engine, @msg_type, @content, @callback
			
			it "should send a request to the CLSI", ->
				@request.post
					.calledWith({
						url: "#{@settings.apis.clsi.url}/project/#{@project_id}/reply"
						json: {
							msg_type: @msg_type
							content: @content,
							engine: @engine
						}
						jar: false
					})
					.should.equal true
			
			it "should call the callback", ->
				@callback.calledWith(null).should.equal true
		
		describe "with a non-success response", ->
			beforeEach ->
				@request.post = sinon.stub().callsArgWith(1, null, {statusCode: 500}, @body = { mock: "foo" })
				@ClsiManager.sendJupyterReply @project_id, @engine, @msg_type, @content, @callback
			
			it "should call the callback with an error", ->
				@callback.calledWith(new Error("CLSI returned non-success code: 500")).should.equal true

	describe "interruptRequest", ->
		beforeEach ->
			@request_id = "message-123"
			@request.post = sinon.stub().callsArgWith(1, null, {statusCode: 204}, {})
			@ClsiManager.interruptRequest @project_id, @request_id, @callback
		
		it "should send a request to the CLSI", ->
			@request.post
				.calledWith({
					url: "#{@settings.apis.clsi.url}/project/#{@project_id}/request/#{@request_id}/interrupt"
					jar: false
				})
				.should.equal true
		
		it "should call the callback", ->
			@callback.called.should.equal true
			
