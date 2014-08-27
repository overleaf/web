Settings = require('settings-sharelatex')
ldap = require('ldapjs')
lclient = ldap.createClient({ url: Settings.ldap.host })

module.exports =
	authDN: (body, callback)->
		if (!Settings.ldap)
			callback null, true 
		else
			lclient.bind Settings.ldap.dnObj + body.ldap_user + Settings.ldap.dnSuffix, body.password, (err)->
				callback err, err == null
