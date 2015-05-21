define [
	"base"
], (App) ->
	# We create and provide this as service so that we can access the global ide
	# from within other parts of the angular app.
	App.factory "jupyterRunner", ($http, $timeout, ide, ansi2html, $sce) ->
		ide.socket.on "clsiOutput", (message) ->
			engine_and_request_id = message.request_id
			return if !engine_and_request_id?
			[engine,request_id] = engine_and_request_id?.split(":")
			if !request_id? or !engine?
				# The message isn't a jupyter message, likely from commandRunner instead.
				return
			
			cell = jupyterRunner.findOrCreateCell(request_id, engine)
			
			jupyterRunner.status.initing = false
			if jupyterRunner._initingTimeout?
				$timeout.cancel(jupyterRunner._initingTimeout)
				delete jupyterRunner._initingTimeout
			
			if message.header.msg_type == "shutdown_reply"
				cell.shutdown = true
			
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
					jupyterRunner.status.running = true
				else if message.content.execution_state == "idle"
					jupyterRunner.status.running = false
		
			ide.$scope.$apply()
		
		ansiToSafeHtml = (input) ->
			input = input
				.replace(/&/g, "&amp;")
				.replace(/</g, "&lt;")
				.replace(/>/g, "&gt;")
				.replace(/"/g, "&quot;")
				.replace(/'/g, "&#039;")
			return $sce.trustAsHtml(ansi2html.toHtml(input))
		
		jupyterRunner =
			CELL_LIST: {}
			CELLS: {}
			
			status: {
				running: false,
				stopping: false,
				error: false,
				initing: false
			}
			
			current_request_id: null
		
			executeRequest: (code, engine) ->
				request_id = Math.random().toString().slice(2)
				@current_request_id = "#{engine}:#{request_id}"
				@status.running = true
				@status.error = false
				
				@_initingTimeout = $timeout () =>
					@status.initing = true
				, 2000

				url = "/project/#{ide.$scope.project_id}/request"
				options = {
					request_id: "#{engine}:#{request_id}"
					msg_type: "execute_request"
					content: {
						code: code,
						silent: false,
						store_history: true,
						user_expressions: {},
						allow_stdin: false,
						stop_on_error: false
					}
					engine: engine
					_csrf: window.csrfToken
				}
				$http
					.post(url, options)
					.success (data) =>
						@status.running = false
					.error () =>
						@status.error = true
						@status.running = false
			
			findOrCreateCell: (request_id, engine) ->
				if jupyterRunner.CELLS[request_id]?
					return jupyterRunner.CELLS[request_id]
				else
					cell = {
						request_id: request_id
						engine: engine
						input: []
						output: []
					}
					jupyterRunner.CELLS[request_id] = cell
					jupyterRunner.CELL_LIST[engine] ||= []
					jupyterRunner.CELL_LIST[engine].push cell
					return cell
			
			stop: () ->
				request_id = @current_request_id
				return if !request_id?
				url = "/project/#{_ide.$scope.project_id}/request/#{request_id}/interrupt"
				$http
					.post(url, {
						_csrf: window.csrfToken
					})
			
			shutdown: (engine) ->
				request_id = Math.random().toString().slice(2)
				@current_request_id = "#{engine}:#{request_id}"
				url = "/project/#{ide.$scope.project_id}/request"
				options = {
					request_id: "#{engine}:#{request_id}"
					msg_type: "shutdown_request"
					content: {
						restart: true
					}
					engine: engine
					_csrf: window.csrfToken
				}
				$http
					.post(url, options)
					.success (data) =>
						console.log "SHUTDOWN REPLY", data
					.error () =>
						@status.error = true

		return jupyterRunner
