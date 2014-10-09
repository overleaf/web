Settings = require('settings-sharelatex')
ldap = require('ldapjs')
if (Settings.ldap)
	lclient = ldap.createClient({ url: Settings.ldap.host })

module.exports =
	authDN: (body, callback)->
		if (!Settings.ldap)
			callback null, true 
		else
			if (!Settings.ldap.filter)
				dn = Settings.ldap.dnObj + "=" + body.ldap_user + "," + Settings.ldap.dnSuffix
				lclient.bind dn, body.password, (err)->
					callback err, err == null
			else
				filter = Settings.ldap.filter.replace("#{ldap_user}", body.ldap_user)
				opts = { filter: filter, scope: 'sub' }
				lclient.search Settings.ldap.dnSuffix, opts, (err, res)->
					res.on 'searchEntry', (entry)->
						dn = entry.object['dn'];
						lclient.bind dn, body.password, (err)->
							callback err, err == null