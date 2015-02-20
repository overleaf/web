Settings = require('settings-sharelatex')
redis = require('redis')
rclient = redis.createClient(Settings.redis.web.port, Settings.redis.web.host)
rclient.auth(Settings.redis.web.password)
crypto = require("crypto")
logger = require("logger-sharelatex")

ONE_HOUR_IN_S = 60 * 60

buildKey = (token)-> return "email_token:#{token}"

module.exports =

	getNewTokenVerificationEmail: (emails, callback)->
		logger.log email:emails, "generating token for email verification"
		token = crypto.randomBytes(32).toString("hex")
		multi = rclient.multi()
		multi.hset buildKey(token), "newEmail", emails.newEmail
		multi.hset buildKey(token), "oldEmail", emails.oldEmail
		multi.expire buildKey(token), ONE_HOUR_IN_S
		multi.exec (err)->
			callback(err, token)

	getEmailFromTokenAndExpire: (token, callback)->
		logger.log token:token, "getting user email from email token"
		multi = rclient.multi()
		multi.hgetall buildKey(token)
		multi.del buildKey(token)
		multi.exec (err, results)->
			callback err, results[0]

