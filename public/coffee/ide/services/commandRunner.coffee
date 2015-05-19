define [
	"base"
], (App) ->
	# We create and provide this as service so that we can access the global ide
	# from within other parts of the angular app.
	App.factory "commandRunner", ($http, $timeout, ide, ansi2html, $sce) ->
		ide.socket.on "clsiOutput", (message) ->
			console.log "MESSAGE", message
			
			commandRunner.status.initing = false
			if commandRunner._initingTimeout?
				$timeout.cancel(commandRunner._initingTimeout)
				delete commandRunner._initingTimeout
			
			engine_and_msg_id = message.header?.msg_id
			commandRunner.current_msg_id = engine_and_msg_id
			[engine,msg_id] = engine_and_msg_id?.split(":")
			return if !msg_id? or !engine?
			cell = commandRunner.findOrCreateCell(msg_id, engine)
			
			if message.header.msg_type == "execute_input"
				cell.execution_count = message.content.execution_count
				cell.input.push message
			
			if message.header.msg_type in ["error", "stream", "display_data", "execute_result"]
				cell.output.push message
			
			if message.header.msg_type == "stream"
				message.content.text_escaped = ansiToSafeHtml(message.content.text)
			
			if message.header.msg_type == "error"
				message.content.traceback_escaped = message.content.traceback.map ansiToSafeHtml
			
			if message.header.msg_type == "display_data"
				if message.content.data['text/html']?
					message.content.data['text/html_escaped'] = $sce.trustAsHtml(message.content.data['text/html'])
				
			if message.header.msg_type == "status"
				if message.content.execution_state == "busy"
					commandRunner.status.running = true
				else if message.content.execution_state == "idle"
					commandRunner.status.running = false
		
			ide.$scope.$apply()
			# if message.msg_type == "system_status" and message.content.status == "starting_run"
			# 	run.inited = true
			# 	ide.$scope.$apply()
			# else if message.msg_type == "command_exited"
			# 	run.exitCode = message.content.exitCode
			# 	commandRunner._displayErrors(run)
			# else
			# 	output = commandRunner._parseOutputMessage(message)
			# 	if output?
			# 		output = commandRunner._filterOutputMessage(output)
			# 		if output.output_type == 'stderr' and run.parseErrors
			# 			parsedErrors = commandRunner._parseChunk output
			# 			if parsedErrors?.length
			# 				output.parsedErrors = parsedErrors
			# 		run.output.push output
			# 		ide.$scope.$apply()
		
		ansiToSafeHtml = (input) ->
			input = input
				.replace(/&/g, "&amp;")
				.replace(/</g, "&lt;")
				.replace(/>/g, "&gt;")
				.replace(/"/g, "&quot;")
				.replace(/'/g, "&#039;")
			return $sce.trustAsHtml(ansi2html.toHtml(input))
		
		commandRunner =
			CELL_LIST: {}
			CELLS: {}
			
			status: {
				running: false,
				stopping: false,
				error: false,
				initing: false
			}
			
			current_msg_id: null
		
			executeRequest: (code, engine) ->
				msg_id = Math.random().toString().slice(2)
				@current_msg_id = "#{engine}:#{msg_id}"
				@status.running = true
				@status.error = false
				
				@_initingTimeout = $timeout () =>
					@status.initing = true
				, 1000

				url = "/project/#{ide.$scope.project_id}/execute_request"
				options = {
					code: code
					engine: engine
					msg_id: "#{engine}:#{msg_id}"
					_csrf: window.csrfToken
				}
				$http
					.post(url, options)
					.success (data) =>
						@status.running = false
					.error () =>
						@status.error = true
						@status.running = false
			
			findOrCreateCell: (msg_id, engine) ->
				if commandRunner.CELLS[msg_id]?
					return commandRunner.CELLS[msg_id]
				else
					cell = {
						msg_id: msg_id
						engine: engine
						input: []
						output: []
					}
					commandRunner.CELLS[msg_id] = cell
					commandRunner.CELL_LIST[engine] ||= []
					commandRunner.CELL_LIST[engine].push cell
			
			stop: (run) ->
				msg_id = @current_msg_id
				console.log "STOPPING", msg_id
				return if !msg_id?
				url = "/project/#{_ide.$scope.project_id}/request/#{msg_id}/interrupt"
				$http
					.post(url, {
						_csrf: window.csrfToken
					})
			
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

			_parseChunk: (output) ->
				stderr = output.text
				parsedErrors = []
				stderr = stderr.replace /ImportError: No module named (\S+)/g, (match, packageName) ->
					parsedErrors.push {
						type: "missing_package"
						package: packageName
						language: "python"
					}
					return match
				stderr = stderr.replace /.*there is no package called ['‘](.*)[’']/, (match, packageName) ->
					parsedErrors.push {
						type: "missing_package"
						package: packageName
						language: "R"
					}
					return match
				# Examples of python error messages:
				#
				# Traceback (most recent call last):
				#   File "/usr/bin/datajoy-wrapper.py", line 15, in <module>
				#     execfile(script)
				#   File "main.py", line 8, in <module>
				#     print i/0
				# ZeroDivisionError: integer division or modulo by zero
				#
				# Traceback (most recent call last):
				#   File "/usr/bin/datajoy-wrapper.py", line 15, in <module>
				#     execfile(script)
				#   File "main.py", line 8
				#     prinxt i
				#            ^
				# SyntaxError: invalid syntax
				stderr = stderr.replace ///^
					Traceback.\(most.recent.call.last\):
					\n
					((\s\s\s*[a-zA-Z].*\n)+)(\s+\^\n)?
					(.*:.*)
				///m, (match, stack, lastLine, pointer, error) ->
					PYTHON_STACK_REGEX = /File "(.*)", line (\d+),?/
					PYTHON_WRAPPER_REGEX = /File "\/usr\/bin\/datajoy-wrapper\.py", line (\d+),/
					PYTHON_WRAPPER_FULL_REGEX = /File "\/usr\/bin\/datajoy-wrapper\.py", line (\d+), .*\n.*\n/
					PYTHON_PATH_REGEX = /\/home\/user\/project\//
					parsedError = {
						type: "runtime_error"
						message: error
						language: "python"
						raw: match.replace(PYTHON_WRAPPER_FULL_REGEX, '').replace(PYTHON_PATH_REGEX, '')
					}
					# parse the stack lines (if any)
					stackLines = stack?.replace(/^  /mg,'').replace(/\s?\n^\s+/mg, ', ').replace(/\n+$/, '').split('\n')
					if stackLines?
						# strip off stack frame from the wrapper script
						if stackLines?[0].match(PYTHON_WRAPPER_REGEX)
							stackLines.shift()
						stackFrames = []
						seenLocation = false # whether we've got a file/line yet
						errorFrameIndex = null
						for s, i in stackLines
							frame = { message: (i+1) + ": " + s.replace(PYTHON_STACK_REGEX, '') }
							s.replace PYTHON_STACK_REGEX, (match, fileName, lineNumber) ->
								fileName = fileName.replace(PYTHON_PATH_REGEX, '')
								return if fileName.match(/^\//) # skip libraries
								frame.file = fileName
								frame.line = parseInt lineNumber, 10
								seenLocation = true
								errorFrameIndex = i
							if frame.file?
								stackFrames.push frame
								parsedError.file = frame.file
								parsedError.line = frame.line
						if errorFrameIndex?
							stackFrames[errorFrameIndex].type = "error"
						# add the stack frame to the error object
						parsedError.stack = stackFrames if stackFrames.length
						delete parsedError.raw if stackFrames.length == stackLines.length
						parsedErrors.push parsedError
					return ''

				stderr = stderr.replace ///^
					(Error.*(\(from\s\S+\.[rR]\#\d+\))?.*(\n\s\s\S.*)?) # first line has "Error in foo (from file.R#8) blah"
					\n
					(Calls:\s.*\n)?
					((\s*\d+:.*(\s at\s\S+\.[rR]\#\d+)?\n|\s.*\n)*) # stack frames (repeated) have "1: foo() at lib.R#2"
				///m, (match, error, line, continuation, stack) ->
					R_FILE_LINE_REGEX = /\s+\(from (\S+\.[rR])#(\d+)\)/
					R_STACK_REGEX = /\s+at (\S+\.[rR])#(\d+)/
					R_WRAPPER_REGEX = /^Error in eval\(expr, envir, enclos\)/
					# the top-level error
					parsedError = {
						type: "runtime_error"
						# strip any default error text coming from wrapper script
						message: error.replace(R_WRAPPER_REGEX, 'Error').replace(R_FILE_LINE_REGEX, '').replace(/\s?\n^\s+/mg,' ')
						language: "R"
						raw: match
					}
					result = error.match R_FILE_LINE_REGEX
					if result?
						fileName = result[1]
						lineNumber = parseInt result[2], 10
						parsedError.file = fileName
						parsedError.line = lineNumber
					# parse the stack lines (if any)
					stackLines = stack?.replace(/\s?\n^\s+/mg,' ').replace(/\n+$/, '').split '\n'
					if stackLines?
						stackFrames = []
						seenLocation = false # whether we've got a file/line yet
						for s, i in stackLines
							frame = { message: s.replace(R_STACK_REGEX, '') }
							s.replace R_STACK_REGEX, (match, fileName, lineNumber) ->
								frame.file = fileName
								frame.line = parseInt lineNumber, 10
								if !seenLocation
									frame.type = "error"
								seenLocation = true
							stackFrames.push frame if seenLocation
						# add the stack frame to the error object
						parsedError.stack = stackFrames if stackFrames.length
						delete parsedError.raw if stackFrames.length == stackLines.length
						parsedErrors.push parsedError
					return ''
				output.text = stderr
				return parsedErrors

			_displayErrors: (run) ->
				$scope = ide.$scope
				$scope.pdf.logEntryAnnotations = {}

				addError = (error, message = error.message, type = "error") ->
					return unless error.file?
					entity = ide.fileTreeManager.findEntityByPath(error.file)
					if entity?
						$scope.pdf.logEntryAnnotations[entity.id] ||= []
						$scope.pdf.logEntryAnnotations[entity.id].push {
							row: error.line-1
							type: type
							text: message
						}

				formatStackTrace = (error, depth) ->
					formatLine = (frame, i, j) ->
						if i == j then "*" + frame.message else frame.message
					error.message + "\n" + (formatLine(s, i, depth) for s, i in error.stack).join("\n")

				for output in run.output when output.parsedErrors?
					for error in output.parsedErrors
						if error.stack?
							for frame, i in error.stack
								status = if frame.type? then frame.type else "warning"
								addError frame, formatStackTrace(error, i), status
						else
							addError error

				$scope.$evalAsync()


		return commandRunner
