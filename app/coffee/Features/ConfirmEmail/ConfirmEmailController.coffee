ConfirmEmailHandler = require("./ConfirmEmailHandler")
ConfirmEmailTokenHandler = require("./ConfirmEmailTokenHandler")
RateLimiter = require("../../infrastructure/RateLimiter")
UserController = require("../User/UserController")
UserUpdater = require("../User/UserUpdater")
UserGetter = require("../User/UserGetter")
logger = require "logger-sharelatex"

module.exports =

	renderCreatePasswordForm: (req, res)->
		res.render "user/createPassword", 
			title:"create_password"
			emailVerificationToken:req.query.emailVerificationToken

	renderUpdateEmail: (req, res)->
		ConfirmEmailTokenHandler.getEmailFromTokenAndExpire req.query.emailVerificationToken, (err, emails)->
			if err
				logger.err err: err, "Error while retrieving the verification token"
				return res.send 500, {message: "Error"}
			if !emails?
				logger.err req.query.emailVerificationToken, "token for registration did not find email"
				return res.send 500, {message: "Error"}
			UserGetter.getUser email:emails.oldEmail, (err, user)->
				if err
					logger.err err: err, "Error while retrieving user from email"
					return res.send 500, {message: "Error"}
				if !user?
					logger.err emails.oldEmail, "user could not be found for update email"
					return res.send 500, {message: "Error"}
				UserUpdater.changeEmailAddress user._id, emails.newEmail, (err)->
					if err?
						logger.err err:err, user._id, emails.newEmail, "problem updaing users email address"
						if err.message == "alread_exists"
							message = req.i18n.translate("alread_exists")
						else
							message = req.i18n.translate("problem_changing_email_address")
						return res.send 500, {message:message}
					res.render "general/emailValidate"			

	requestCreatePassword: (req, res, next)->
		{emailVerificationToken, password} = req.body
		if !password? or password.length == 0 or !emailVerificationToken? or emailVerificationToken.length == 0
			return res.send 500
		ConfirmEmailHandler.createPassword emailVerificationToken?.trim(), password?.trim(), req, res, (req, res, next)->
      UserController.register req, res, next
