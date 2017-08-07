ol_router = require('express').Router();

ol_router.use '/is_ol', (req, res)->
	res.send("true")

module.exports = ol_router