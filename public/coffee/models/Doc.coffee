define [
	"libs/backbone"
], () ->
	Doc = Backbone.Model.extend
		initialize: () ->
			@set("type", "doc")
			@set("icon", "file")

		parse: (rawAttributes) ->
			attributes =
				id: rawAttributes._id
				name: rawAttributes.name
