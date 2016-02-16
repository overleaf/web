logger = require 'logger-sharelatex'
fs = require 'fs'
crypto = require 'crypto'
Settings = require('settings-sharelatex')
SubscriptionFormatters = require('../Features/Subscription/SubscriptionFormatters')
querystring = require('querystring')
SystemMessageManager = require("../Features/SystemMessages/SystemMessageManager")
UserGetter = require "../Features/User/UserGetter"
_ = require("underscore")
Modules = require "./Modules"

fingerprints = {}
Path = require 'path'
jsPath =
	if Settings.useMinifiedJs
		"/minjs/"
	else
		"/js/"

logger.log "Generating file fingerprints..."
for path in [
	"#{jsPath}libs/require.js",
	"#{jsPath}ide.js",
	"#{jsPath}main.js",
	"#{jsPath}libs.js",
	"#{jsPath}ace/ace.js",
	"#{jsPath}libs/pdfjs-1.3.91/pdf.js",
	"#{jsPath}libs/pdfjs-1.3.91/pdf.worker.js",
	"#{jsPath}libs/pdfjs-1.3.91/compatibility.js",
	"/stylesheets/style.css"
]
	filePath = Path.join __dirname, "../../../", "public#{path}"
	exists = fs.existsSync filePath
	if exists
		content = fs.readFileSync filePath
		hash = crypto.createHash("md5").update(content).digest("hex")
		logger.log "#{filePath}: #{hash}"
		fingerprints[path] = hash
	else
		logger.log filePath:filePath, "file does not exist for fingerprints"
	

module.exports = (app, webRouter, apiRouter)->
	webRouter.use (req, res, next)->
		res.locals.session = req.session
		next()

	webRouter.use (req, res, next)-> 
		res.locals.jsPath = jsPath
		next()

	webRouter.use (req, res, next)-> 
		res.locals.settings = Settings
		next()

	webRouter.use (req, res, next)->
		res.locals.translate = (key, vars = {}) ->
			vars.appName = Settings.appName
			req.i18n.translate(key, vars)
		res.locals.currentUrl = req.originalUrl
		next()

	webRouter.use (req, res, next)->
		res.locals.getSiteHost = ->
			Settings.siteUrl.substring(Settings.siteUrl.indexOf("//")+2)
		next()

	webRouter.use (req, res, next)->
		res.locals.formatProjectPublicAccessLevel = (privilegeLevel)->
			formatedPrivileges = private:"Private", readOnly:"Public: Read Only", readAndWrite:"Public: Read and Write"
			return formatedPrivileges[privilegeLevel] || "Private"
		next()

	webRouter.use (req, res, next)-> 
		res.locals.buildReferalUrl = (referal_medium) ->
			url = Settings.siteUrl
			if req.session? and req.session.user? and req.session.user.referal_id?
				url+="?r=#{req.session.user.referal_id}&rm=#{referal_medium}&rs=b" # Referal source = bonus
			return url
		res.locals.getReferalId = ->
			if req.session? and req.session.user? and req.session.user.referal_id
				return req.session.user.referal_id
		res.locals.getReferalTagLine = ->
			tagLines = [
				"Roar!"
				"Shout about us!"
				"Please recommend us"
				"Tell the world!"
				"Thanks for using ShareLaTeX"
			]
			return tagLines[Math.floor(Math.random()*tagLines.length)]
		res.locals.getRedirAsQueryString = ->
			if req.query.redir?
				return "?#{querystring.stringify({redir:req.query.redir})}"
			return ""

		res.locals.getLoggedInUserId = ->
			return req.session.user?._id
		next()

	webRouter.use (req, res, next) ->
		res.locals.csrfToken = req?.csrfToken()
		next()

	webRouter.use (req, res, next) ->
		res.locals.getReqQueryParam = (field)->
			return req.query?[field]
		next()

	webRouter.use (req, res, next)-> 
		res.locals.fingerprint = (path) ->
			if fingerprints[path]?
				return fingerprints[path]
			else
				logger.err "No fingerprint for file: #{path}"
				return ""
		next()

	webRouter.use (req, res, next)-> 
		res.locals.formatPrice = SubscriptionFormatters.formatPrice
		next()

	webRouter.use (req, res, next)->
		res.locals.externalAuthenticationSystemUsed = ->
			Settings.ldap?
		next()

	webRouter.use (req, res, next)->
		if req.session.user?
			# We have to make these methods so that we only clear the temporary
			# session flag when it is actually called when rendering a page,
			# so that we can pass through redirects without clearing them.
			res.locals.justRegistered = () ->
				result = !!req.session.justRegistered
				delete req.session.justRegistered
				return result
			res.locals.justLoggedIn = () ->
				result = !!req.session.justLoggedIn
				delete req.session.justLoggedIn
				return result
		res.locals.gaToken       = Settings.analytics?.ga?.token
		res.locals.tenderUrl     = Settings.tenderUrl
		res.locals.sentrySrc     = Settings.sentry?.src
		res.locals.sentryPublicDSN = Settings.sentry?.publicDSN
		next()

	webRouter.use (req, res, next) ->
		if req.query? and req.query.scribtex_path?
			res.locals.lookingForScribtex = true
			res.locals.scribtexPath = req.query.scribtex_path
		next()

	webRouter.use (req, res, next) ->
		# Clone the nav settings so they can be modified for each request
		res.locals.nav = {}
		for key, value of Settings.nav
			res.locals.nav[key] = _.clone(Settings.nav[key])
		res.locals.templates = Settings.templateLinks
		next()
		
	webRouter.use (req, res, next) ->
		SystemMessageManager.getMessages (error, messages = []) ->
			res.locals.systemMessages = messages
			next()

	webRouter.use (req, res, next)->
		res.locals.query = req.query
		next()

	webRouter.use (req, res, next)->
		subdomain = _.find Settings.i18n.subdomainLang, (subdomain)->
			subdomain.lngCode == req.showUserOtherLng and !subdomain.hide
		res.locals.recomendSubdomain = subdomain
		res.locals.currentLngCode = req.lng
		next()

	webRouter.use (req, res, next) ->
		if Settings.reloadModuleViewsOnEachRequest
			Modules.loadViewIncludes()
		res.locals.moduleIncludes = Modules.moduleIncludes
		res.locals.moduleIncludesAvailable = Modules.moduleIncludesAvailable
		next()
	
	webRouter.use (req, res, next) ->
		if req.session.user? and !req.session.use_case?
			UserGetter.getUser req.session.user._id, {use_case: 1}, (error, user) ->
				return next(error) if error?
				req.session.use_case = res.locals.use_case = (user.use_case or "")
				next()
		else
			res.locals.use_case = req.session.use_case
			next()
				 

