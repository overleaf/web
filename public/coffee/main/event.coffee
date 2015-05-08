define [
	"base"
], (App) ->
	send = (category, action, attributes = {})->
		ga('send', 'event', category, action)
		Intercom?("trackEvent", "#{action}-#{category}", attributes)

	App.factory "event_tracking", ->
		return send: send

	if window.events?
		for event in window.events
			send.apply(send, event)
