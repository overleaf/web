GoogleStrategy 				= require('passport-google-oauth').OAuth2Strategy
AuthenticationController 	= require './AuthenticationController'

User	= require('../../models/User').User
Settings = require 'settings-sharelatex'
configAuth = Settings

module.exports = (passport) ->
	passport.serializeUser (user,done)->
		done null,user.id
	passport.deserializeUser (id,done)->
		User.findById id,(err,user)->
			done err,user

	passport.use new GoogleStrategy {
    	clientID		: configAuth.googleAuth.clientID,
    	clientSecret	: configAuth.googleAuth.clientSecret
    	callbackURL		: configAuth.googleAuth.callbackURL
	},(token,secretToken,profile,done)->
			# console.log req, res, profile
			process.nextTick ()->

				User.findOne {'google.id' : profile.id}, (err,user)->
					if err
						done err
					if user
						done null,user
					else
						newUser = new User
						newUser.google.id = profile.id
						newUser.google.name = newUser.firstName = profile.displayName
						newUser.google.email = newUser.email = profile.emails[0].value
						newUser.google.token = token
						newUser.confirmed = true

						newUser.save (err)->
							if err
								throw err
							done(null, newUser)


		
	
