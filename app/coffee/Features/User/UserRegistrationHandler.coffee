sanitize = require('sanitizer')
Settings = require('settings-sharelatex')
User = require("../../models/User").User
UserCreator = require("./UserCreator")
AuthenticationManager = require("../Authentication/AuthenticationManager")
NewsLetterManager = require("../Newsletter/NewsletterManager")
EmailHandler = require("../Email/EmailHandler")
async = require("async")
logger = require("logger-sharelatex")

module.exports =
	validateEmail : (email) ->
		re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\ ".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA -Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
		return re.test(email)

	hasZeroLengths : (props) ->
		hasZeroLength = false
		props.forEach (prop) ->
			if prop.length == 0
				hasZeroLength = true
		return hasZeroLength

	_registrationRequestIsValid : (body, callback)->
		email = sanitize.escape(body.email).trim().toLowerCase()
		password = body.password
		username = email.match(/^[^@]*/)
		domain = email.match(/[^@]*$/)
		domain = domain[0] if domain?
		if @hasZeroLengths([password, email])
			return "Password/email cannot be empty"
		else if !@validateEmail(email)
			return "Invalid email"
		else if Settings.signupDomain? and Settings.signupDomain != domain
			return "Invalid domain. Only emails ending with @"+Settings.signupDomain+" accepted."
		else
			return "OK"

	_createNewUserIfRequired: (user, userDetails, callback)->
		if !user?
			UserCreator.createNewUser {holdingAccount:false, email:userDetails.email, confirmed:userDetails.confirmed}, (error,user) ->
				if user? and Settings.requireRegistrationConfirmation
					AuthenticationManager.getAuthToken user._id, (error, auth_token)->
						if !error?
							user.auth_token = auth_token
						callback error, user
				else
					callback error, user
		else
			callback null, user

	registerNewUser: (userDetails, callback)->
		self = @
		validationResult = @_registrationRequestIsValid userDetails
		if validationResult != "OK"
			return callback(new Error(validationResult))
		userDetails.email = userDetails.email?.trim()?.toLowerCase()
		User.findOne email:userDetails.email, (err, user)->
			if err?
				return callback err
			if user?.holdingAccount == false
				return callback(new Error("EmailAlreadyRegistered"), user)
			self._createNewUserIfRequired user, userDetails, (err, user)->
				if err?
					return callback(err)
				async.series [
					(cb)-> User.update {_id: user._id}, {"$set":{holdingAccount:false}}, cb
					(cb)-> AuthenticationManager.setUserPassword user._id, userDetails.password, cb
					(cb)-> NewsLetterManager.subscribe user, cb
					(cb)->
						emailOpts =
							first_name:user.first_name
							to: user.email
							auth_token:user.auth_token
						EmailHandler.sendEmail "welcome", emailOpts, cb
				], (err)->
					logger.log user: user, "registered"
					callback(err, user)
