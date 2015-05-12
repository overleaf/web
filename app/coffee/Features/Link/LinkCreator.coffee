Link = require("../../models/Link").Link

module.exports =

	createNewLink: (opts, callback)->
		link = new Link()
		link.path = opts.path
		link.project_id = opts.project_id
		link.user_id = opts.user_id
		link.save (err)->
			callback(err, link)
