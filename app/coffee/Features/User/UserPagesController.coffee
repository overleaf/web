UserLocator = require("./UserLocator")
UserController = require("./UserController")
dropboxHandler = require('../Dropbox/DropboxHandler')
logger = require("logger-sharelatex")
Settings = require("settings-sharelatex")
fs = require('fs')

module.exports =

	registerPage : (req, res)->
		sharedProjectData =
			project_name:req.query.project_name
			user_first_name:req.query.user_first_name

		newTemplateData = {}
		if req.session.templateData?
			newTemplateData.templateName = req.session.templateData.templateName

		res.render 'user/register',
			title: 'register'
			redir: req.query.redir
			sharedProjectData: sharedProjectData
			newTemplateData: newTemplateData
			new_email:req.query.new_email || ""

	confirmRegistrationPage : (req, res)->
		if req.query.auth_token?
			req.body = req.query
			UserController.confirmRegistration req, res, ((error) ->
				res.render 'user/confirm',
					title: 'confirm'
					error: error
					redir: req.query.redir
			), true
		else
			res.render 'user/confirm',
				title: 'confirm'
				redir: req.query.redir

	loginPage : (req, res)->
		res.render 'user/login',
			title: 'login',
			redir: req.query.redir

	settingsPage : (req, res)->
		logger.log user: req.session.user, "loading settings page"
		UserLocator.findById req.session.user._id, (err, user)->
			dropboxHandler.getUserRegistrationStatus user._id, (err, status)->
				userIsRegisteredWithDropbox = !err? and status.registered
				res.render 'user/settings',
					title:'account_settings',
					userHasDropboxFeature: user.features.dropbox
					userIsRegisteredWithDropbox: userIsRegisteredWithDropbox
					user: user,
					languages: Settings.languages,
					accountSettingsTabActive: true
