Settings = require 'settings-sharelatex'
User = require("../../models/User").User
{db, ObjectId} = require("../../infrastructure/mongojs")
crypto = require 'crypto'
bcrypt = require 'bcrypt'

module.exports = AuthenticationManager =
	authenticate: (query, password, callback = (error, user) ->) ->
		# Using Mongoose for legacy reasons here. The returned User instance
		# gets serialized into the session and there may be subtle differences
		# between the user returned by Mongoose vs mongojs (such as default values)
		# console.log 'in authenticate'
		User.findOne query, (error, user) =>
			return callback(error) if error?
			if user?
				console.log 'user? >> true'
				if user.google?
					console.log 'user google'
					callback null, user
				else
					if user.hashedPassword?
						bcrypt.compare password, user.hashedPassword, (error, match) ->
							return callback(error) if error?
							if match
								console.log 'match? >> true'
								callback null, user
							else
								console.log 'match? >> false'
								callback null, null
					else
						callback null, null
			else
				console.log 'user? >> false'
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
