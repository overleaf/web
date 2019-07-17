/* eslint-disable
    max-len,
    no-return-assign,
    no-unused-vars,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const should = require('chai').should()
const spies = require('chai-spies')
const chai = require('chai').use(spies)
const sinon = require('sinon')
const SandboxedModule = require('sandboxed-module')
const { assert } = require('chai')
const path = require('path')
const _ = require('underscore')
const { ObjectId } = require('mongojs')
const modulePath = path.join(
  __dirname,
  '../../../../app/src/Features/DocumentUpdater/DocumentUpdaterHandler'
)

describe('DocumentUpdaterHandler', function() {
  beforeEach(function() {
    this.project_id = 'project-id-923'
    this.projectHistoryId = 'ol-project-id-1'
    this.doc_id = 'doc-id-394'
    this.lines = ['one', 'two', 'three']
    this.version = 42
    this.user_id = 'mock-user-id-123'
    this.project = { _id: this.project_id }

    this.request = sinon.stub()
    this.projectEntityHandler = {}
    this.settings = {
      apis: {
        documentupdater: {
          url: 'http://document_updater.example.com'
        },
        project_history: {
          url: 'http://project_history.example.com'
        }
      }
    }

    this.callback = sinon.stub()
    return (this.handler = SandboxedModule.require(modulePath, {
      globals: {
        console: console
      },
      requires: {
        request: {
          defaults: () => {
            return this.request
          }
        },
        'settings-sharelatex': this.settings,
        'logger-sharelatex': { log() {}, error() {}, warn() {} },
        '../Project/ProjectEntityHandler': this.projectEntityHandler,
        '../../models/Project': {
          Project: (this.Project = {})
        },
        '../../Features/Project/ProjectLocator': {},
        'metrics-sharelatex': {
          Timer: class {
            done() {}
          }
        }
      }
    }))
  })

  describe('flushProjectToMongo', function() {
    describe('successfully', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 204 }, '')
        return this.handler.flushProjectToMongo(this.project_id, this.callback)
      })

      it('should flush the document from the document updater', function() {
        return this.request
          .calledWithMatch({
            url: `${this.settings.apis.documentupdater.url}/project/${
              this.project_id
            }/flush`,
            method: 'POST'
          })
          .should.equal(true)
      })

      it('should call the callback with no error', function() {
        return this.callback.calledWith(null).should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.callsArgWith(
          1,
          (this.error = new Error('something went wrong')),
          null,
          null
        )
        return this.handler.flushProjectToMongo(this.project_id, this.callback)
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns a failure error code', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 500 }, '')
        return this.handler.flushProjectToMongo(this.project_id, this.callback)
      })

      it('should return the callback with an error', function() {
        return this.callback
          .calledWith(
            new Error('doc updater returned failure status code: 500')
          )
          .should.equal(true)
      })
    })
  })

  describe('flushProjectToMongoAndDelete', function() {
    describe('successfully', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 204 }, '')
        return this.handler.flushProjectToMongoAndDelete(
          this.project_id,
          this.callback
        )
      })

      it('should delete the project from the document updater', function() {
        return this.request
          .calledWithMatch({
            url: `${this.settings.apis.documentupdater.url}/project/${
              this.project_id
            }`,
            method: 'DELETE'
          })
          .should.equal(true)
      })

      it('should call the callback with no error', function() {
        return this.callback.calledWith(null).should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.callsArgWith(
          1,
          (this.error = new Error('something went wrong')),
          null,
          null
        )
        return this.handler.flushProjectToMongoAndDelete(
          this.project_id,
          this.callback
        )
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns a failure error code', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 500 }, '')
        return this.handler.flushProjectToMongoAndDelete(
          this.project_id,
          this.callback
        )
      })

      it('should return the callback with an error', function() {
        return this.callback
          .calledWith(
            new Error('doc updater returned failure status code: 500')
          )
          .should.equal(true)
      })
    })
  })

  describe('flushDocToMongo', function() {
    describe('successfully', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 204 }, '')
        return this.handler.flushDocToMongo(
          this.project_id,
          this.doc_id,
          this.callback
        )
      })

      it('should flush the document from the document updater', function() {
        return this.request
          .calledWithMatch({
            url: `${this.settings.apis.documentupdater.url}/project/${
              this.project_id
            }/doc/${this.doc_id}/flush`,
            method: 'POST'
          })
          .should.equal(true)
      })

      it('should call the callback with no error', function() {
        return this.callback.calledWith(null).should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.callsArgWith(
          1,
          (this.error = new Error('something went wrong')),
          null,
          null
        )
        return this.handler.flushDocToMongo(
          this.project_id,
          this.doc_id,
          this.callback
        )
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns a failure error code', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 500 }, '')
        return this.handler.flushDocToMongo(
          this.project_id,
          this.doc_id,
          this.callback
        )
      })

      it('should return the callback with an error', function() {
        return this.callback
          .calledWith(
            new Error('doc updater returned failure status code: 500')
          )
          .should.equal(true)
      })
    })
  })

  describe('deleteDoc', function() {
    describe('successfully', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 204 }, '')
        return this.handler.deleteDoc(
          this.project_id,
          this.doc_id,
          this.callback
        )
      })

      it('should delete the document from the document updater', function() {
        return this.request
          .calledWithMatch({
            url: `${this.settings.apis.documentupdater.url}/project/${
              this.project_id
            }/doc/${this.doc_id}`,
            method: 'DELETE'
          })
          .should.equal(true)
      })

      it('should call the callback with no error', function() {
        return this.callback.calledWith(null).should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.callsArgWith(
          1,
          (this.error = new Error('something went wrong')),
          null,
          null
        )
        return this.handler.deleteDoc(
          this.project_id,
          this.doc_id,
          this.callback
        )
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns a failure error code', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 500 }, '')
        return this.handler.deleteDoc(
          this.project_id,
          this.doc_id,
          this.callback
        )
      })

      it('should return the callback with an error', function() {
        return this.callback
          .calledWith(
            new Error('doc updater returned failure status code: 500')
          )
          .should.equal(true)
      })
    })
  })

  describe('setDocument', function() {
    beforeEach(function() {
      return (this.source = 'dropbox')
    })

    describe('successfully', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 204 }, '')
        return this.handler.setDocument(
          this.project_id,
          this.doc_id,
          this.user_id,
          this.lines,
          this.source,
          this.callback
        )
      })

      it('should set the document in the document updater', function() {
        return this.request
          .calledWith({
            url: `${this.settings.apis.documentupdater.url}/project/${
              this.project_id
            }/doc/${this.doc_id}`,
            json: {
              lines: this.lines,
              source: this.source,
              user_id: this.user_id
            },
            method: 'POST'
          })
          .should.equal(true)
      })

      it('should call the callback with no error', function() {
        return this.callback.calledWith(null).should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.callsArgWith(
          1,
          (this.error = new Error('something went wrong')),
          null,
          null
        )
        return this.handler.setDocument(
          this.project_id,
          this.doc_id,
          this.user_id,
          this.lines,
          this.source,
          this.callback
        )
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns a failure error code', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 500 }, '')
        return this.handler.setDocument(
          this.project_id,
          this.doc_id,
          this.user_id,
          this.lines,
          this.source,
          this.callback
        )
      })

      it('should return the callback with an error', function() {
        return this.callback
          .calledWith(
            new Error('doc updater returned failure status code: 500')
          )
          .should.equal(true)
      })
    })
  })

  describe('getDocument', function() {
    describe('successfully', function() {
      beforeEach(function() {
        this.body = {
          lines: this.lines,
          version: this.version,
          ops: (this.ops = ['mock-op-1', 'mock-op-2']),
          ranges: (this.ranges = { mock: 'ranges' })
        }
        this.fromVersion = 2
        this.request.callsArgWith(1, null, { statusCode: 200 }, this.body)
        return this.handler.getDocument(
          this.project_id,
          this.doc_id,
          this.fromVersion,
          this.callback
        )
      })

      it('should get the document from the document updater', function() {
        return this.request
          .calledWith({
            url: `${this.settings.apis.documentupdater.url}/project/${
              this.project_id
            }/doc/${this.doc_id}?fromVersion=${this.fromVersion}`,
            method: 'GET',
            json: true
          })
          .should.equal(true)
      })

      it('should call the callback with the lines and version', function() {
        return this.callback
          .calledWith(null, this.lines, this.version, this.ranges, this.ops)
          .should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.callsArgWith(
          1,
          (this.error = new Error('something went wrong')),
          null,
          null
        )
        return this.handler.getDocument(
          this.project_id,
          this.doc_id,
          this.fromVersion,
          this.callback
        )
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns a failure error code', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 500 }, '')
        return this.handler.getDocument(
          this.project_id,
          this.doc_id,
          this.fromVersion,
          this.callback
        )
      })

      it('should return the callback with an error', function() {
        return this.callback
          .calledWith(
            new Error('doc updater returned failure status code: 500')
          )
          .should.equal(true)
      })
    })
  })

  describe('getProjectDocsIfMatch', function() {
    beforeEach(function() {
      return (this.project_state_hash = '1234567890abcdef')
    })

    describe('successfully', function() {
      beforeEach(function() {
        this.doc0 = {
          _id: this.doc_id,
          lines: this.lines,
          v: this.version
        }
        this.docs = [this.doc0, this.doc0, this.doc0]
        this.body = JSON.stringify(this.docs)
        this.request.post = sinon
          .stub()
          .callsArgWith(1, null, { statusCode: 200 }, this.body)
        return this.handler.getProjectDocsIfMatch(
          this.project_id,
          this.project_state_hash,
          this.callback
        )
      })

      it('should get the documents from the document updater', function() {
        const url = `${this.settings.apis.documentupdater.url}/project/${
          this.project_id
        }/get_and_flush_if_old?state=${this.project_state_hash}`
        return this.request.post.calledWith(url).should.equal(true)
      })

      it('should call the callback with the documents', function() {
        return this.callback
          .calledWithExactly(null, this.docs)
          .should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.post = sinon
          .stub()
          .callsArgWith(
            1,
            (this.error = new Error('something went wrong')),
            null,
            null
          )
        return this.handler.getProjectDocsIfMatch(
          this.project_id,
          this.project_state_hash,
          this.callback
        )
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns a conflict error code', function() {
      beforeEach(function() {
        this.request.post = sinon
          .stub()
          .callsArgWith(1, null, { statusCode: 409 }, 'Conflict')
        return this.handler.getProjectDocsIfMatch(
          this.project_id,
          this.project_state_hash,
          this.callback
        )
      })

      it('should return the callback with no documents', function() {
        return this.callback.alwaysCalledWithExactly().should.equal(true)
      })
    })
  })

  describe('clearProjectState', function() {
    describe('successfully', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 200 })
        return this.handler.clearProjectState(this.project_id, this.callback)
      })

      it('should clear the project state from the document updater', function() {
        return this.request
          .calledWithMatch({
            url: `${this.settings.apis.documentupdater.url}/project/${
              this.project_id
            }/clearState`,
            method: 'POST'
          })
          .should.equal(true)
      })

      it('should call the callback', function() {
        return this.callback.calledWith(null).should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.callsArgWith(
          1,
          (this.error = new Error('something went wrong')),
          null,
          null
        )
        return this.handler.clearProjectState(this.project_id, this.callback)
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns an error code', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 500 }, null)
        return this.handler.clearProjectState(this.project_id, this.callback)
      })

      it('should return the callback with no documents', function() {
        return this.callback
          .calledWith(
            new Error('doc updater returned failure status code: 500')
          )
          .should.equal(true)
      })
    })
  })

  describe('acceptChanges', function() {
    beforeEach(function() {
      return (this.change_id = 'mock-change-id-1')
    })

    describe('successfully', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 200 }, this.body)
        return this.handler.acceptChanges(
          this.project_id,
          this.doc_id,
          [this.change_id],
          this.callback
        )
      })

      it('should accept the change in the document updater', function() {
        return this.request
          .calledWith({
            url: `${this.settings.apis.documentupdater.url}/project/${
              this.project_id
            }/doc/${this.doc_id}/change/accept`,
            json: {
              change_ids: [this.change_id]
            },
            method: 'POST'
          })
          .should.equal(true)
      })

      it('should call the callback', function() {
        return this.callback.calledWith(null).should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.callsArgWith(
          1,
          (this.error = new Error('something went wrong')),
          null,
          null
        )
        return this.handler.acceptChanges(
          this.project_id,
          this.doc_id,
          [this.change_id],
          this.callback
        )
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns a failure error code', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 500 }, '')
        return this.handler.acceptChanges(
          this.project_id,
          this.doc_id,
          [this.change_id],
          this.callback
        )
      })

      it('should return the callback with an error', function() {
        return this.callback
          .calledWith(
            new Error('doc updater returned failure status code: 500')
          )
          .should.equal(true)
      })
    })
  })

  describe('deleteThread', function() {
    beforeEach(function() {
      return (this.thread_id = 'mock-thread-id-1')
    })

    describe('successfully', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 200 }, this.body)
        return this.handler.deleteThread(
          this.project_id,
          this.doc_id,
          this.thread_id,
          this.callback
        )
      })

      it('should delete the thread in the document updater', function() {
        return this.request
          .calledWithMatch({
            url: `${this.settings.apis.documentupdater.url}/project/${
              this.project_id
            }/doc/${this.doc_id}/comment/${this.thread_id}`,
            method: 'DELETE'
          })
          .should.equal(true)
      })

      it('should call the callback', function() {
        return this.callback.calledWith(null).should.equal(true)
      })
    })

    describe('when the document updater API returns an error', function() {
      beforeEach(function() {
        this.request.callsArgWith(
          1,
          (this.error = new Error('something went wrong')),
          null,
          null
        )
        return this.handler.deleteThread(
          this.project_id,
          this.doc_id,
          this.thread_id,
          this.callback
        )
      })

      it('should return an error to the callback', function() {
        return this.callback.calledWith(this.error).should.equal(true)
      })
    })

    describe('when the document updater returns a failure error code', function() {
      beforeEach(function() {
        this.request.callsArgWith(1, null, { statusCode: 500 }, '')
        return this.handler.deleteThread(
          this.project_id,
          this.doc_id,
          this.thread_id,
          this.callback
        )
      })

      it('should return the callback with an error', function() {
        return this.callback
          .calledWith(
            new Error('doc updater returned failure status code: 500')
          )
          .should.equal(true)
      })
    })
  })

  describe('updateProjectStructure ', function() {
    beforeEach(function() {
      this.user_id = 1234
      return (this.version = 999)
    })

    describe('with project history disabled', function() {
      beforeEach(function() {
        this.settings.apis.project_history.sendProjectStructureOps = false
        return this.handler.updateProjectStructure(
          this.project_id,
          this.projectHistoryId,
          this.user_id,
          {},
          this.callback
        )
      })

      it('does not make a web request', function() {
        return this.request.called.should.equal(false)
      })

      it('calls the callback', function() {
        return this.callback.called.should.equal(true)
      })
    })

    describe('with project history enabled', function() {
      beforeEach(function() {
        this.settings.apis.project_history.sendProjectStructureOps = true
        this.url = `${this.settings.apis.documentupdater.url}/project/${
          this.project_id
        }`
        return this.request.callsArgWith(1, null, { statusCode: 204 }, '')
      })

      describe('when an entity has changed name', () =>
        it('should send the structure update to the document updater', function(done) {
          this.docIdA = new ObjectId()
          this.docIdB = new ObjectId()
          this.changes = {
            oldDocs: [
              { path: '/old_a', doc: { _id: this.docIdA } },
              { path: '/old_b', doc: { _id: this.docIdB } }
            ],
            // create new instances of the same ObjectIds so that == doesn't pass
            newDocs: [
              {
                path: '/old_a',
                doc: { _id: new ObjectId(this.docIdA.toString()) }
              },
              {
                path: '/new_b',
                doc: { _id: new ObjectId(this.docIdB.toString()) }
              }
            ],
            newProject: { version: this.version }
          }

          const docUpdates = [
            {
              id: this.docIdB.toString(),
              pathname: '/old_b',
              newPathname: '/new_b'
            }
          ]

          return this.handler.updateProjectStructure(
            this.project_id,
            this.projectHistoryId,
            this.user_id,
            this.changes,
            () => {
              this.request
                .calledWith({
                  url: this.url,
                  method: 'POST',
                  json: {
                    docUpdates,
                    fileUpdates: [],
                    userId: this.user_id,
                    version: this.version,
                    projectHistoryId: this.projectHistoryId
                  }
                })
                .should.equal(true)
              return done()
            }
          )
        }))

      describe('when a doc has been added', () =>
        it('should send the structure update to the document updater', function(done) {
          this.docId = new ObjectId()
          this.changes = {
            newDocs: [
              { path: '/foo', docLines: 'a\nb', doc: { _id: this.docId } }
            ],
            newProject: { version: this.version }
          }

          const docUpdates = [
            {
              id: this.docId.toString(),
              pathname: '/foo',
              docLines: 'a\nb',
              url: undefined,
              hash: undefined
            }
          ]

          return this.handler.updateProjectStructure(
            this.project_id,
            this.projectHistoryId,
            this.user_id,
            this.changes,
            () => {
              this.request
                .calledWith({
                  url: this.url,
                  method: 'POST',
                  json: {
                    docUpdates,
                    fileUpdates: [],
                    userId: this.user_id,
                    version: this.version,
                    projectHistoryId: this.projectHistoryId
                  }
                })
                .should.equal(true)
              return done()
            }
          )
        }))

      describe('when a file has been added', () =>
        it('should send the structure update to the document updater', function(done) {
          this.fileId = new ObjectId()
          this.changes = {
            newFiles: [
              {
                path: '/bar',
                url: 'filestore.example.com/file',
                file: { _id: this.fileId, hash: '12345' }
              }
            ],
            newProject: { version: this.version }
          }

          const fileUpdates = [
            {
              id: this.fileId.toString(),
              pathname: '/bar',
              url: 'filestore.example.com/file',
              docLines: undefined,
              hash: '12345'
            }
          ]

          return this.handler.updateProjectStructure(
            this.project_id,
            this.projectHistoryId,
            this.user_id,
            this.changes,
            () => {
              this.request
                .calledWith({
                  url: this.url,
                  method: 'POST',
                  json: {
                    docUpdates: [],
                    fileUpdates,
                    userId: this.user_id,
                    version: this.version,
                    projectHistoryId: this.projectHistoryId
                  }
                })
                .should.equal(true)
              return done()
            }
          )
        }))

      describe('when an entity has been deleted', () =>
        it('should end the structure update to the document updater', function(done) {
          this.docId = new ObjectId()
          this.changes = {
            oldDocs: [
              { path: '/foo', docLines: 'a\nb', doc: { _id: this.docId } }
            ],
            newProject: { version: this.version }
          }

          const docUpdates = [
            {
              id: this.docId.toString(),
              pathname: '/foo',
              newPathname: ''
            }
          ]

          return this.handler.updateProjectStructure(
            this.project_id,
            this.projectHistoryId,
            this.user_id,
            this.changes,
            () => {
              this.request
                .calledWith({
                  url: this.url,
                  method: 'POST',
                  json: {
                    docUpdates,
                    fileUpdates: [],
                    userId: this.user_id,
                    version: this.version,
                    projectHistoryId: this.projectHistoryId
                  }
                })
                .should.equal(true)
              return done()
            }
          )
        }))

      describe('when the project version is missing', () =>
        it('should call the callback with an error', function() {
          this.docId = new ObjectId()
          this.changes = {
            oldDocs: [
              { path: '/foo', docLines: 'a\nb', doc: { _id: this.docId } }
            ]
          }

          const docUpdates = [
            {
              id: this.docId.toString(),
              pathname: '/foo',
              newPathname: ''
            }
          ]

          this.handler.updateProjectStructure(
            this.project_id,
            this.projectHistoryId,
            this.user_id,
            this.changes,
            this.callback
          )

          this.callback.calledWith(new Error()).should.equal(true)
          const firstCallArgs = this.callback.args[0]
          return firstCallArgs[0].message.should.equal(
            'did not receive project version in changes'
          )
        }))
    })
  })
})