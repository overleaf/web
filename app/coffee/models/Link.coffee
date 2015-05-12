mongoose = require 'mongoose'
Settings = require 'settings-sharelatex'
autoIncrement = require 'mongoose-auto-increment'

autoIncrement.initialize(mongoose)

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

LinkSchema = new Schema
	path          :     { type:String, default:'' }
	created       :     { type:Date, default: () -> new Date() }
	project_id    :     { type:ObjectId }
	user_id       :     { type:ObjectId }

LinkSchema.plugin autoIncrement.plugin, { model: 'Link', field: 'public_id', startAt: 100 }

LinkSchema.index {public_id : 1}, {unique: true}

Link = mongoose.model 'Link', LinkSchema

exports.Link = mongoose.model 'Link'
exports.LinkSchema = LinkSchema
