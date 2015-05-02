sanitize = require('sanitizer')
User = require("../../models/User").User
UserCreator = require("./UserCreator")
AuthenticationManager = require("../Authentication/AuthenticationManager")
NewsLetterManager = require("../Newsletter/NewsletterManager")
async = require("async")
EmailHandler = require("../Email/EmailHandler")
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
		if @hasZeroLengths([password, email])
			return false
		else if !@validateEmail(email)
			return false
		else
			return true

	_createNewUserIfRequired: (user, userDetails, callback)->
		if !user?
			UserCreator.createNewUser {holdingAccount:false, email:userDetails.email}, (error,user) ->
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
			return callback(validationResult)
		userDetails.email = userDetails.email?.trim()?.toLowerCase()
		User.findOne email:userDetails.email, (err, user)->
			if err?
				return callback err
			if user?.holdingAccount == false
				return callback("EmailAlreadyRegisterd")
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




