logger = require('logger-sharelatex')
FileStoreHandler = require("./FileStoreHandler")
ProjectLocator = require("../Project/ProjectLocator")
ProjectEntityHandler = require("../Project/ProjectEntityHandler")
_ = require('underscore')

is_mobile_safari = (user_agent) ->
	user_agent and (user_agent.indexOf('iPhone') >= 0 or
									user_agent.indexOf('iPad') >= 0)

is_html = (file) ->
	ends_with = (ext) ->
		file.name? and
		file.name.length > ext.length and
		(file.name.lastIndexOf(ext) == file.name.length - ext.length)

	ends_with('.html') or ends_with('.htm') or ends_with('.xhtml')

module.exports = FileStoreController =

	getFile: (req, res)->
		project_id = req.params.Project_id
		file_id = req.params.File_id
		queryString = req.query
		user_agent = req.get('User-Agent')
		logger.log project_id: project_id, file_id: file_id, queryString:queryString, "file download"
		ProjectLocator.findElement {project_id: project_id, element_id: file_id, type: "file"}, (err, file)->
			if err?
				logger.err err:err, project_id: project_id, file_id: file_id, queryString:queryString, "error finding element for downloading file"
				return res.sendStatus 500
			FileStoreHandler.getFileStream project_id, file_id, queryString, (err, stream)->
				if err?
					logger.err err:err, project_id: project_id, file_id: file_id, queryString:queryString, "error getting file stream for downloading file"
					return res.sendStatus 500
				# mobile safari will try to render html files, prevent this
				if (is_mobile_safari(user_agent) and is_html(file))
					logger.log filename: file.name, user_agent: user_agent, "sending html file to mobile-safari as plain text"
					res.setHeader('Content-Type', 'text/plain')
				res.setHeader("Content-Disposition", "attachment; filename=#{file.name}")
				stream.pipe res

	getFileByProjectAndPath: (req, res)->
		project_id = req.params.project_id
		path = req.params.path
		queryString = req.query
		user_agent = req.get('User-Agent')
		ProjectLocator.findElementByPath project_id, path, (err, foundFolder) ->
			if foundFolder?
				file_id = foundFolder._id
				ProjectLocator.findElement {project_id: project_id, element_id: file_id, type: "files"}, (err, file)->
					if err? or !file?
						ProjectEntityHandler.getDoc project_id, file_id, (error, lines, rev) ->
							if error?
								logger.err err:error, doc_id:file_id, project_id:project_id, "error finding element for getDocument"
								return res.sendStatus 500
							res.setHeader('Content-Type', 'application/x-tex')
							res.send lines.join("\n")
					else

						FileStoreHandler.getFileStream project_id, file_id, queryString, (err, stream)->
							if err? or !file?
								logger.err err:err, project_id: project_id, file_id: file_id, queryString:queryString, "error getting file stream for downloading file"
								return res.sendStatus 500
							# mobile safari will try to render html files, prevent this
							if (is_mobile_safari(user_agent) and is_html(file))
								logger.log filename: file.name, user_agent: user_agent, "sending html file to mobile-safari as plain text"
								res.setHeader('Content-Type', 'text/plain')
							res.setHeader("Content-Disposition", "attachment; filename=#{file.name}")
							stream.pipe res
			logger.err err:err, project_id: project_id, path: path, queryString:queryString, "error finding file by project and path"
			return res.sendStatus 500