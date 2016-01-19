AuthenticationManager = require ("./AuthenticationManager")
LoginRateLimiter = require("../Security/LoginRateLimiter")

User = require("../../models/User").User
UserGetter = require "../User/UserGetter"
UserUpdater = require "../User/UserUpdater"
UserRegistrationHandler = require "../User/UserRegistrationHandler"

AuthenticationController = require "./AuthenticationController"

Metrics = require('../../infrastructure/Metrics')
crypto = require("crypto")
logger = require("logger-sharelatex")
querystring = require('querystring')

Url = require("url")
Settings = require "settings-sharelatex"
basicAuth = require('basic-auth-connect')
OAuth = require('simple-oauth2');
Settings = require('settings-sharelatex')


OAuthController =
	login: (req, res, next = (error) ->) ->
		oauth2 = OAuthController.oauth_core()
		authorization_uri = oauth2.authCode.authorizeURL({
		  redirect_uri: OAuthController.redirect_url(),
		  scope: Settings.oauth.scope,
		})

		res.redirect(authorization_uri)

	oauth_core: ->
		credentials = {
		  clientID: Settings.oauth.client_id,
		  clientSecret: Settings.oauth.client_secret,
		  site: Settings.oauth.base_url
		}

		return OAuth(credentials)

	redirect_url: ->
		return Settings.apis.web.url + '/oauth/callback'

	callback: (req, res) ->
		code = req.query.code
		oauth2 = OAuthController.oauth_core()

		oauth2.authCode.getToken {
			  code: code,
			  redirect_uri: OAuthController.redirect_url()

			},

			(error, result) ->
		  		if error
		    		console.log 'Access Token Error', error.message
		  
		  		token = oauth2.accessToken.create(result)
		  		console.log 'token: ', token
		  		oauth2.api 'GET', '/user', { access_token: token.token.access_token }, (err, data) -> OAuthController.handle_user_data(req, res, err, data)
   	

	login_user: (req, res, user) ->
		LoginRateLimiter.recordSuccessfulLogin user.email
		AuthenticationController._recordSuccessfulLogin user._id
		AuthenticationController.establishUserSession req, user, (error) ->
			if error?
				return error 
			req.session.justLoggedIn = true
		logger.log email: user.email, user_id: user._id.toString(), "successful log in"
		res.redirect Url.parse("/project").path


	handle_user_data: (req, res, error, data) ->
		if error
    		console.log 'User Data Access Error', error.message

    	console.log(data.principal)
    	
    	email = data.principal.email
    	fname = data.principal.name
    	sname = data.principal.surname

    	User.findOne email: email, (err, user)->
			if user?
    			# handle user perform login
    			logger.log {email}, "matched existing user via oauth"
    			OAuthController.login_user user
    		else
    			# register user
    			logger.log {email}, "registering new user via oauth"

    			usr = email: email, password: crypto.randomBytes(32).toString("hex")

				console.log(usr)
				UserRegistrationHandler.registerNewUser usr, (err, user2) ->
					if err?
		    			console.log(err.message)
					user2.first_name = fname
					user2.last_name  = sname
					user2.save()
					OAuthController.login_user(req, res, user2)

module.exports = OAuthController