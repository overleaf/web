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
		@file_name = 'somefile.csv'
		@response =
			statusCode: 200
		@preview =
			source: @file_url
			labels: []
			rows: []
			truncated: false

	describe "_build_url", ->

		it "should build a url for the previewer service", (done) ->
			url = @PreviewHandler._build_url(@file_url, @file_name)
			url.should.match(new RegExp("^#{@settings.apis.previewer.url}.*#{@file_url}.*#{@file_name}$"))
			done()

	describe "getPreview", ->

		beforeEach ->
			@request.callsArgWith(1, null, @response, @preview)

		it "should send back the right data", (done) ->
			@PreviewHandler.getPreview @file_url, @file_name, (err, data) =>
				expect(data).to.not.equal null
				expect(data).to.be.Object
				expect(data).to.equal @preview
				done()

		describe "when the remote service responds with an error", ->

			[500, 502, 404, 410, 307].forEach (bad_status_code) ->

				beforeEach ->
					@response.statusCode = bad_status_code

				it "should produce an error", (done) ->
					@PreviewHandler.getPreview @file_url, @file_name, (err, data) =>
						expect(data).to.equal null
						expect(err).to.not.equal null
						expect(err instanceof Error).to.equal true
						done()
