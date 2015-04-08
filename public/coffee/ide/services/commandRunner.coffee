define [
	"base"
], (App) ->
	# We create and provide this as service so that we can access the global ide
	# from within other parts of the angular app.
	App.factory "commandRunner", ($http, $timeout, ide) ->
		ide.socket.on "clsiOutput", (message) ->
			session_id = message.header?.session
			return if !session_id?
			
			run = commandRunner.INPROGRESS_RUNS[session_id]
			return if !run?
			
			if message.msg_type == "system_status" and message.content.status == "starting_run"
				run.inited = true
				ide.$scope.$apply()
			else if message.msg_type == "command_exited"
				run.exitCode = message.content.exitCode
				commandRunner._parseErrors(run)
				commandRunner._displayErrors(run)
			else
				output = commandRunner._parseOutputMessage(message)
				if output?
					output = commandRunner._filterOutputMessage(output)
					run.output.push output
					ide.$scope.$apply()
		
		commandRunner =
			INPROGRESS_RUNS: {}
			
			run: (options) ->
				run = @_createNewRun()

				initing = $timeout () ->
					# Only show initing message after 2 seconds of delay
					run.stillIniting = true
				, 2000
				run.running = true
				run.uncompiled = false
				
				url = "/project/#{ide.$scope.project_id}/compile"
				options._csrf = window.csrfToken
				options.session_id = run.session_id
				$http
					.post(url, options)
					.success (data) =>
						$timeout.cancel(initing)
						run.running = false
						run.stopping = false
						if data?.status == "timedout"
							run.timedout = true
						@_clearRun(run)
					.error () =>
						$timeout.cancel(initing)
						run.running = false
						run.stopping = false
						run.error = true
						@_clearRun(run)

				return run
			
			stop: (run) ->
				url = "/project/#{_ide.$scope.project_id}/compile/#{run.session_id}/stop"
				run.stopping = true
				$http
					.post(url, {
						_csrf: window.csrfToken
					})
					.error () ->
						run.stopping = false
		
			_createNewRun: () ->
				session_id = Math.random().toString().slice(2)
				run = @INPROGRESS_RUNS[session_id] = {
					output: []
					running: false
					error: false
					timedout: false
					session_id: session_id
					stillIniting: false
					inited: false
					stopping: false
					exitCode: null
					parsedErrors: []
				}
				return run
			
			_clearRun: (run) ->
				# Once a run has completed, we don't need to keep it hanging
				# around in our memory for appending messages to it.
				# Add a short delay to ensure that all real time messages
				# have been flushed (this delay can be removed if there is a more
				# reliable way of ensuring we have all the real-time content)
				setTimeout () =>
					delete @INPROGRESS_RUNS[run.session_id]
				, 5000
			
			_parseOutputMessage: (message) ->
				if message.msg_type == "stream"
					output = {
						output_type: message.content.name # 'stdout' or 'stderr'
						text: message.content.text
						msg_id: parseInt(message.header.msg_id, 10)
					}
				else if message.msg_type == "file_modified"
					path = message.content.data['text/path']
					output = {
						output_type: "file"
						url: "/project/#{ide.$scope.project_id}/output/#{path}?cache_bust=#{Date.now()}"
						file_type: "unknown"
						path: path
						ignore: @_shouldIgnorePath(path)
						msg_id: parseInt(message.header.msg_id, 10)
					}
					parts = path.split(".")
					if parts.length == 1
						extension = null
					else
						extension = parts[parts.length - 1].toLowerCase()
					output.extension = extension
					if extension in ["png", "jpg", "jpeg", "svg", "gif"]
						output.file_type = "image"
					else if extension in ["pdf"]
						output.file_type = "pdf"
					else if extension in ["rout"]
						output.file_type = "text"
				else
					output = null
				return output

			_shouldIgnorePath: (path) ->
				return true if path.match(/\.pyc$/)
				return false

			_filterOutputMessage: (output) ->
				if output.output_type == 'stderr'
					# strip call stack from R error output
					output.text = output.text.replace /Calls: source -> withVisible -> eval -> eval.*\n/, ''
				return output

			_parseErrors: (run) ->
				stderr = ""
				for output in run.output
					if output.output_type == "stderr"
						stderr += output.text
				stderr.replace /ImportError: No module named ([^ ]*)/g, (match, packageName) ->
					run.parsedErrors.push {
						type: "missing_package"
						package: packageName
						language: "python"
					}
				stderr.replace /there is no package called ‘(.*)’/, (match, packageName) ->
					run.parsedErrors.push {
						type: "missing_package"
						package: packageName
						language: "R"
					}
				stderr.replace /(.*\S) \(from (\S+\.[rR])#(\d+)\)\s*(.*)/, (match, message1, fileName, lineNumber, message2) ->
					message = message1 + message2
					run.parsedErrors.push {
						type: "error"
						file: fileName
						line: +lineNumber
						message: message
						language: "R"
					}
				stderr.replace /^(\d+:.*) at (\S+\.[rR])#(\d+)$/m, (match, stackFrame, fileName, lineNumber) ->
					run.parsedErrors.push {
						type: "stackframe"
						file: fileName
						line: +lineNumber
						message: stackFrame
						language: "R"
					}


			_displayErrors: (run) ->
				$scope = ide.$scope
				$scope.pdf.logEntryAnnotations = {}
				for error in run.parsedErrors
					entity = ide.fileTreeManager.findEntityByPath(error.file)
					if entity?
						$scope.pdf.logEntryAnnotations[entity.id] ||= []
						$scope.pdf.logEntryAnnotations[entity.id].push {
							row: error.line-1
							type: if error.type == "stackframe" then "warning" else "error"
							text: error.message
						}
				$scope.$evalAsync()


		return commandRunner
