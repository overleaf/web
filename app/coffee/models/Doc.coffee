mongoose = require 'mongoose'
Settings = require 'settings-sharelatex'

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

DocSchema = new Schema
	name          :     {type:String, default:'new doc'},
        mimetype	:	{type:String, default:'application/x-tex'}


mongoose.model 'Doc', DocSchema
exports.Doc = mongoose.model 'Doc'
exports.DocSchema = DocSchema
