define [
	"base"
], (App) ->

	App.factory "event_tracking", ->
		return {
			send: (category, action, attributes = {})->
				ga('send', 'event', category, action)
				Intercom?("trackEvent", "#{action}-#{category}", attributes)
		}

