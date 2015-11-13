define [
	"base"
	"ide/file-tree/FileTreeManager"
	"ide/connection/ConnectionManager"
	"ide/editor/EditorManager"
	"ide/online-users/OnlineUsersManager"
	"ide/track-changes/TrackChangesManager"
	"ide/permissions/PermissionsManager"
	"ide/binary-files/BinaryFilesManager"
	"ide/script-output/ScriptOutputManager"
	"ide/analytics/AnalyticsManager"
	"ide/settings/index"
	"ide/share/index"
	"ide/chat/index"
	"ide/clone/index"
	"ide/hotkeys/index"
	"ide/install/index"
	"ide/link-image/index"
	"ide/directives/layout"
	"ide/directives/commandLine"
	"ide/directives/expandToContentHeight"
	"ide/services/ide"
	"ide/services/commandRunner"
	"ide/services/jupyterRunner"
	"__IDE_CLIENTSIDE_INCLUDES__"
	"analytics/AbTestingManager"
	"directives/focus"
	"directives/fineUpload"
	"directives/scroll"
	"directives/onEnter"
	"directives/stopPropagation"
	"directives/rightClick"
	"filters/formatDate"
	"main/event"
	"main/account-upgrade"
], (
	App
	FileTreeManager
	ConnectionManager
	EditorManager
	OnlineUsersManager
	TrackChangesManager
	PermissionsManager
	BinaryFilesManager
	ScriptOutputManager
	AnalyticsManager
) ->

	App.controller "IdeController", ($scope, $timeout, ide, localStorage, $http, $injector) ->
		# Don't freak out if we're already in an apply callback
		$scope.$originalApply = $scope.$apply
		$scope.$apply = (fn = () ->) ->
			phase = @$root.$$phase
			if (phase == '$apply' || phase == '$digest')
				fn()
			else
				this.$originalApply(fn);

		$scope.state = {
			loading: true
			load_progress: 40
			error: null
		}
		$scope.ui = {
			leftMenuShown: false
			view: "editor"
			chatOpen: false
			pdfLayout: 'sideBySide'
		}
		$scope.user = window.user
		$scope.settings = window.userSettings
		$scope.anonymous = window.anonymous

		$scope.chat = {}
		$scope.outputFiles = []

		# we want to hide the intercom button when some chat window is open
		# and the same for the console input box
		$scope.showInterCom = (visible = true) ->
			if visible
				$('#intercom-container').show()
			else
				$('#intercom-container').hide()
			return null # don't return dom node

		window._ide = ide

		ide.project_id = $scope.project_id = window.project_id
		ide.$scope = $scope

		ide.connectionManager = new ConnectionManager(ide, $scope)
		ide.fileTreeManager = new FileTreeManager(ide, $scope)
		ide.editorManager = new EditorManager(ide, $scope)
		ide.onlineUsersManager = new OnlineUsersManager(ide, $scope)
		ide.trackChangesManager = new TrackChangesManager(ide, $scope)
		ide.permissionsManager = new PermissionsManager(ide, $scope)
		ide.binaryFilesManager = new BinaryFilesManager(ide, $scope)
		ide.scriptOutputManager = new ScriptOutputManager(ide, $scope)
		ide.analyticsManager = new AnalyticsManager(ide, $scope)

		_pingCompiler = () ->
			try
				commandRunner = $injector.get('commandRunner')
				options =
					compiler: 'command',
					command: ['echo', 'warm-up']
					timeout: 30
					parseErrors: false
				r = commandRunner.run options
				console.log r
			catch err
				console.log ">> could not ping compiler backend"
				console.log err

		inited = false
		$scope.$on "project:joined", () ->
			setTimeout(_pingCompiler, 1000)
			return if inited
			inited = true
			if $scope?.project?.deletedByExternalDataSource
				ide.showGenericMessageModal("Project Renamed or Deleted", """
					This project has either been renamed or deleted by an external data source such as Dropbox.
					We don't want to delete your data on ShareLaTeX, so this project still contains your history and collaborators.
					If the project has been renamed please look in your project list for a new project under the new name.
				""")

		DARK_THEMES = [
			"ambiance", "chaos", "clouds_midnight", "cobalt", "idle_fingers",
			"merbivore", "merbivore_soft", "mono_industrial", "monokai",
			"pastel_on_dark", "solarized_dark", "terminal", "tomorrow_night",
			"tomorrow_night_blue", "tomorrow_night_bright", "tomorrow_night_eighties",
			"twilight", "vibrant_ink"
		]
		$scope.darkTheme = false
		$scope.$watch "settings.theme", (theme) ->
			if theme in DARK_THEMES
				$scope.darkTheme = true
			else
				$scope.darkTheme = false

		ide.localStorage = localStorage

		IGNORE_OUTPUT_FILE_EXTENSIONS = ["pyc"]
		ide.shouldIgnoreOutputFile = (path) ->
			return true if path[0] == "." # don't show dot files
			ext = path.split(".").pop()
			return (ext in IGNORE_OUTPUT_FILE_EXTENSIONS)

	angular.bootstrap(document.body, ["SharelatexApp"])
