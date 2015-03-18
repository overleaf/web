Settings = require 'settings-sharelatex'
User = require("../../models/User").User
{db, ObjectId} = require("../../infrastructure/mongojs")
crypto = require 'crypto'
bcrypt = require 'bcrypt'

logger = require("logger-sharelatex")

module.exports = AuthenticationManager =
	authenticate: (query, password, callback = (error, user) ->) ->
		# Using Mongoose for legacy reasons here. The returned User instance
		# gets serialized into the session and there may be subtle differences
		# between the user returned by Mongoose vs mongojs (such as default values)
		User.findOne query, (error, user) =>
			return callback(error) if error?
			if user?
				if user.hashedPassword?
					bcrypt.compare password, user.hashedPassword, (error, match) ->
						return callback(error) if error?
						if match
							callback null, user
						else
							callback null, null
				else
					callback null, null
			else
				callback null, null

	setUserPassword: (user_id, password, callback = (error) ->) ->
		bcrypt.genSalt 7, (error, salt) ->
			return callback(error) if error?
			bcrypt.hash password, salt, (error, hash) ->
				return callback(error) if error?
				db.users.update({
					_id: ObjectId(user_id.toString())
				}, {
					$set: hashedPassword: hash
					$unset: password: true
				}, callback)

	getAuthToken: (user_id, callback = (error, auth_token) ->) ->
		db.users.findOne { _id: ObjectId(user_id.toString()) }, { auth_token : true }, (error, user) =>
			return callback(error) if error?
			return callback(new Error("user could not be found: #{user_id}")) if !user?
			if user.auth_token?
				callback null, user.auth_token
			else
				@_createSecureToken (error, auth_token) ->
					db.users.update { _id: ObjectId(user_id.toString()) }, { $set : auth_token: auth_token }, (error) ->
						return callback(error) if error?
						callback null, auth_token
		
	_createSecureToken: (callback = (error, token) ->) ->
		crypto.randomBytes 48, (error, buffer) ->
			return callback(error) if error?
			callback null, buffer.toString("hex")
			
	authenticateApi : (req, res, next)->
		auth = req.headers['authorization']
		if !auth
			res.statusCode = 401
			res.setHeader 'WWW-Authenticate', 'Basic realm="User you ShareLaTeX credentials"'
			res.end 'Unauthorized'
		else if auth
			tmp = auth.split(' ')
			buf = new Buffer(tmp[1], 'base64')
			plain_auth = buf.toString()
			
			creds = plain_auth.split(':')
			email = creds[0].toLowerCase()
			password = creds[1]
			
			AuthenticationManager.authenticate email: email, password, (error, user) ->
				if error?
					res.statusCode = 500
					res.end 'An error occurred'
					logger.err error:error, "an error occurred"					
				else if user?
					res.statusCode = 200
					req.user = user
					next()
				else
					logger.err email:email, password:password, "invalid login details"
					res.statusCode = 403
					res.end 'Unauthorized, forbidden.'
