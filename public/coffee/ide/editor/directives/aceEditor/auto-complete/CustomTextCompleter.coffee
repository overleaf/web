define [
	"ace/ace"
], () ->

	Range = ace.require("ace/range").Range

	stripUnwantedText =  (original_text) ->
		_.reduce(
			[
				/#(.*)$/m                  # remove comments
				/('|").*\1/mg              # remove string contents
				/^\s*(?:-|_|=){4}.*\s*$/mg # remove markdown-alike lines
				/\b(\d+)\b/mg              # remove numeric literals
			]
			(text, re) -> text.replace(re, ' ')
			original_text
		)

	splitRegex = /[^a-zA-Z_0-9\$\-\u00C0-\u1FFF\u2C00-\uD7FF\w]+/

	# this is mostly a replica of ace/autocomplete/text_completer,
	# except it ignores text within comments and strings as best it can
	class CustomTextCompleter

		@init: (editor) ->
			# find the completer responsible for the 'local' suggestions
			# and replace it with ours, an instance of this class
			target_index = null
			for completer, i in editor.completers
				if completer.getCompletions.toString().indexOf('wordDistance(') >= 0
					target_index = i
					break
			if target_index
				editor.completers.splice(target_index, 1, new CustomTextCompleter(editor))
			else
				console.warn "Could not find suitable target to replace with CustomTextCompleter"

		constructor: (@editor) ->

		# these methods are much the same as in ace/autocomplete/text_completer,
		# except for the calls to stripUnwantedText()
		getWordIndex: (doc, pos) ->
			textBefore = doc.getTextRange(Range.fromPoints({row: 0, column:0}, pos))
			textBefore = stripUnwantedText(textBefore)
			return textBefore.split(splitRegex).length - 1

		wordDistance: (doc, pos) ->
			prefixPos = @getWordIndex(doc, pos)
			words = stripUnwantedText(doc.getValue()).split(splitRegex)
			wordScores = Object.create(null)

			currentWord = words[prefixPos]

			words.forEach((word, idx) ->
				if (!word || word == currentWord)
					return
				distance = Math.abs(prefixPos - idx)
				score = words.length - distance
				if (wordScores[word])
					wordScores[word] = Math.max(score, wordScores[word])
				else
					wordScores[word] = score;
			)
			return wordScores

		getCompletions: (editor, session, pos, prefix, callback) ->
			wordScore = @wordDistance(session, pos, prefix)
			wordList = Object.keys(wordScore)
			callback(null, wordList.map((word) ->
					{
							caption: word,
							value: word,
							score: wordScore[word],
							meta: "local"
					}
			))
