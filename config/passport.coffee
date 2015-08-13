GoogleStrategy 	= require('passport-google-oauth').OAuth2Strategy

User	= require '../models/User'
configAuth = require './auth'

module.exports = (passport) ->
	passport.serializeUser (user,done)->
		done null,user.id
	passport.deserializeUser (id,done)->
		done err,user

	passport.use new GoogleStrategy {
		clientID		: configAuth.googleAuth.clientID,
    	clientSecret	: configAuth.googleAuth.clientSecret
    	callbackURL		: configAuth.googleAuth.callbackURL
		},(token,secretToken,profile,done)->
			process.nextTick ()->
				User.findOne {'google.id' : profile.id}, (err,user)->
					if err
						done err
					if user
						done null,user
					else
						newUser = new User
						newUser.google.id = profile.id
						newUser.google.name = profile.displayName
						newUser.google.email = profile.emails[0].value
						newUser.google.token = token
						newUser.save (err)->
							if err
								throw err
							done(null, newUser)


		
	
