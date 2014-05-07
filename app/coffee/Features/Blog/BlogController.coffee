

module.exports =

	indexPage: (req, res)->
		res.render "blog/indexPage",
			title:"blog posts"

	postExamplePage: (req, res)->
		res.render "blog/post", 
			title:"blog post"