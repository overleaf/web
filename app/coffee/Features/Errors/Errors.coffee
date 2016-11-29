NotFoundError = (message) ->
	error = new Error(message)
	error.name = "NotFoundError"
	error.__proto__ = NotFoundError.prototype
	return error
NotFoundError.prototype.__proto__ = Error.prototype


# DeniedError = (message) ->
# 	error = new Error(message)
# 	error.name = "DeniedError"
# 	error.__proto__ = DeniedError.prototype
# 	return error
# DeniedError.prototype.__proto__ = Error.prototype


module.exports = Errors =
	NotFoundError: NotFoundError
	# DeniedError:   DeniedError
