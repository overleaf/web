app = angular.module 'PathPatcher', []

app.factory 'pathPatchInterceptor', ['$q','$location', ($q, $location) ->
		request: (config) ->
			if config.url[0] == '/' and config.url.substring(0,2) != '//'
				config.url = config.url.substring(1)
			return config
]

app.config ['$httpProvider', ($httpProvider) ->
	$httpProvider.interceptors.push 'pathPatchInterceptor'
]
