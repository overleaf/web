Errors = require "./Errors"
logger = require "logger-sharelatex"
AuthenticationController = require '../Authentication/AuthenticationController'

module.exports = ErrorController =

	_shouldObscureExistenceOfResource: (req) ->
		!!req.url.match(new RegExp('^/project/.*$'))

	notFound: (req, res)->
		template = 'general/404'
		if ErrorController._shouldObscureExistenceOfResource(req)
			template = 'general/404_or_restricted'
		res.status(404)
		res.render template,
			title: "page_not_found"

	serverError: (req, res)->
		res.status(500)
		res.render 'general/500',
			title: "Server Error"

	handleError: (error, req, res, next) ->
		user = AuthenticationController.getSessionUser(req)
		if error?.code is 'EBADCSRFTOKEN'
			logger.warn err: error,url:req.url, method:req.method, user:user, "invalid csrf"
			res.sendStatus(403)
			return
		if error instanceof Errors.NotFoundError
			logger.warn {err: error, url: req.url}, "not found error"
			ErrorController.notFound req, res
		else
			logger.error err: error, url:req.url, method:req.method, user:user, "error passed to top level next middlewear"
			ErrorController.serverError req, res
