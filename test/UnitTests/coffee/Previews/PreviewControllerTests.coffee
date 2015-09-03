assert = require("chai").assert
sinon = require('sinon')
chai = require('chai')
should = chai.should()
expect = chai.expect
modulePath = "../../../../app/js/Features/Previews/PreviewController.js"
SandboxedModule = require('sandboxed-module')

describe "PreviewController", ->

	beforeEach ->
		@PreviewHandler =
			getPreviewCsv: sinon.stub()
		@ProjectLocator =
			findElement: sinon.stub()
		@FileStoreHandler =
			_buildUrl: sinon.stub()
		@controller = SandboxedModule.require modulePath, requires:
			"logger-sharelatex" : @logger = {log:sinon.stub(), err:sinon.stub()}
			"../Project/ProjectLocator": @ProjectLocator
			"./PreviewHandler": @PreviewHandler
			"../FileStore/FileStoreHandler": @FileStoreHandler
		@project_id = "someproject"
		@file_id = "somefile"
		@req =
			params:
				Project_id: @project_id
				file_id: @file_id
			query: "query_string_here"
			get: (key) -> undefined
		@res =
			setHeader: sinon.stub()
		@file =
			name: 'somefile.csv'
		@preview =
			source: "somewhere"
			labels: []
			rows: []

	describe "getPreviewCsv", ->

		beforeEach ->
			@ProjectLocator.findElement.callsArgWith(1, null, @file)
			@PreviewHandler.getPreviewCsv.callsArgWith(1, null, @preview)


		it "should send back some data", (done) ->
			@res.send = (data) =>
				expect(data).to.not.equal null
				data.should.be.Object
				done()
			@controller.getPreviewCsv @req, @res


		it "should use FileStoreHandler._buildUrld to build a url", (done) ->
			@res.send = (data) =>
				@FileStoreHandler._buildUrl.calledWith(@project_id, @file_id).should.equal true
				done()
			@controller.getPreviewCsv @req, @res


		it "should use the ProjectLocator to check if the resource exists", (done) ->
			@res.send = (data) =>
				expected_options=
					project_id: @project_id
					element_id: @file_id
					type: 'file'
				@ProjectLocator.findElement.calledWith(expected_options).should.equal true
				done()
			@controller.getPreviewCsv @req, @res

		it "should use the PreviewHandler to get the preview object", (done) ->
			@res.send = (data) =>
				@PreviewHandler.getPreviewCsv.calledOnce.should.equal true
				done()
			@controller.getPreviewCsv @req, @res

		describe "when the ProjectLocator can't find the file", ->

			beforeEach ->
				@ProjectLocator.findElement.callsArgWith(1, new Error('not found'), null)

			it "should respond with a 500", (done) ->
				@res.sendStatus = (code) ->
					code.should.equal 500
					done()
				@controller.getPreviewCsv @req, @res

		describe "when the PreviewHandler produces an error", ->

			beforeEach ->
				@PreviewHandler.getPreviewCsv.callsArgWith(1, new Error('not found'), null)

			it "should respond with a 500", (done) ->
				@res.sendStatus = (code) ->
					code.should.equal 500
					done()
				@controller.getPreviewCsv @req, @res
