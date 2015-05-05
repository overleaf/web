logger = require('logger-sharelatex')
FileStoreHandler = require("../FileStore/FileStoreHandler")
CompileController = require("../Compile/CompileController")
LinkCreator = require("./LinkCreator")
Settings = require "settings-sharelatex"
request = require "request"
Link = require("../../models/Link").Link

module.exports =
	generateLink : (req, res) ->
		user_id = req.session.user._id
		project_id = req.params.Project_id # this has been checked by the middleware
		path = req.body.path # this will be checked by the clsi
		logger.log project_id: project_id, user_id: user_id, path: path, "generate link"
		# Copy file from clsi to filestore using link._id as the identifier
		CompileController.getClsiStream project_id, path, (err, srcStream) ->
			# Get the stream from the CLSI
			srcStream.on "error", (err) ->
				logger.err err:err, "error on get stream"
				res.status(500).send {error: err}
			srcStream.pause()
			srcStream.on "response", (response) ->
				# N.B. make sure the srcStream/response stream are discard if needed
				logger.err statusCode:response.statusCode, "get response code"
				# Create the link in mongo
				LinkCreator.createNewLink {user_id, project_id, path}, (err, link) ->
					if err?
						srcStream.resume()
						logger.err err:err, "error creating link"
						return res.status(500).send {error: err}
					logger.log link, "created new link"
					# Send the stream to the filestore at /project/:project_id/public/:public_file_id
					destUrl = "#{Settings.apis.filestore.url}/project/#{project_id}/public/#{link._id}"
					destStream = request.post destUrl, {timeout: 60*1000, json:true}, (err, response, body) ->
						if err? or response.statusCode != 200
							res.status(response?.statusCode || 500).send { error: body }
						else
							short_id = link.public_id.toString(36)  # use base 36 for shortened url
							res.send {
								link: "#{Settings.publicLinkUrl || Settings.siteUrl}/public/#{short_id}/#{link.path}"
							}
					srcStream.pipe(destStream)
					srcStream.resume()

	getFile : (req, res) ->
		# need to be able to put this on a cdn, so allow for a separate subdomain
		public_id = req.params.public_id
		if not public_id.match(/^[0-9a-zA-Z]+$/)
			return res.status(404).send("Invalid link id")
		Link.findOne {public_id: parseInt(public_id, 36)}, (err, link) ->
			if err?
				return res.status(404).send(err)
			url = "#{Settings.apis.filestore.url}/project/#{link.project_id}/public/#{link._id}"
			oneMinute = 60 * 1000
			options = { url: url, method: req.method,	timeout: oneMinute }
			proxy = request.get url
			proxy.on "error", (err) ->
				logger.warn err: err, url: url, "filestore proxy error"
				res.status(500).end()
			res.setHeader "Cache-Control", "public, max-age=86400"
			res.setHeader "Last-Modified", link.created.toUTCString()
			res.setHeader "ETag", link._id
			proxy.pipe(res)
