import TrialController = require('./TrialController')


interface Router {get: Function}


export function apply(webRouter: Router, apiRouter: Router): void {
		console.log(">> HELLO FROM TS", TrialController.testMessage())
}
