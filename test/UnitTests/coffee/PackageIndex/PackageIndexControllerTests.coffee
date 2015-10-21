assert = require("chai").assert
sinon = require('sinon')
chai = require('chai')
should = chai.should()
expect = chai.expect
modulePath = "../../../../app/js/Features/PackageIndex/PackageIndexController.js"
SandboxedModule = require('sandboxed-module')

describe "PackageIndexController", ->

	beforeEach ->
		@PackageIndexHandler =
			search: sinon.stub()
		@controller = SandboxedModule.require modulePath, requires:
			"logger-sharelatex" : @logger = {log:sinon.stub(), err:sinon.stub()}
			"./PackageIndexHandler": @PackageIndexHandler
		@search_params =
			language: 'python',
			query: 'somepackage'
		@req =
			body: @search_params
		@res =
			setHeader: sinon.stub()
		@search_result =
			results: [],
			searchParams: {}

	describe "search", ->

		beforeEach ->
			@PackageIndexHandler.search.callsArgWith(2, null, @search_result)

		it "should send back some data", (done) ->
			@res.status = (code) =>
				send: (data) =>
					expect(code).to.equal 200
					expect(data).to.be.Object
					expect(data).to.deep.equal @search_result
					done()
			@controller.search @req, @res
