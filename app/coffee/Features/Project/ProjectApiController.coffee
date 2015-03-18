ProjectDetailsHandler = require("./ProjectDetailsHandler")
logger = require("logger-sharelatex")

async = require("async")
Project = require('../../models/Project').Project
TagsHandler = require("../Tags/TagsHandler")
ProjectController = require("./ProjectController")
LimitationsManager = require("../Subscription/LimitationsManager")
User = require('../../models/User').User

module.exports = 

	getProjectDetails : (req, res)->
		{project_id} = req.params
		ProjectDetailsHandler.getDetails project_id, (err, projDetails)->
			if err?
				logger.log err:err, project_id:project_id, "something went wrong getting project details"
				return res.send 500
			req.session.destroy()
			res.json(projDetails)
      
	getProjectList : (req, res)->
		user_id = req.user._id
		Project.findAllUsersProjects user_id, 'name lastUpdated publicAccesLevel archived owner_ref', (err, myProjects, collaborations, readOnlyProjects) ->
			if err?
				logger.err err:err, "error getting data for project list"
				return next(err)
				
			allProjects = myProjects.concat collaborations.concat readOnlyProjects
			logger.log projects: allProjects, "getting all projects"
			res.json({
				projects: allProjects 
			})
