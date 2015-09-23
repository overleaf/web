logger = require("logger-sharelatex")
request = require("request")
settings = require("settings-sharelatex")

oneMinInMs = 60 * 1000
fiveMinsInMs = oneMinInMs * 5

module.exports = PreviewHandler =

	getPreview: (file_url, file_name, callback) ->
		logger.log file_url: file_url, file_name: file_name, "getting preview of file"
		opts =
			method: 'get'
			uri: @_build_url file_url, file_name
			timeout: fiveMinsInMs
		request opts, (err, response, body) ->
			return callback(err, null) if err?
			if 200 <= response.statusCode < 300
				callback(null, body)
			else
				logger.log file_url: file_url, status_code: response.statusCode, "Got non-ok response from Previewer"
				callback(new Error("Got non-ok response from Previewer service: #{response.statusCode}"), null)

	_build_url: (file_url, file_name) ->
		return "#{settings.apis.previewer.url}/preview?fileUrl=#{file_url}&fileName=#{file_name}"
