Link = require("../../models/Link").Link

RX = /[01iloILO]/g  # regex to avoid hard-to-read characters
NUMBERS = "0123456789".replace RX, ''
BASE = "abcdefghijklmnopqrstuvwxyz".replace RX, ''
CHARS = (NUMBERS + BASE)

MAX_TRIES = 12 # maximum length of an id

getRandom = (str) ->
	len = str.length
	idx = Math.floor(Math.random()*len) % len
	return str[idx]

randomId = (n) ->
	# random string of n characters
	result = ""
	while result.length < n
		result = result + getRandom(CHARS)
	# break up any sequences of 3 letters to avoid words in output
	result.replace /([a-zA-Z][a-zA-Z])([a-zA-Z])/g, (a, b, c) ->
		return b + getRandom(NUMBERS)

module.exports =

	createNewLink: (opts, callback)->
		link = new Link()
		link.path = opts.path
		link.project_id = opts.project_id
		link.user_id = opts.user_id
		link.save (err)->
			return callback(err) if err?
			# now try to find an unused public id
			tryPublicId = (N) ->
				link.public_id = randomId(N)
				link.save (err) ->
					if err? # couldn't update it, try increasing id length
						if N < MAX_TRIES
							tryPublicId(N+1)
						else
							callback(err) # maybe a real datbase error
					else
						callback(err, link)	# success, valid public id
			# start with a random id of length 4
			tryPublicId(6)
