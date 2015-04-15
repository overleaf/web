ProjectDetailsHandler = require("./ProjectDetailsHandler")
logger = require("logger-sharelatex")

async = require("async")
Project = require('../../models/Project').Project
TagsHandler = require("../Tags/TagsHandler")
ProjectController = require("./ProjectController")

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
		async.parallel {
			tags: (cb)->
				TagsHandler.getAllTags user_id, cb
			projects: (cb)->
				Project.findAllUsersProjects user_id, 'name lastUpdated publicAccesLevel archived owner_ref', cb
			}, (err, results)->
				if err?
					logger.err err:err, "error getting data for project list"
					return res.send 500
				logger.log results:results, user_id:user_id, "building project list"
				tags = results.tags[0]
				projects = ProjectController._buildProjectList results.projects[0], results.projects[1], results.projects[2]
				logger.log projects: projects, "final project list"
				res.json({
					projects: projects 
					tags: tags
				})
