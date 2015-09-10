Path  = require "path"
async = require "async"
Settings = require "settings-sharelatex"
request = require('request')
Project = require("../../models/Project").Project
ProjectEntityHandler = require("../Project/ProjectEntityHandler")
logger = require "logger-sharelatex"
url = require("url")

module.exports = ClsiManager =
	sendRequest: (project_id, request_id, options = {}, callback = (error, success, outputFiles, output) ->) ->
		ClsiManager._buildRequest project_id, request_id, options, (error, req) ->
			return callback(error) if error?
			logger.log project_id: project_id, "sending compile to CLSI"
			ClsiManager._postToClsi project_id, req, options.compileGroup, (error, response) ->
				return callback(error) if error?
				logger.log project_id: project_id, response: response, "received compile response from CLSI"
				callback(
					null
					response?.compile?.status
					ClsiManager._parseOutputFiles(project_id, response?.compile?.outputFiles)
					response?.compile?.output
				)
	
	sendJupyterRequest: (project_id, request_id, engine, msg_type, content, limits, callback = (error) ->) ->
		ClsiManager._buildResources project_id, (error, resources) ->
			return callback(error) if error?
			request.post {
				url:  "#{Settings.apis.clsi.url}/project/#{project_id}/request"
				json: {msg_type, content, request_id, engine, limits, resources}
				jar:  false
			}, (error, response, body) ->
				return callback(error) if error?
				if 200 <= response.statusCode < 300
					callback null, body
				else
					error = new Error("CLSI returned non-success code: #{response.statusCode}")
					logger.error err: error, project_id: project_id, "CLSI returned failure code"
					callback error, body

	sendJupyterReply: (project_id, engine, msg_type, content, callback = (error) ->) ->
		request.post {
			url:  "#{Settings.apis.clsi.url}/project/#{project_id}/reply"
			json: {msg_type, content, engine}
			jar:  false
		}, (error, response, body) ->
			return callback(error) if error?
			if 200 <= response.statusCode < 300
				callback null, body
			else
				error = new Error("CLSI returned non-success code: #{response.statusCode}")
				logger.error err: error, project_id: project_id, "CLSI returned failure code"
				callback error, body
	
	interruptRequest: (project_id, request_id, callback = (error) ->) ->
		request.post {
			url:  "#{Settings.apis.clsi.url}/project/#{project_id}/request/#{request_id}/interrupt"
			jar:  false
		}, (error, response, body) ->
			return callback(error) if error?
			if 200 <= response.statusCode < 300
				callback null, body
			else
				error = new Error("CLSI returned non-success code: #{response.statusCode}")
				logger.error err: error, project_id: project_id, "CLSI returned failure code"
				callback error, body

	deleteAuxFiles: (project_id, options, callback = (error) ->) ->
		compilerUrl = @_getCompilerUrl(options?.compileGroup)
		request.del "#{compilerUrl}/project/#{project_id}", callback

	deleteOutputFile: (project_id, file, options, callback = (error) ->) ->
		compilerUrl = @_getCompilerUrl(options?.compileGroup)
		request.del "#{compilerUrl}/project/#{project_id}/output/#{file}", callback

	_getCompilerUrl: (compileGroup) ->
		if compileGroup == "priority"
			return Settings.apis.clsi_priority.url
		else
			return Settings.apis.clsi.url

	_postToClsi: (project_id, req, compileGroup, callback = (error, response) ->) ->
		compilerUrl = @_getCompilerUrl(compileGroup)
		request.post {
			url:  "#{compilerUrl}/project/#{project_id}/compile"
			json: req
			jar:  false
		}, (error, response, body) ->
			return callback(error) if error?
			if 200 <= response.statusCode < 300
				callback null, body
			else if response.statusCode == 413
				callback null, compile:status:"project-too-large"
			else
				error = new Error("CLSI returned non-success code: #{response.statusCode}")
				logger.error err: error, project_id: project_id, "CLSI returned failure code"
				callback error, body

	_parseOutputFiles: (project_id, rawOutputFiles = []) ->
		outputFiles = []
		for file in rawOutputFiles
			outputFiles.push
				path: url.parse(file.url).path.replace("/project/#{project_id}/output/", "")
				type: file.type
				build: file.build
		return outputFiles

	VALID_COMPILERS: ["pdflatex", "latex", "xelatex", "lualatex", "python", "r", "command", "apt-get-install"]
	_buildRequest: (project_id, request_id, options={}, callback = (error, request) ->) ->
		Project.findById project_id, {compiler: 1, rootDoc_id: 1}, (error, project) ->
			return callback(error) if error?
			return callback(new Errors.NotFoundError("project does not exist: #{project_id}")) if !project?

			ClsiManager._buildResources project_id, (error, resources) ->
				return callback(error) if error?
				
				rootResourcePath = null
				rootResourcePathOverride = null

				for resource in resources
					if project.rootDoc_id? and resource.id.toString() == project.rootDoc_id.toString()
						rootResourcePath = resource.path
					if options.rootDoc_id? and resource.id.toString() == options.rootDoc_id.toString()
						rootResourcePathOverride = resource.path
					delete resource.id

				rootResourcePath = rootResourcePathOverride if rootResourcePathOverride?

				# If we have no rootResourcePath by now, just use the first file.
				if !rootResourcePath?
					rootResourcePath = resources[0]?.path

				compiler = project.compiler
				if options.compiler?
					compiler = options.compiler
				else if rootResourcePath.match(/\.R$/)
					compiler = "r"
				else if rootResourcePath.match(/\.py$/)
					compiler = "python"

				if compiler not in ClsiManager.VALID_COMPILERS
					compiler = "pdflatex"

				callback null, {
					compile:
						request_id: request_id
						options:
							compiler:   compiler
							command:    options.command
							package:    options.package
							env:        options.env
							timeout:    options.timeout
							memory:     options.memory
							cpu_shares: options.cpu_shares
							processes:  options.processes
						rootResourcePath: rootResourcePath
						resources: resources
				}
	
	_buildResources: (project_id, callback = (error) ->) ->
		ProjectEntityHandler.getAllDocs project_id, (error, docs = {}) ->
			return callback(error) if error?
			ProjectEntityHandler.getAllFiles project_id, (error, files = {}) ->
				return callback(error) if error?

				resources = []

				for path, doc of docs
					path = path.replace(/^\//, "") # Remove leading /
					resources.push
						id:      doc._id
						path:    path
						content: doc.lines.join("\n")
				
				for path, file of files
					path = path.replace(/^\//, "") # Remove leading /
					resources.push
						id:       file._id
						path:     path
						url:      "#{Settings.apis.filestore.url}/project/#{project_id}/file/#{file._id}"
						modified: file.created?.getTime()
				
				callback(null, resources)
