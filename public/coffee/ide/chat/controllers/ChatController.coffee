define [
	"base"
	"ide/chat/services/chatMessages"
], (App) ->
	App.controller "ChatController", ($scope, chatMessages, ide, $location) ->
		$scope.chat = chatMessages.state
		
		$scope.$watch "chat.messages", (messages) ->
			if messages?
				$scope.$emit "updateScrollPosition"
		, true # Deep watch
		
		$scope.$on "layout:chat:resize", () ->
			$scope.$emit "updateScrollPosition"
			
		$scope.$watch "chat.newMessage", (message) ->
			if message?
				ide.$scope.$broadcast "chat:newMessage", message
				
		$scope.resetUnreadMessages = () ->
			ide.$scope.$broadcast "chat:resetUnreadMessages"
				
		$scope.sendMessage = ->
			message = $scope.newMessageContent
			$scope.newMessageContent = ""
			chatMessages
				.sendMessage message
				
		$scope.loadMoreMessages = ->
			chatMessages.loadMoreMessages()
			
		# FIXME: we need an intercom directive instead of putting this here
		# we want to hide the intercom button when the chat window is open
		# we could do the same for the console input box
		$scope.showInterCom = (visible = true) ->
			if visible
				$('#intercom-container').show()
			else
				$('#intercom-container').hide()
