UserLocator = require("./UserLocator")
UserController = require("./UserController")
logger = require("logger-sharelatex")
Settings = require("settings-sharelatex")
fs = require('fs')

module.exports =

	publicRegisterPage : (req, res)->
		sharedProjectData =
			project_name:req.query.project_name
			user_first_name:req.query.user_first_name

		newTemplateData = {}
		if req.session.templateData?
			newTemplateData.templateName = req.session.templateData.templateName

		res.render 'user/register',
			title: 'register'
			redir: req.query.redir
			allowPublicRegistration: settings.allowPublicRegistration
			restrict_domain: Settings.signupDomain?
			domain: Settings.signupDomain
			example_email: if Settings.signupDomain? then 'example@' + Settings.signupDomain else 'email@exmaple.com'
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

	settingsPage : (req, res, next)->
		logger.log user: req.session.user, "loading settings page"
		UserLocator.findById req.session.user._id, (err, user)->
			return next(err) if err?
			res.render 'user/settings',
				title:'account_settings'
				user: user,
				languages: Settings.languages,
				accountSettingsTabActive: true
