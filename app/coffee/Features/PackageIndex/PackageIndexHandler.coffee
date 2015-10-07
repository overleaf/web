logger = require("logger-sharelatex")
request = require("request")
settings = require("settings-sharelatex")

oneMinInMs = 60 * 1000
fiveMinsInMs = oneMinInMs * 5

module.exports = PackageIndexHandler =

	search: (language, query, callback) ->
		logger.log file_url: file_url, file_name: file_name, "calling package index search service"
		opts =
			method: 'post'
			json: true
			body:
				language: language
				query: query
			uri: "#{settings.apis.packageindex.url}/search"
			timeout: fiveMinsInMs
		request opts, (err, response, body) ->
			return callback(err, null) if err?
			if 200 <= response.statusCode < 300
				callback(null, body)
			else
				logger.log file_url: file_url, status_code: response.statusCode, "Got non-ok response from package index search"
				callback(new Error("Got non-ok response from package index search"}), null)
