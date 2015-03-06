// Copyright (C) 2013 Luegg
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
(function(angular, undefined){
	'use strict';
	
	function createActivationState($parse, attr, scope){
		function unboundState(initValue){
			var activated = initValue;
			return {
				getValue: function(){
					return activated;
				},
				setValue: function(value){
					activated = value;
				}
			};
		}
		
		function oneWayBindingState(getter, scope){
			return {
				getValue: function(){
					return getter(scope);
				},
				setValue: function(){}
			}
		}
		
		function twoWayBindingState(getter, setter, scope){
			return {
				getValue: function(){
					return getter(scope);
				},
				setValue: function(value){
					if(value !== getter(scope)){
						scope.$apply(function(){
							setter(scope, value);
						});
					}
				}
			};
		}
		
		if(attr !== ""){
			var getter = $parse(attr);
			if(getter.assign !== undefined){
				return twoWayBindingState(getter, getter.assign, scope);
			} else {
				return oneWayBindingState(getter, scope);
			}
		} else {
			return unboundState(true);
		}
	}
	
	function createDirective(module, attrName, direction){
		module.directive(attrName, ['$parse', function($parse){
			return {
				priority: 1,
				restrict: 'A',
				link: function(scope, $el, attrs){
					var el = $el[0],
					activationState = createActivationState($parse, attrs[attrName], scope);
					
					scope.$watch(function(){
						if(activationState.getValue() && !direction.isAttached(el)){
							direction.scroll(el);
						}
					});
					
					$el.bind('scroll', function(){
						activationState.setValue(direction.isAttached(el));
					});
				}
			};
		}]);
	}
	
	var bottom = {
		isAttached: function(el){
			// + 1 catches off by one errors in chrome
			return el.scrollTop + el.clientHeight + 1 >= el.scrollHeight;
		},
		scroll: function(el){
			el.scrollTop = el.scrollHeight;
		}
	};
	
	var top = {
		isAttached: function(el){
			return el.scrollTop <= 1;
		},
		scroll: function(el){
			el.scrollTop = 0;
		}
	};
	
	var right = {
		isAttached: function(el){
			return el.scrollLeft + el.clientWidth + 1 >= el.scrollWidth;
		},
		scroll: function(el){
			el.scrollLeft = el.scrollWidth;
		}
	};
	
	var left = {
		isAttached: function(el){
			return el.scrollLeft <= 1;
		},
		scroll: function(el){
			el.scrollLeft = 0;
		}
	};
	
	var module = angular.module('luegg.directives', []);
	
	createDirective(module, 'scrollGlue', bottom);
	createDirective(module, 'scrollGlueTop', top);
	createDirective(module, 'scrollGlueBottom', bottom);
	createDirective(module, 'scrollGlueLeft', left);
	createDirective(module, 'scrollGlueRight', right);
}(angular));