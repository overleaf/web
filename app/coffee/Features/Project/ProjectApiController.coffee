ProjectDetailsHandler = require("./ProjectDetailsHandler")
ProjectEntityHandler = require("./ProjectEntityHandler")
Settings = require "settings-sharelatex"
logger = require("logger-sharelatex")


module.exports = 
	getProjectDetails : (req, res, next)->
		{project_id} = req.params
		ProjectDetailsHandler.getDetails project_id, (err, projDetails)->
			if err?
				logger.log err:err, project_id:project_id, "something went wrong getting project details"
				return res.sendStatus 500
			res.json(projDetails)

	getProjectContent: (req, res, next) ->
		{project_id} = req.params
		ProjectEntityHandler.getAllDocs project_id, (error, docs = {}) ->
			return callback(error) if error?
			ProjectEntityHandler.getAllFiles project_id, (error, files = {}) ->
				return callback(error) if error?
				content = []
				for path, doc of docs
					path = path.replace(/^\//, "") # Remove leading /
					content.push
						path:    path
						content: doc.lines.join("\n")
				for path, file of files
					path = path.replace(/^\//, "") # Remove leading /
					content.push
						path:     path
						url:      "#{Settings.apis.filestore.url}/project/#{project_id}/file/#{file._id}"
				res.json content: content