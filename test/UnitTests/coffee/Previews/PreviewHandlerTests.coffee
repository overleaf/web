assert = require("chai").assert
sinon = require('sinon')
chai = require('chai')
should = chai.should()
expect = chai.expect
modulePath = "../../../../app/js/Features/Previews/PreviewHandler.js"
SandboxedModule = require('sandboxed-module')

describe "PreviewHandler", ->

	beforeEach ->
		@PreviewHandler = SandboxedModule.require modulePath, requires:
			"logger-sharelatex": @logger = {log:sinon.stub(), err:sinon.stub()}
			"request": @request = sinon.stub()
			"settings-sharelatex": @settings =
				apis:
					previewer:
						url: "previewerservice:3000"
		@file_url = "http://example.com/somefile.csv"
		@response =
			statusCode: 200
		@preview =
			source: @file_url
			labels: []
			rows: []


	describe "_build_url", ->

		it "should build a url for the previewer service", (done) ->
			url = @PreviewHandler._build_url(@file_url)
			url.should.match(new RegExp("^#{@settings.apis.previewer.url}.*$"))
			done()

	describe "getPreviewCsv", ->

		beforeEach ->
			@request.callsArgWith(1, null, @response, @preview)

		it "should send back the right data", (done) ->
			@PreviewHandler.getPreviewCsv @file_url, (err, data) =>
				expect(data).to.not.equal null
				expect(data).to.be.Object
				expect(data).to.equal @preview
				done()
