Settings = require "settings-sharelatex"
logger = require "logger-sharelatex"
_ = require "underscore"

if !Settings.mysql.metrics?
	module.exports =
		recordEvent: (user_id, event, metadata, callback) ->
			logger.log {user_id, event, metadata}, "no event tracking configured, logging event"
			callback()
else
	Sequelize = require "sequelize"
	options = _.extend {logging:false}, Settings.mysql.metrics

	sequelize = new Sequelize(
		Settings.mysql.metrics.database,
		Settings.mysql.metrics.username,
		Settings.mysql.metrics.password,
		options
	)
	
	Event = sequelize.define("Event", {
		user_id: Sequelize.STRING,
		event: Sequelize.STRING,
		metadata: Sequelize.STRING
	})

	module.exports =
		recordEvent: (user_id, event, metadata, callback = (error) ->) ->
			if typeof(metadata) != "string"
				metadata = JSON.stringify(metadata)
			Event
				.create({ user_id, event, metadata })
				.then(
					(result) -> callback(),
					(error) -> callback(error)
				)
			
		sync: () -> sequelize.sync()