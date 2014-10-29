define [
	"base"
], (App) ->
	App.controller "ScriptOutputController", ($scope, $http, ide) ->
		reset = () ->
			$scope.files = []
			$scope.output = {}
			$scope.running = false
			$scope.error = false
			$scope.timedout = false
			
		$scope.uncompiled = true
		
		$scope.$on "editor:recompile", () ->
			$scope.run()
		
		$scope.run = () ->
			return if $scope.running
			
			reset()
			$scope.running = true
			$scope.uncompiled = false
			
			compiler = "python"
			extension = $scope.editor.open_doc.name.split(".").pop()?.toLowerCase()
			if extension == "r"
				compiler = "r"
			rootDoc_id = $scope.editor.open_doc_id
				
			doCompile(rootDoc_id, compiler)
				.success (data) ->
					$scope.running = false
					$scope.files = parseAndLoadOutputFiles(data?.outputFiles)
					$scope.output = data?.output
					if data?.status == "timedout"
						$scope.timedout = true

				.error () ->
					$scope.running = false
					$scope.error = true
					
		doCompile = (rootDoc_id, compiler) ->
			url = "/project/#{$scope.project_id}/compile"
			$http
				.post(url, {
					_csrf: window.csrfToken
					# Always compile the open doc in this case
					rootDoc_id: rootDoc_id
					compiler: compiler
				})
					
		parseAndLoadOutputFiles = (files = []) ->
			return files
				.map(parseOutputFile)
				.map(loadOutputFile)
				.filter(shouldShowOutputFile)
				.sort(sortOutputFiles)
			
		parseOutputFile = (file) ->
			file.url = "/project/#{$scope.project_id}/output/#{file.path}?cache_bust=#{Date.now()}"
			file.type = "unknown"
			parts = file.path.split(".")
			if parts.length == 1
				extension = null
			else
				extension = parts[parts.length - 1].toLowerCase()
			file.ext = extension
			if extension in ["png", "jpg", "jpeg", "svg", "gif"]
				file.type = "image"
			else if extension in ["pdf"]
				file.type = "pdf"
			else if extension in ["rout"]
				file.type = "text"
			return file
			
		loadOutputFile = (file) ->
			if file.type == "text"
				file.loading = true
				$http.get(file.url)
					.success (content) ->
						file.loading = false
						file.content = content
			return file
					
		shouldShowOutputFile = (file) ->
			# The latex files are left over after a LaTeX compilation and not needed.
			file.ext not in ["pyc", "aux", "fdb_latexmk", "fls"]
		
		PRIORITIES = {
			"rout": 1
			"png": 2
			"jpg": 2
			"jpeg": 2
			"gif": 2
			"svg": 2
			"pdf": 2
		}
		sortOutputFiles = (a, b) ->
			# Sort first by extension
			priorityA = PRIORITIES[a.ext] or 100
			priorityB = PRIORITIES[b.ext] or 100
			result = (priorityA - priorityB)
			
			# Then name
			if result == 0
				if a.name > b.name
					result = -1
				else if a.name < b.name
					result = 1
			
			return result
						
						
				
