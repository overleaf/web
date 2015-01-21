settings = require("settings-sharelatex")
async = require("async")
UserGetter = require("../User/UserGetter")
ConfirmEmailTokenHandler = require("./ConfirmEmailTokenHandler")
EmailHandler = require("../Email/EmailHandler")
AuthenticationManager = require("../Authentication/AuthenticationManager")
UserRegistrationHandler = require("../User/UserRegistrationHandler")

logger = require("logger-sharelatex")

module.exports =

  generateAndEmailVerificationToken:(emails, action, callback = (error, exists) ->)->
    UserGetter.getUser email:emails.newEmail, (err, user)->
      if err then return callback(err)
      if user?
        logger.err email:emails.newEmail, "User is already register"
        return callback(null, true)
      ConfirmEmailTokenHandler.getNewTokenVerificationEmail emails, (err, token)->
        if err then return callback(err)
        emailOptions =
          to : emails.newEmail
          setEmailVerificationUrl : "#{settings.siteUrl}/user/#{action}?emailVerificationToken=#{token}"
        EmailHandler.sendEmail "emailVerificationRequested", emailOptions, (error) ->
          return callback(error) if error?
          callback null, false

  createPassword: (token, password, req, res,  callback )->
    ConfirmEmailTokenHandler.getEmailFromTokenAndExpire token, (err, emails)->
      if err
        logger.err err: err, "Error while retrieving the verification token"
        return res.send 500, {message: "Error"}
      if !emails?
        logger.err token, "token for registration did not find email"
        return res.send 500, {message: "Error"}
      req.body.email = emails.newEmail
      req.body.password = password
      callback req, res


