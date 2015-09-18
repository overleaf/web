define [
	"ide/script-output/controllers/ScriptOutputController"
	"ide/script-output/controllers/InputRequestController"
	"ide/script-output/directives/displayImage"
	"ide/script-output/directives/showFormatLabel"
], () ->
	class ScriptOutputManager
		constructor: (@ide, @$scope) ->
