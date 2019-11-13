/* eslint-disable
    handle-callback-err,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let SystemMessageManager
const { SystemMessage } = require('../../models/SystemMessage')

module.exports = SystemMessageManager = {
  pending: [],

  getMessages(callback) {
    if (callback == null) {
      callback = function(error, messages) {}
    }
    if (this._cachedMessages != null) {
      return callback(null, this._cachedMessages)
    }
    if (this.pending.push(callback) !== 1) {
      return
    }
    this.getMessagesFromDB((error, messages) => {
      if (error == null) {
        this._cachedMessages = messages
      }
      const pending = this.pending
      this.pending = []
      pending.forEach(cb => process.nextTick(cb, error, messages))
    })
  },

  getMessagesFromDB(callback) {
    if (callback == null) {
      callback = function(error, messages) {}
    }
    return SystemMessage.find({}, callback)
  },

  clearMessages(callback) {
    if (callback == null) {
      callback = function(error) {}
    }
    return SystemMessage.remove({}, callback)
  },

  createMessage(content, callback) {
    if (callback == null) {
      callback = function(error) {}
    }
    const message = new SystemMessage({ content })
    return message.save(callback)
  },

  clearCache() {
    return delete this._cachedMessages
  }
}

const CACHE_TIMEOUT = 20 * 1000 // 20 seconds
setInterval(() => SystemMessageManager.clearCache(), CACHE_TIMEOUT)
