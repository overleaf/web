Settings = require('settings-sharelatex')
logger = require("logger-sharelatex")
ldap = require('ldapjs')
if (Settings.ldap)
	lclient = ldap.createClient({ url: Settings.ldap.host })

module.exports =
	authDN: (body, callback)->
		if (!Settings.ldap)
			callback null, true 
		else
			dnObjFilter = Settings.ldap.dnObj + "=" + body.email
			dn = dnObjFilter + "," + Settings.ldap.dnSuffix
			filter = "(" + dnObjFilter + ")"
			opts = { filter: filter, scope: 'sub' }
		
			if (Settings.ldap.type == 'bind')
				logger.log dn:dn, "ldap bind"
				lclient.bind dn, body.password, (err)->
					logger.log opts:opts, "ldap bind success, now ldap search"
					lclient.search Settings.ldap.dnSuffix, opts, (err, res)->
						res.on 'searchEntry', (entry)->		
							logger.log opts:opts, "ldap search success"
							body.email = entry.object[Settings.ldap.emailAtt].toLowerCase()
							body.password = entry.object[Settings.ldap.dnObj]
							callback err, err == null
						res.on 'error', (err)->
							logger.log err:err, "ldap search error"
							callback err, err == null
			else
				logger.log opts:opts, "ldap search"
				lclient.search Settings.ldap.dnSuffix, opts, (err, res)->
					res.on 'searchEntry', (entry)->
						dn = entry.object['dn']
						logger.log dn:dn, "ldap search success, now ldap bind"
						lclient.bind dn, body.password, (err)->
							body.email = entry.object[Settings.ldap.emailAtt].toLowerCase()
							body.password = entry.object[Settings.ldap.dnObj]
							callback err, err == null
					res.on 'error', (err)->
						logger.log err:err, "ldap search error"
						callback err, err == null
