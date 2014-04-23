module.exports =

	templatesIndexPath: (req, res)->
		res.render "templates/indexPage", 
			title:"templates example page"


	templateExamplePage: (req, res)->
		res.render "templates/templatePage", 
			title:"template"