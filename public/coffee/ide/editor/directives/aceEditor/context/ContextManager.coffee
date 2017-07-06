define [
	"ace/ace"
], () ->
	Range = ace.require("ace/range").Range

	class ContextManager
		constructor: (@$scope, @editor, @element) ->
			@contexts = []
			
			onLint = (data) =>
				contexts = data?.data?.contexts
				@updateContext(contexts)
			
			onChangeCursor = () =>
				@recalculateContext()
				
			tryBindWorker = (session) ->
				if session.$worker?
					session.$worker.on 'lint', onLint
				else
					setTimeout () ->
						tryBindWorker(session)
					, 100
			
			@editor.on "changeSession", (e) =>
				e.oldSession?.selection.off "changeCursor", onChangeCursor
				e.session.selection.on "changeCursor", onChangeCursor
				
				e.oldSession?.$worker?.off 'lint', onLint
				tryBindWorker(e.session)

		updateContext: (contexts) ->
			doc = @editor.getSession().getDocument()
			for context in @contexts
				context.range.start.detach()
				context.range.end.detach()
			@contexts = []
			for context in contexts
				if context.range.start? and context.range.end?
					@contexts.push {
						range: 
							start: doc.createAnchor(context.range.start),
							end: doc.createAnchor(context.range.end)
						mathMode: (context.type == "math")
					}
			@recalculateContext()
	
		recalculateContext: () ->
			_recalculateContext = () =>
				cursor = @editor.getCursorPosition()
				mathMode = false
				for context in @contexts
					range = Range.fromPoints(context.range.start, context.range.end)
					if context.mathMode and range.contains(cursor.row, cursor.column)
						mathMode = {
							content: @editor.getSession().getDocument().getLinesForRange(range).join("\n")
						}
						break
				@$scope.context = { mathMode }
			setTimeout _recalculateContext, 0 # Give Ace a chance to update anchored ranges
