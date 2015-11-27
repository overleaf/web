define [], () ->
	class Parser
		constructor: (@doc) ->

		parse: () ->
			commands = []
			seen = {}
			while command = @nextCommand()
				docState = @doc

				optionalArgs = 0
				while @consumeArgument("[", "]")
					optionalArgs++

				args = 0
				while @consumeArgument("{", "}")
					args++

				commandHash = "#{command}\\#{optionalArgs}\\#{args}"
				if !seen[commandHash]?
					seen[commandHash] = true
					commands.push [command, optionalArgs, args]

				# Reset to before argument to handle nested commands
				@doc = docState

			return commands

		# Ignore single letter commands since auto complete is moot then.
		commandRegex: /\\([a-zA-Z][a-zA-Z]+)/

		nextCommand: () ->
			i = @doc.search(@commandRegex)
			if i == -1
				return false
			else
				match = @doc.match(@commandRegex)[1]
				@doc = @doc.substr(i + match.length + 1)
				return match

		consumeWhitespace: () ->
			match = @doc.match(/^[ \t\n]*/m)[0]
			@doc = @doc.substr(match.length)

		consumeArgument: (openingBracket, closingBracket) ->
			@consumeWhitespace()

			if @doc[0] == openingBracket
				i = 1
				bracketParity = 1
				while bracketParity > 0 and i < @doc.length
					if @doc[i] == openingBracket
						bracketParity++
					else if @doc[i] == closingBracket
						bracketParity--
					i++

				if bracketParity == 0
					@doc = @doc.substr(i)
					return true
				else
					return false
			else
				return false

	class SuggestionManager
		completionTimeout: null
		getCompletions: (editor, session, pos, prefix, callback) ->
			line = session.getLine(pos.row).slice(0, pos.column)
			# console.log "getCompletions", pos, prefix, line
			if @completionTimeout?
				clearTimeout(@completionTimeout)
			@completionTimeout = setTimeout () =>
				engine = window?._ide?.$scope?.engine || 'python'
				window._JUPYTER_RUNNER.executeCompletionRequest line, pos.column, engine, (results) ->
					completions = []
					for match in results.matches or []
						# console.log "CONSIDERING", match
						# Need to figure out how to properly complete
						#    plt.show(np.s|)
						# where | is the cursor.
						# In this case, prefix is 's', line is 'plt.show(np.s'
						# and the kernel returns 'np.sin', etc. Ace expects
						# a completion of the 'prefix', so we need to return 'sin'.
						# It's not clear how to determine that the 'np.' is what we need
						# to strip.
						if match.indexOf(line) == 0
							completion = prefix + match.slice(line.length)
							# console.log "MATCHES START", completion
							completions.push {
								caption: completion
								snippet: completion
								meta: "cmd"
							}
						else
							# try to catch the case above: plt.show(np.s|)
							if match.indexOf('.') >= 0
								completion = match.slice(match.indexOf('.') + 1)
							else
								completion = match
							# console.log "MATCHES LATER", completion
							completions.push {
								caption: completion
								snippet: completion
								meta: "cmd"
							}

					@completionTimeout = null
					console.log "completions", completions
					callback null, completions
			, 500

		loadCommandsFromDoc: (doc) ->
			parser = new Parser(doc)
			@commands = parser.parse()

		getSuggestions: (commandFragment) ->
			matchingCommands = _.filter @commands, (command) ->
				command[0].slice(0, commandFragment.length) == commandFragment

			return _.map matchingCommands, (command) ->
				base = "\\" + commandFragment

				args = ""
				_.times command[1], () -> args = args + "[]"
				_.times command[2], () -> args = args + "{}"
				completionBase = command[0].slice(commandFragment.length)

				squareArgsNo = command[1]
				curlyArgsNo = command[2]
				totalArgs = squareArgsNo + curlyArgsNo
				if totalArgs == 0
					completionBeforeCursor = completionBase
					completionAfterCurspr = ""
				else
					completionBeforeCursor = completionBase + args[0]
					completionAfterCursor = args.slice(1)

				return {
					base: base,
					completion: completionBase + args,
					completionBeforeCursor: completionBeforeCursor
					completionAfterCursor: completionAfterCursor
				}
