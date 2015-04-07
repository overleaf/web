define [
	"ide/script-output/controllers/ScriptOutputController"
	"ide/script-output/directives/stackFrame"
], () ->
	class ScriptOutputManager
		constructor: (@ide, @$scope) ->

