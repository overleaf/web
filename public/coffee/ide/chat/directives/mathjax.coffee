define [
	"base"
	"mathjax"
], (App) ->
	mathjaxConfig =
		messageStyle: "none"
		"HTML-CSS":
			availableFonts: ["TeX"]
			matchFontHeight: false
		TeX:
			equationNumbers: { autoNumber: "none" },
			useLabelIDs: false
		tex2jax:
			inlineMath: [ ['$','$'], ["\\(","\\)"] ],
			displayMath: [ ['$$','$$'], ["\\[","\\]"] ],
			processEscapes: true
		skipStartupTypeset: true
		showMathMenu: false

	MathJax?.Hub?.Config(mathjaxConfig);
	
	App.directive "mathjax", () ->
		return {
			link: (scope, element, attrs) ->
				scope.$watch attrs['mathjaxModel'], (value) ->
					element.text(value)
					# element.css(visibility: "hidden")
					MathJax?.Hub?.Queue(
						["Typeset", MathJax?.Hub, element.get(0), () -> console.log("typeset", arguments)],
						# () ->
						# 	element.css(visibility: "visible")
					)
		}