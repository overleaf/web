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
	public_id     :     { type:String }

LinkSchema.plugin autoIncrement.plugin, { model: 'Link', field: 'count_id', startAt: 100 }

LinkSchema.index {public_id : 1}, {unique: true, sparse: true}

Link = mongoose.model 'Link', LinkSchema

exports.Link = mongoose.model 'Link'
exports.LinkSchema = LinkSchema
