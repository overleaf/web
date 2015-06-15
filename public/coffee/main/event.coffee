define [
	"base"
], (App) ->
	send = (category, action, attributes = {})->
		ga('send', 'event', category, action)
		event_name = "#{action}-#{category}"
		Intercom?("trackEvent", event_name, attributes)
		$.ajax {
			url: "/event/#{event_name}",
			method: "POST",
			data: attributes,
			dataType: "json",
			headers: {
				"X-CSRF-Token": window.csrfToken
			}
		}

	App.factory "event_tracking", ->
		return send: send

	if window.events?
		for event in window.events
			send.apply(send, event)
