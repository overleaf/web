define [
	"ide/editor/Document"
	"ide/editor/directives/aceEditor"
	"ide/editor/controllers/SavingNotificationController"
], (Document) ->
	class EditorManager
		constructor: (@ide, @$scope) ->
			@$scope.editor = {
				sharejs_doc: null
				open_doc_id: null
				open_doc: null
				opening: true
				editor_mode: null
				ace_mode: null
			}

			@$scope.$on "entity:selected", (event, entity) =>
				if (@$scope.ui.view != "track-changes" and entity.type == "doc")
					@openDoc(entity)

			@$scope.$on "entity:deleted", (event, entity) =>
				if @$scope.editor.open_doc_id == entity.id
					return if !@$scope.project.rootDoc_id
					doc = @ide.fileTreeManager.findEntityById(@$scope.project.rootDoc_id)
					return if !doc?
					@openDoc(doc)

			initialized = false
			@$scope.$on "file-tree:initialized", () =>
				if !initialized
					initialized = true
					@autoOpenDoc()

			@$scope.$on "flush-changes", () =>
				Document.flushAll()

		autoOpenDoc: () ->
			open_doc_id = 
				@ide.localStorage("doc.open_id.#{@$scope.project_id}") or
				@$scope.project.rootDoc_id
			if open_doc_id?
				doc = @ide.fileTreeManager.findEntityById(open_doc_id)
			if !doc?
				doc = @ide.fileTreeManager.getAllActiveDocs()[0]
			return if !doc?
			@openDoc(doc)

		openDoc: (doc, options = {}) ->
			@$scope.ui.view = "editor"

			done = () =>
				if options.gotoLine?
					@$scope.$broadcast "editor:gotoLine", options.gotoLine
			
			if doc.id == @$scope.editor.open_doc_id and !options.forceReopen
				@$scope.$apply () =>
					done()
				return

			@$scope.editor.open_doc_id = doc.id
			@$scope.editor.open_doc = doc
			@$scope.editor.editor_mode = @_getEditorModeFromDoc(doc)
			@$scope.editor.ace_mode = @_getAceModeFromDoc(doc)

			@ide.localStorage "doc.open_id.#{@$scope.project_id}", doc.id
			@ide.fileTreeManager.selectEntity(doc)

			@$scope.editor.opening = true
			@_openNewDocument doc, (error, sharejs_doc) =>
				if error?
					@ide.showGenericMessageModal(
						"Error opening document"
						"Sorry, something went wrong opening this document. Please try again."
					)
					return

				@$scope.$broadcast "doc:opened"

				@$scope.$apply () =>
					@$scope.editor.opening = false
					@$scope.editor.sharejs_doc = sharejs_doc
					done()

		_openNewDocument: (doc, callback = (error, sharejs_doc) ->) ->
			current_sharejs_doc = @$scope.editor.sharejs_doc
			if current_sharejs_doc?
				current_sharejs_doc.leaveAndCleanUp()
				@_unbindFromDocumentEvents(current_sharejs_doc)

			new_sharejs_doc = Document.getDocument @ide, doc.id

			new_sharejs_doc.join (error) =>
				return callback(error) if error?
				@_bindToDocumentEvents(doc, new_sharejs_doc)
				callback null, new_sharejs_doc

		_bindToDocumentEvents: (doc, sharejs_doc) ->
			sharejs_doc.on "error", (error, meta) =>
				if error?.message?.match "maxDocLength"
					@ide.showGenericMessageModal(
						"Document Too Long"
						"Sorry, this file is too long to be edited manually. Please upload it directly."
					)
				else
					@ide.socket.disconnect()
					@ide.reportError(error, meta)
					@ide.showGenericMessageModal(
						"Out of sync"
						"Sorry, this file has gone out of sync and we need to do a full refresh. Please let us know if this happens frequently."
					)
				@openDoc(doc, forceReopen: true)

			sharejs_doc.on "externalUpdate", (update) =>
				return if @_ignoreExternalUpdates
				@ide.showGenericMessageModal(
					"Document Updated Externally"
					"This document was just updated externally. Any recent changes you have made may have been overwritten. To see previous versions please look in the history."
				)

		_unbindFromDocumentEvents: (document) ->
			document.off()

		_getEditorModeFromDoc: (doc) ->
			return "script"

		# Ace Syntax Highlighting Modes
		_getAceModeFromDoc: (doc) ->
			extension = doc.name.split(".").pop()?.toLowerCase()
			if extension == "py"
				return "python"
			else if extension == "r"
				return "r"
			else if extension in ["cpp", "c"]
				return "c_cpp"
			else if extension == "json"
				return "json"
			else if extension in ["md", "markdown"]
				return "markdown"
			else if extension == "sh"
				return "sh"
			else if extension == "xml"
				return "xml"
			else if extension in ["yaml", "yml"]
				return "yaml"
			else
				return "latex"

		getCurrentDocValue: () ->
			@$scope.editor.sharejs_doc?.getSnapshot()

		getCurrentDocId: () ->
			@$scope.editor.open_doc_id
			
		startIgnoringExternalUpdates: () ->
			@_ignoreExternalUpdates = true
			
		stopIgnoringExternalUpdates: () ->
			@_ignoreExternalUpdates = false
