logger = require('logger-sharelatex')
ProjectLocator = require("../Project/ProjectLocator")
PreviewHandler = require('./PreviewHandler')
_build_filestore_url = require('../FileStore/FileStoreHandler')._buildUrl
settings = require("settings-sharelatex")


module.exports = PreviewController =

	getPreview: (req, res) ->
		project_id = req.params.Project_id
		file_id = req.params.file_id
		logger.log project_id: project_id, file_id: file_id, "getting preview of file"
		ProjectLocator.findElement project_id: project_id, element_id: file_id, type: 'file', (err, file) ->
			if err?
				logger.log err: err, project_id: project_id, file_id: file_id, "error finding element for file"
				return res.sendStatus 500

			file_url = _build_filestore_url(project_id, file_id)
			file_name = file.name

			logger.log project_id: project_id, file_id: file_id, file_name: file_name, "requesting preview from Previewer service"
			PreviewHandler.getPreview file_url, file_name, (err, preview) ->
				if err?
					logger.log err: err, project_id: project_id, file_id: file_id, "error getting preview"
					return res.sendStatus 500
				res.send preview

	getOutputFilePreview: (req, res) ->
		project_id = req.params.Project_id
		file_id = req.params.file_id
		logger.log project_id: project_id, file_id: file_id, "getting preview of output file"

		file_url = PreviewController._build_clsi_url(project_id, file_id)
		file_name = file_id

		logger.log project_id: project_id, file_id: file_id, "requesting preview from Previewer service"
		PreviewHandler.getPreview file_url, file_name, (err, preview) ->
			if err?
				logger.log err: err, project_id: project_id, file_id: file_id, "error getting preview"
				return res.sendStatus 500
			res.send preview

	_build_clsi_url: (project_id, file_id) ->
		"#{settings.apis.clsi.url}/project/#{project_id}/output/#{file_id}"
