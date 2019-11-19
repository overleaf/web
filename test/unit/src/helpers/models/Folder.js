const mockModel = require('../MockModel')

module.exports = mockModel('Folder', {
  './File': require('./File'),
  './Doc': require('./Doc')
})
