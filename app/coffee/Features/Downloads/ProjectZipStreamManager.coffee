archiver = require "archiver"
tar      = require "tar-stream"
gunzip   = require "gunzip-maybe"
async    = require "async"
logger   = require "logger-sharelatex"
ProjectEntityHandler = require "../Project/ProjectEntityHandler"
FileStoreHandler = require("../FileStore/FileStoreHandler")
CompileController = require "../Compile/CompileController"
Project = require("../../models/Project").Project

module.exports = ProjectZipStreamManager =
	createZipStreamForMultipleProjects: (project_ids, callback = (error, stream) ->) ->
		# We'll build up a zip file that contains multiple zip files

		archive = archiver("zip")
		archive.on "error", (err)->
			logger.err err:err, project_ids:project_ids, "something went wrong building archive of project"
		callback null, archive

		logger.log project_ids: project_ids, "creating zip stream of multiple projects"

		jobs = []
		for project_id in project_ids or []
			do (project_id) ->
				jobs.push (callback) ->
					Project.findById project_id, "name", (error, project) ->
						return callback(error) if error?
						logger.log project_id: project_id, name: project.name, "appending project to zip stream"
						ProjectZipStreamManager.createZipStreamForProject project_id, (error, stream) ->
							return callback(error) if error?
							archive.append stream, name: "#{project.name}.zip"
							stream.on "end", () ->
								logger.log project_id: project_id, name: project.name, "zip stream ended"
								callback()

		async.series jobs, () ->
			logger.log project_ids: project_ids, "finished creating zip stream of multiple projects"
			archive.finalize()

	createZipStreamForProject: (project_id, callback = (error, stream) ->) ->
		archive = archiver("zip")
		# return stream immediately before we start adding things to it
		archive.on "error", (err)->
			logger.err err:err, project_id:project_id, "something went wrong building archive of project"
		callback(null, archive)
		@addAllDocsToArchive project_id, archive, (error) =>
			if error?
				logger.error err: error, project_id: project_id, "error adding docs to zip stream"
			@addAllFilesToArchive project_id, archive, (error) =>
				if error?
					logger.error err: error, project_id: project_id, "error adding files to zip stream"
				@addOutputFilesToArchive project_id, archive, (error) =>
					if error?
						logger.error err: error, project_id: project_id, "error adding output files to zip stream"
					archive.finalize()

	createZipStreamForProjectWithoutOutput: (project_id, callback = (error, stream) ->) ->
		archive = archiver("zip")
		# return stream immediately before we start adding things to it
		archive.on "error", (err)->
			logger.err err:err, project_id:project_id, "something went wrong building archive of project"
		callback(null, archive)
		@addAllDocsToArchive project_id, archive, (error) =>
			if error?
				logger.error err: error, project_id: project_id, "error adding docs to zip stream"
			@addAllFilesToArchive project_id, archive, (error) =>
				if error?
					logger.error err: error, project_id: project_id, "error adding files to zip stream"
				archive.finalize()

	addAllDocsToArchive: (project_id, archive, callback = (error) ->) ->
		ProjectEntityHandler.getAllDocs project_id, (error, docs) ->
			return callback(error) if error?
			jobs = []
			for path, doc of docs
				do (path, doc) ->
					path = path.slice(1) if path[0] == "/"
					jobs.push (callback) ->
						logger.log project_id: project_id, "Adding doc"
						archive.append doc.lines.join("\n"), name: path
						callback()
			async.series jobs, callback

	addAllFilesToArchive: (project_id, archive, callback = (error) ->) ->
		ProjectEntityHandler.getAllFiles project_id, (error, files) ->
			return callback(error) if error?
			jobs = []
			for path, file of files
				do (path, file) ->
					jobs.push (callback) ->
						FileStoreHandler.getFileStream  project_id, file._id, {}, (error, stream) ->
							if error?
								logger.err err:error, project_id:project_id, file_id:file._id, "something went wrong adding file to zip archive"
								return callback(err)
							path = path.slice(1) if path[0] == "/"
							archive.append stream, name: path
							stream.on "end", () ->
								callback()
			async.parallelLimit jobs, 5, callback

	addOutputFilesToArchive: (project_id, archive, _callback = (error) ->) ->
		callback = (args...) ->
			_callback(args...)
			callback = ->
		CompileController.getClsiStream project_id, {format: 'tar'}, (error, tarStream) ->
			return callback(error) if error?
			logger.log {project_id}, "streaming tar file from CLSI"
			tarStream.on 'error', (err) ->
				logger.log {err}, "error in tar stream from CLSI"
				callback(err)
			extract = tar.extract()
			extract.on "entry", (header, stream, cb) ->
				# header is the tar header
				# stream is the content body (might be an empty stream)
				# call cb when you are done with this entry
				logger.log {project_id, header_name: header.name}, "adding tar file entry"
				archive.append stream, name: header.name
				stream.on "error", () ->
					logger.error {project_id}, "error unpacking tar file entry"
				stream.on "end", () ->
					cb() # ready for next entry
			extract.on "error", (err) ->
				logger.err {err}, "error unpacking tar file"
			extract.on "finish", () ->
				logger.log {project_id}, "end of tar file"
				callback()
			tarStream.pipe(gunzip()).pipe(extract)
