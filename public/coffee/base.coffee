define [
	"libs"
	"modules/recursionHelper"
	"modules/errorCatcher"
	"modules/localStorage"
	"utils/underscore"
], () ->
	App = angular.module("SharelatexApp", [
		"ui.bootstrap"
		"autocomplete"
		"RecursionHelper"
		"ng-context-menu"
		"underscore"
		"ngSanitize"
		"ipCookie"
		"ErrorCatcher"
		"localStorage"
		"luegg.directives" # Scroll glue
		"ansiToHtml"
	])
	App.config( [
		'$compileProvider', ($compileProvider) ->
			# Add data: as an allowed format so that we can download images 
			# returned by Jupyter kernel
			$compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|mailto|data):/);
	])

	return App
