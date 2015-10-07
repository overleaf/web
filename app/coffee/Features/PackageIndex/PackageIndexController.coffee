logger = require('logger-sharelatex')
PackageIndexHandler = require('./PackageIndexHandler')


module.exports = PackageIndexController =

	search: (req, res) ->
		{language, query} = req.body
		logger.log language: language, query: query, "searching package index"
		PackageIndexHandler.search language, query, (err, search_result) ->
			if err
				logger.log language: language, query: query, "error searching package index"
				return res.status(500).send()
			res.setHeader("Content-Type", "application/json")
			res.status(200).send(search_result)
