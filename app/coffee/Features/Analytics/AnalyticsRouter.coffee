AnalyticsController = require('./AnalyticsController')

module.exports =
	apply: (app) ->
		app.post '/event/:event', AnalyticsController.recordEvent
