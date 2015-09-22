logger = require('logger-sharelatex')
ProjectLocator = require("../Project/ProjectLocator")
PreviewHandler = require('./PreviewHandler')
_build_filestore_url = require('../FileStore/FileStoreHandler')._buildUrl


module.exports = PreviewController =

	getPreview: (req, res) ->
		project_id = req.params.Project_id
		file_id = req.params.file_id
		file_type = req.params.file_type
		logger.log project_id: project_id, file_id: file_id, file_type: file_type, "getting preview of file"
		ProjectLocator.findElement project_id: project_id, element_id: file_id, type: 'file', (err, file) ->
			if err?
				logger.log err: err, project_id: project_id, file_id: file_id, "error finding element for file"
				return res.sendStatus 500

			file_url = _build_filestore_url(project_id, file_id)

			PreviewHandler.getPreview file_url, file_type, (err, preview) ->
				if err?
					logger.log err: err, project_id: project_id, file_id: file_id, "error getting preview"
					return res.sendStatus 500
				res.send preview
