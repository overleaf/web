logger                  = require "logger-sharelatex"
Metrics                 = require "../../infrastructure/Metrics"
Project                 = require("../../models/Project").Project
ProjectZipStreamManager = require "./ProjectZipStreamManager"
DocumentUpdaterHandler  = require "../DocumentUpdater/DocumentUpdaterHandler"
ErrorController         = require "../Errors/ErrorController"

module.exports = ProjectDownloadsController =
	downloadProject: (req, res, next) ->
		project_id = req.params.Project_id
		Metrics.inc "zip-downloads"
		logger.log project_id: project_id, "downloading project"
		DocumentUpdaterHandler.flushProjectToMongo project_id, (error)->
			return next(error) if error?
			Project.findById project_id, "name", (error, project) ->
				return next(error) if error?
				if !project?
					return ErrorController.notFound(req, res)
				handler = (error, stream) ->
					return next(error) if error?
					res.header(
						"Content-Disposition",
						"attachment; filename=#{encodeURIComponent(project.name)}.zip"
					)
					res.contentType('application/zip')
					stream.pipe(res)
				if req.query.skipOutputFiles
					ProjectZipStreamManager.createZipStreamForProjectWithoutOutput project_id, handler
				else
					ProjectZipStreamManager.createZipStreamForProject project_id, handler

	downloadMultipleProjects: (req, res, next) ->
		project_ids = req.query.project_ids.split(",")
		Metrics.inc "zip-downloads-multiple"
		logger.log project_ids: project_ids, "downloading multiple projects"
		DocumentUpdaterHandler.flushMultipleProjectsToMongo project_ids, (error) ->
			return next(error) if error?
			ProjectZipStreamManager.createZipStreamForMultipleProjects project_ids, (error, stream) ->
				return next(error) if error?
				res.header(
					"Content-Disposition",
					"attachment; filename=DataJoy Projects (#{project_ids.length} items).zip"
				)
				res.contentType('application/zip')
				stream.pipe(res)


