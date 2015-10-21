assert = require("chai").assert
sinon = require('sinon')
chai = require('chai')
should = chai.should()
expect = chai.expect
modulePath = "../../../../app/js/Features/PackageIndex/PackageIndexHandler.js"
SandboxedModule = require('sandboxed-module')

describe "PackageIndexHandler", ->

	beforeEach ->
		@request = sinon.stub()
		@settings =
			apis:
				packageindexer:
					url: 'indexer.example.com'
		@handler = SandboxedModule.require modulePath, requires:
			"logger-sharelatex" : @logger = {log:sinon.stub(), err:sinon.stub()}
			"request": @request
			"settings-sharelatex": @settings
		@search_response =
			statusCode: 200
		@search_result =
			results: [],
			searchParams: {}

	describe "search", ->

		beforeEach ->
			@request.callsArgWith(1, null, @search_response, @search_result)

		it "should send back the search result", (done) ->
			@handler.search "python", "somepackage", (err, result) =>
				expect(err).to.equal null
				expect(result).to.deep.equal @search_result
				expect(@request.calledOnce).to.equal true
				done()

		describe "when the request errors out", ->

			beforeEach ->
				@request.callsArgWith(1, new Error("request error"), null, null)

			it "should produce an error", (done) ->
				@handler.search "python", "somepackage", (err, result) =>
					expect(err).to.not.equal null
					expect(err).to.be.Error
					expect(result).to.equal null
					done()

		describe "when the remote service produces an error", ->

			beforeEach ->
				@search_response.statusCode = 404
				@request.callsArgWith(1, null, @search_response, @search_result)

			it "should produce an error", (done) ->
				@handler.search "python", "somepackage", (err, result) =>
					expect(err).to.not.equal null
					expect(result).to.equal null
					done()
