define [
	"ide/script-output/controllers/ScriptOutputController"
	"ide/script-output/directives/stackFrame"
	"ide/script-output/directives/displayImage"
	"ide/script-output/directives/showFormatLabel"
], () ->
	class ScriptOutputManager
		constructor: (@ide, @$scope) ->

