const { expect } = require('chai')
const async = require('async')
const User = require('./helpers/User')
const request = require('./helpers/request')
const settings = require('settings-sharelatex')
const { db, ObjectId } = require('../../../app/src/infrastructure/mongodb')
const MockV1ApiClass = require('./mocks/MockV1Api')
const expectErrorResponse = require('./helpers/expectErrorResponse')

let MockV1Api

before(function () {
  MockV1Api = MockV1ApiClass.instance()
})

const tryEditorAccess = (user, projectId, test, callback) =>
  async.series(
    [
      cb =>
        user.request.get(`/project/${projectId}`, (error, response, body) => {
          if (error != null) {
            return cb(error)
          }
          test(response, body)
          cb()
        }),
      cb =>
        user.request.get(
          `/project/${projectId}/download/zip`,
          (error, response, body) => {
            if (error != null) {
              return cb(error)
            }
            test(response, body)
            cb()
          }
        ),
    ],
    callback
  )

const tryReadOnlyTokenAccess = (
  user,
  token,
  testPageLoad,
  testFormPost,
  callback
) => {
  _doTryTokenAccess(
    `/read/${token}`,
    user,
    token,
    testPageLoad,
    testFormPost,
    callback
  )
}

const tryReadAndWriteTokenAccess = (
  user,
  token,
  testPageLoad,
  testFormPost,
  callback
) => {
  _doTryTokenAccess(
    `/${token}`,
    user,
    token,
    testPageLoad,
    testFormPost,
    callback
  )
}

const _doTryTokenAccess = (
  url,
  user,
  token,
  testPageLoad,
  testFormPost,
  callback
) => {
  user.request.get(url, (err, response, body) => {
    if (err) {
      return callback(err)
    }
    testPageLoad(response, body)
    if (!testFormPost) {
      return callback()
    }
    user.request.post(
      `${url}/grant`,
      { json: { token } },
      (err, response, body) => {
        if (err) {
          return callback(err)
        }
        testFormPost(response, body)
        callback()
      }
    )
  })
}

const tryContentAccess = (user, projcetId, test, callback) => {
  // The real-time service calls this end point to determine the user's
  // permissions.
  let userId
  if (user.id != null) {
    userId = user.id
  } else {
    userId = 'anonymous-user'
  }
  request.post(
    {
      url: `/project/${projcetId}/join`,
      qs: { user_id: userId },
      auth: {
        user: settings.apis.web.user,
        pass: settings.apis.web.pass,
        sendImmediately: true,
      },
      json: true,
      jar: false,
    },
    (error, response, body) => {
      if (error != null) {
        return callback(error)
      }
      test(response, body)
      callback()
    }
  )
}

const tryAnonContentAccess = (user, projectId, token, test, callback) => {
  // The real-time service calls this end point to determine the user's
  // permissions.
  let userId
  if (user.id != null) {
    userId = user.id
  } else {
    userId = 'anonymous-user'
  }
  request.post(
    {
      url: `/project/${projectId}/join`,
      qs: { user_id: userId },
      auth: {
        user: settings.apis.web.user,
        pass: settings.apis.web.pass,
        sendImmediately: true,
      },
      headers: {
        'x-sl-anonymous-access-token': token,
      },
      json: true,
      jar: false,
    },
    (error, response, body) => {
      if (error != null) {
        return callback(error)
      }
      test(response, body)
      callback()
    }
  )
}

describe('TokenAccess', function () {
  beforeEach(function (done) {
    this.timeout(90000)
    this.owner = new User()
    this.other1 = new User()
    this.other2 = new User()
    this.anon = new User()
    this.siteAdmin = new User({ email: 'admin@example.com' })
    async.parallel(
      [
        cb =>
          this.siteAdmin.login(err => {
            if (err) {
              return cb(err)
            }
            this.siteAdmin.ensureAdmin(cb)
          }),
        cb => this.owner.login(cb),
        cb => this.other1.login(cb),
        cb => this.other2.login(cb),
        cb => this.anon.getCsrfToken(cb),
      ],
      done
    )
  })

  describe('no token-access', function () {
    beforeEach(function (done) {
      this.owner.createProject(
        `token-ro-test${Math.random()}`,
        (err, projectId) => {
          if (err != null) {
            return done(err)
          }
          this.projectId = projectId
          // Note, never made token-based,
          // thus no tokens
          done()
        }
      )
    })

    it('should deny access ', function (done) {
      async.series(
        [
          cb => {
            tryEditorAccess(
              this.other1,
              this.projectId,
              expectErrorResponse.restricted.html,
              cb
            )
          },
          cb => {
            tryContentAccess(
              this.other1,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(403)
                expect(body).to.equal('Forbidden')
              },
              cb
            )
          },
        ],
        done
      )
    })
  })

  describe('read-only token', function () {
    beforeEach(function (done) {
      this.owner.createProject(
        `token-ro-test${Math.random()}`,
        (err, projectId) => {
          if (err != null) {
            return done(err)
          }
          this.projectId = projectId
          this.owner.makeTokenBased(this.projectId, err => {
            if (err != null) {
              return done(err)
            }
            this.owner.getProject(this.projectId, (err, project) => {
              if (err != null) {
                return done(err)
              }
              this.tokens = project.tokens
              done()
            })
          })
        }
      )
    })

    it('allow the user read-only access to the project', function (done) {
      async.series(
        [
          cb => {
            // deny access before token is used
            tryEditorAccess(
              this.other1,
              this.projectId,
              expectErrorResponse.restricted.html,
              cb
            )
          },
          cb => {
            // use token
            tryReadOnlyTokenAccess(
              this.other1,
              this.tokens.readOnly,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              (response, body) => {
                expect(response.statusCode).to.equal(200)
                expect(body.redirect).to.equal(`/project/${this.projectId}`)
                expect(body.tokenAccessGranted).to.equal('readOnly')
              },
              cb
            )
          },
          cb => {
            // allow content access read-only
            tryContentAccess(
              this.other1,
              this.projectId,
              (response, body) => {
                expect(body.privilegeLevel).to.equal('readOnly')
                expect(body.isRestrictedUser).to.equal(true)
                expect(body.project.owner).to.have.keys('_id')
                expect(body.project.owner).to.not.have.any.keys(
                  'email',
                  'first_name',
                  'last_name'
                )
              },
              cb
            )
          },
          cb => {
            tryEditorAccess(
              this.other1,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              cb
            )
          },
        ],
        done
      )
    })

    it('should redirect the admin to the project (with rw access)', function (done) {
      async.series(
        [
          cb => {
            // use token
            tryReadOnlyTokenAccess(
              this.siteAdmin,
              this.tokens.readOnly,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              (response, body) => {
                expect(response.statusCode).to.equal(200)
                expect(body.redirect).to.equal(`/project/${this.projectId}`)
              },
              cb
            )
          },
          cb => {
            // allow content access read-and-write
            tryContentAccess(
              this.siteAdmin,
              this.projectId,
              (response, body) => {
                expect(body.privilegeLevel).to.equal('owner')
                expect(body.isRestrictedUser).to.equal(false)
              },
              cb
            )
          },
        ],
        done
      )
    })

    describe('made private again', function () {
      beforeEach(function (done) {
        this.owner.makePrivate(this.projectId, () => setTimeout(done, 1000))
      })

      it('should not allow the user to access the project', function (done) {
        async.series(
          [
            // no access before token is used
            cb =>
              tryEditorAccess(
                this.other1,
                this.projectId,
                expectErrorResponse.restricted.html,
                cb
              ),
            // token goes nowhere
            cb =>
              tryReadOnlyTokenAccess(
                this.other1,
                this.tokens.readOnly,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                (response, body) => {
                  expect(response.statusCode).to.equal(404)
                },
                cb
              ),
            // still no access
            cb =>
              tryEditorAccess(
                this.other1,
                this.projectId,
                expectErrorResponse.restricted.html,
                cb
              ),
            cb =>
              tryContentAccess(
                this.other1,
                this.projectId,
                (response, body) => {
                  expect(response.statusCode).to.equal(403)
                  expect(body).to.equal('Forbidden')
                },
                cb
              ),
          ],
          done
        )
      })
    })
  })

  describe('anonymous read-only token', function () {
    beforeEach(function (done) {
      this.owner.createProject(
        `token-anon-ro-test${Math.random()}`,
        (err, projectId) => {
          if (err != null) {
            return done(err)
          }
          this.projectId = projectId
          this.owner.makeTokenBased(this.projectId, err => {
            if (err != null) {
              return done(err)
            }
            this.owner.getProject(this.projectId, (err, project) => {
              if (err != null) {
                return done(err)
              }
              this.tokens = project.tokens
              done()
            })
          })
        }
      )
    })

    it('should allow the user to access project via read-only token url', function (done) {
      async.series(
        [
          cb =>
            tryEditorAccess(
              this.anon,
              this.projectId,
              expectErrorResponse.restricted.html,
              cb
            ),
          cb =>
            tryReadOnlyTokenAccess(
              this.anon,
              this.tokens.readOnly,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              (response, body) => {
                expect(response.statusCode).to.equal(200)
                expect(body.redirect).to.equal(`/project/${this.projectId}`)
                expect(body.grantAnonymousAccess).to.equal('readOnly')
              },
              cb
            ),
          cb =>
            tryEditorAccess(
              this.anon,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              cb
            ),
          cb =>
            tryAnonContentAccess(
              this.anon,
              this.projectId,
              this.tokens.readOnly,
              (response, body) => {
                expect(body.privilegeLevel).to.equal('readOnly')
                expect(body.isRestrictedUser).to.equal(true)
                expect(body.project.owner).to.have.keys('_id')
                expect(body.project.owner).to.not.have.any.keys(
                  'email',
                  'first_name',
                  'last_name'
                )
              },
              cb
            ),
        ],
        done
      )
    })

    describe('made private again', function () {
      beforeEach(function (done) {
        this.owner.makePrivate(this.projectId, () => setTimeout(done, 1000))
      })

      it('should deny access to project', function (done) {
        async.series(
          [
            cb =>
              tryEditorAccess(
                this.anon,
                this.projectId,
                expectErrorResponse.restricted.html,
                cb
              ),
            // should not allow the user to access read-only token
            cb =>
              tryReadOnlyTokenAccess(
                this.anon,
                this.tokens.readOnly,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                (response, body) => {
                  expect(response.statusCode).to.equal(404)
                },
                cb
              ),
            // still no access
            cb =>
              tryEditorAccess(
                this.anon,
                this.projectId,
                expectErrorResponse.restricted.html,
                cb
              ),
            // should not allow the user to join the project
            cb =>
              tryAnonContentAccess(
                this.anon,
                this.projectId,
                this.tokens.readOnly,
                (response, body) => {
                  expect(response.statusCode).to.equal(403)
                  expect(body).to.equal('Forbidden')
                },
                cb
              ),
          ],
          done
        )
      })
    })
  })

  describe('read-and-write token', function () {
    beforeEach(function (done) {
      this.owner.createProject(
        `token-rw-test${Math.random()}`,
        (err, projectId) => {
          if (err != null) {
            return done(err)
          }
          this.projectId = projectId
          this.owner.makeTokenBased(this.projectId, err => {
            if (err != null) {
              return done(err)
            }
            this.owner.getProject(this.projectId, (err, project) => {
              if (err != null) {
                return done(err)
              }
              this.tokens = project.tokens
              done()
            })
          })
        }
      )
    })

    it('should allow the user to access project via read-and-write token url', function (done) {
      async.series(
        [
          // deny access before the token is used
          cb =>
            tryEditorAccess(
              this.other1,
              this.projectId,
              expectErrorResponse.restricted.html,
              cb
            ),
          cb =>
            tryReadAndWriteTokenAccess(
              this.other1,
              this.tokens.readAndWrite,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              (response, body) => {
                expect(response.statusCode).to.equal(200)
                expect(body.redirect).to.equal(`/project/${this.projectId}`)
                expect(body.tokenAccessGranted).to.equal('readAndWrite')
              },
              cb
            ),
          cb =>
            tryEditorAccess(
              this.other1,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              cb
            ),
          cb =>
            tryContentAccess(
              this.other1,
              this.projectId,
              (response, body) => {
                expect(body.privilegeLevel).to.equal('readAndWrite')
                expect(body.isRestrictedUser).to.equal(false)
                expect(body.project.owner).to.have.all.keys(
                  '_id',
                  'email',
                  'first_name',
                  'last_name',
                  'privileges',
                  'signUpDate'
                )
              },
              cb
            ),
        ],
        done
      )
    })

    describe('upgrading from a read-only token', function () {
      beforeEach(function (done) {
        this.owner.createProject(
          `token-rw-upgrade-test${Math.random()}`,
          (err, projectId) => {
            if (err != null) {
              return done(err)
            }
            this.projectId = projectId
            this.owner.makeTokenBased(this.projectId, err => {
              if (err != null) {
                return done(err)
              }
              this.owner.getProject(this.projectId, (err, project) => {
                if (err != null) {
                  return done(err)
                }
                this.tokens = project.tokens
                done()
              })
            })
          }
        )
      })

      it('should allow user to access project via read-only, then upgrade to read-write', function (done) {
        async.series(
          [
            // deny access before the token is used
            cb =>
              tryEditorAccess(
                this.other1,
                this.projectId,
                expectErrorResponse.restricted.html,
                cb
              ),
            cb => {
              // use read-only token
              tryReadOnlyTokenAccess(
                this.other1,
                this.tokens.readOnly,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                  expect(body.redirect).to.equal(`/project/${this.projectId}`)
                  expect(body.tokenAccessGranted).to.equal('readOnly')
                },
                cb
              )
            },
            cb => {
              tryEditorAccess(
                this.other1,
                this.projectId,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                cb
              )
            },
            cb => {
              // allow content access read-only
              tryContentAccess(
                this.other1,
                this.projectId,
                (response, body) => {
                  expect(body.privilegeLevel).to.equal('readOnly')
                  expect(body.isRestrictedUser).to.equal(true)
                  expect(body.project.owner).to.have.keys('_id')
                  expect(body.project.owner).to.not.have.any.keys(
                    'email',
                    'first_name',
                    'last_name'
                  )
                },
                cb
              )
            },
            //
            // Then switch to read-write token
            //
            cb =>
              tryReadAndWriteTokenAccess(
                this.other1,
                this.tokens.readAndWrite,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                  expect(body.redirect).to.equal(`/project/${this.projectId}`)
                  expect(body.tokenAccessGranted).to.equal('readAndWrite')
                },
                cb
              ),
            cb =>
              tryEditorAccess(
                this.other1,
                this.projectId,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                cb
              ),
            cb =>
              tryContentAccess(
                this.other1,
                this.projectId,
                (response, body) => {
                  expect(body.privilegeLevel).to.equal('readAndWrite')
                  expect(body.isRestrictedUser).to.equal(false)
                  expect(body.project.owner).to.have.all.keys(
                    '_id',
                    'email',
                    'first_name',
                    'last_name',
                    'privileges',
                    'signUpDate'
                  )
                },
                cb
              ),
          ],
          done
        )
      })
    })

    describe('made private again', function () {
      beforeEach(function (done) {
        this.owner.makePrivate(this.projectId, () => setTimeout(done, 1000))
      })

      it('should deny access to project', function (done) {
        async.series(
          [
            cb => {
              tryEditorAccess(
                this.other1,
                this.projectId,
                (response, body) => {},
                cb
              )
            },
            cb => {
              tryReadAndWriteTokenAccess(
                this.other1,
                this.tokens.readAndWrite,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                (response, body) => {
                  expect(response.statusCode).to.equal(404)
                },
                cb
              )
            },
            cb => {
              tryEditorAccess(
                this.other1,
                this.projectId,
                expectErrorResponse.restricted.html,
                cb
              )
            },
            cb => {
              tryContentAccess(
                this.other1,
                this.projectId,
                (response, body) => {
                  expect(response.statusCode).to.equal(403)
                  expect(body).to.equal('Forbidden')
                },
                cb
              )
            },
          ],
          done
        )
      })
    })
  })

  if (!settings.allowAnonymousReadAndWriteSharing) {
    describe('anonymous read-and-write token, disabled', function () {
      beforeEach(function (done) {
        this.owner.createProject(
          `token-anon-rw-test${Math.random()}`,
          (err, projectId) => {
            if (err != null) {
              return done(err)
            }
            this.projectId = projectId
            this.owner.makeTokenBased(this.projectId, err => {
              if (err != null) {
                return done(err)
              }
              this.owner.getProject(this.projectId, (err, project) => {
                if (err != null) {
                  return done(err)
                }
                this.tokens = project.tokens
                done()
              })
            })
          }
        )
      })

      it('should not allow the user to access read-and-write token', function (done) {
        async.series(
          [
            cb =>
              tryEditorAccess(
                this.anon,
                this.projectId,
                expectErrorResponse.restricted.html,
                cb
              ),
            cb =>
              tryReadAndWriteTokenAccess(
                this.anon,
                this.tokens.readAndWrite,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                  expect(body).to.deep.equal({
                    redirect: '/restricted',
                    anonWriteAccessDenied: true,
                  })
                },
                cb
              ),
            cb =>
              tryAnonContentAccess(
                this.anon,
                this.projectId,
                this.tokens.readAndWrite,
                (response, body) => {
                  expect(response.statusCode).to.equal(403)
                  expect(body).to.equal('Forbidden')
                },
                cb
              ),
            cb =>
              this.anon.login((err, response, body) => {
                expect(err).to.not.exist
                expect(response.statusCode).to.equal(200)
                expect(body.redir).to.equal(`/${this.tokens.readAndWrite}`)
                cb()
              }),
          ],
          done
        )
      })
    })
  } else {
    describe('anonymous read-and-write token, enabled', function () {
      beforeEach(function (done) {
        this.owner.createProject(
          `token-anon-rw-test${Math.random()}`,
          (err, projectId) => {
            if (err != null) {
              return done(err)
            }
            this.projectId = projectId
            this.owner.makeTokenBased(this.projectId, err => {
              if (err != null) {
                return done(err)
              }
              this.owner.getProject(this.projectId, (err, project) => {
                if (err != null) {
                  return done(err)
                }
                this.tokens = project.tokens
                done()
              })
            })
          }
        )
      })

      it('should allow the user to access project via read-and-write token url', function (done) {
        async.series(
          [
            cb =>
              tryEditorAccess(
                this.anon,
                this.projectId,
                expectErrorResponse.restricted.html,
                cb
              ),
            cb =>
              tryReadAndWriteTokenAccess(
                this.anon,
                this.tokens.readAndWrite,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                  expect(body.redirect).to.equal(`/project/${this.projectId}`)
                  expect(body.grantAnonymousAccess).to.equal('readAndWrite')
                },
                cb
              ),
            cb =>
              tryEditorAccess(
                this.anon,
                this.projectId,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                cb
              ),
            cb =>
              tryAnonContentAccess(
                this.anon,
                this.projectId,
                this.tokens.readAndWrite,
                (response, body) => {
                  expect(body.privilegeLevel).to.equal('readAndWrite')
                },
                cb
              ),
          ],
          done
        )
      })

      describe('made private again', function () {
        beforeEach(function (done) {
          this.owner.makePrivate(this.projectId, () => setTimeout(done, 1000))
        })

        it('should not allow the user to access read-and-write token', function (done) {
          async.series(
            [
              cb =>
                tryEditorAccess(
                  this.anon,
                  this.projectId,
                  expectErrorResponse.restricted.html,
                  cb
                ),
              cb =>
                tryReadAndWriteTokenAccess(
                  this.anon,
                  this.tokens.readAndWrite,
                  (response, body) => {
                    expect(response.statusCode).to.equal(200)
                  },
                  (response, body) => {
                    expect(response.statusCode).to.equal(404)
                  },
                  cb
                ),
              cb =>
                tryEditorAccess(
                  this.anon,
                  this.projectId,
                  expectErrorResponse.restricted.html,
                  cb
                ),
              cb =>
                tryAnonContentAccess(
                  this.anon,
                  this.projectId,
                  this.tokens.readAndWrite,
                  (response, body) => {
                    expect(response.statusCode).to.equal(403)
                    expect(body).to.equal('Forbidden')
                  },
                  cb
                ),
            ],
            done
          )
        })
      })
    })
  }

  describe('private overleaf project', function () {
    beforeEach(function (done) {
      this.owner.createProject('overleaf-import', (err, projectId) => {
        expect(err).not.to.exist
        this.projectId = projectId
        this.owner.makeTokenBased(this.projectId, err => {
          expect(err).not.to.exist
          this.owner.getProject(this.projectId, (err, project) => {
            expect(err).not.to.exist
            this.tokens = project.tokens
            this.owner.makePrivate(this.projectId, () => {
              db.projects.updateOne(
                { _id: project._id },
                {
                  $set: {
                    overleaf: { id: 1234 },
                  },
                },
                err => {
                  expect(err).not.to.exist
                  done()
                }
              )
            })
          })
        })
      })
    })

    it('should only allow the owner access to the project', function (done) {
      async.series(
        [
          // should redirect to canonical path, when owner uses read-write token
          cb =>
            tryReadAndWriteTokenAccess(
              this.owner,
              this.tokens.readAndWrite,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              (response, body) => {
                expect(response.statusCode).to.equal(200)
                expect(response.body.redirect).to.equal(
                  `/project/${this.projectId}`
                )
                expect(response.body.higherAccess).to.equal(true)
              },
              cb
            ),
          cb =>
            tryEditorAccess(
              this.owner,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              cb
            ),
          cb =>
            tryContentAccess(
              this.owner,
              this.projectId,
              (response, body) => {
                expect(body.privilegeLevel).to.equal('owner')
              },
              cb
            ),
          // non-owner should be denied access
          cb =>
            tryContentAccess(
              this.other2,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(403)
                expect(body).to.equal('Forbidden')
              },
              cb
            ),
        ],
        done
      )
    })
  })

  describe('private project, with higher access', function () {
    beforeEach(function (done) {
      this.owner.createProject(
        `higher-access-test-${Math.random()}`,
        (err, projectId) => {
          expect(err).not.to.exist
          this.projectId = projectId
          this.owner.addUserToProject(
            this.projectId,
            this.other1,
            'readAndWrite',
            err => {
              expect(err).not.to.exist
              this.owner.makeTokenBased(this.projectId, err => {
                expect(err).not.to.exist
                this.owner.getProject(this.projectId, (err, project) => {
                  expect(err).not.to.exist
                  this.tokens = project.tokens
                  this.owner.makePrivate(this.projectId, () => {
                    setTimeout(done, 1000)
                  })
                })
              })
            }
          )
        }
      )
    })

    it('should allow the user access to the project', function (done) {
      async.series(
        [
          // should redirect to canonical path, when user uses read-write token
          cb =>
            tryReadAndWriteTokenAccess(
              this.other1,
              this.tokens.readAndWrite,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              (response, body) => {
                expect(response.statusCode).to.equal(200)
                expect(response.body.redirect).to.equal(
                  `/project/${this.projectId}`
                )
                expect(response.body.higherAccess).to.equal(true)
              },
              cb
            ),
          // should redirect to canonical path, when user uses read-only token
          cb =>
            tryReadOnlyTokenAccess(
              this.other1,
              this.tokens.readOnly,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              (response, body) => {
                expect(response.statusCode).to.equal(200)
                expect(response.body.redirect).to.equal(
                  `/project/${this.projectId}`
                )
                expect(response.body.higherAccess).to.equal(true)
              },
              cb
            ),
          // should allow the user access to the project
          cb =>
            tryEditorAccess(
              this.other1,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              cb
            ),
          // should allow user to join the project
          cb =>
            tryContentAccess(
              this.other1,
              this.projectId,
              (response, body) => {
                expect(body.privilegeLevel).to.equal('readAndWrite')
              },
              cb
            ),
          // should not allow a different user to join the project
          cb =>
            tryEditorAccess(
              this.other2,
              this.projectId,
              expectErrorResponse.restricted.html,
              cb
            ),
          cb =>
            tryContentAccess(
              this.other2,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(403)
                expect(body).to.equal('Forbidden')
              },
              cb
            ),
        ],
        done
      )
    })
  })

  describe('unimported v1 project', function () {
    beforeEach(function () {
      settings.overleaf = { host: 'http://localhost:5000' }
    })

    afterEach(function () {
      delete settings.overleaf
    })

    it('should show error page for read and write token', function (done) {
      const unimportedV1Token = '123abcdefabcdef'
      tryReadAndWriteTokenAccess(
        this.owner,
        unimportedV1Token,
        (response, body) => {
          expect(response.statusCode).to.equal(200)
        },
        (response, body) => {
          expect(response.statusCode).to.equal(200)
          expect(body).to.deep.equal({ v1Import: { status: 'cannotImport' } })
        },
        done
      )
    })

    it('should show error page for read only token to v1', function (done) {
      const unimportedV1Token = 'aaaaaabbbbbb'
      tryReadOnlyTokenAccess(
        this.owner,
        unimportedV1Token,
        (response, body) => {
          expect(response.statusCode).to.equal(200)
        },
        (response, body) => {
          expect(response.statusCode).to.equal(200)
          expect(body).to.deep.equal({ v1Import: { status: 'cannotImport' } })
        },
        done
      )
    })
  })

  describe('importing v1 project', function () {
    beforeEach(function (done) {
      settings.projectImportingCheckMaxCreateDelta = 3600
      settings.overleaf = { host: 'http://localhost:5000' }
      this.owner.createProject(
        `token-rw-test${Math.random()}`,
        (err, projectId) => {
          if (err != null) {
            return done(err)
          }
          this.projectId = projectId
          db.users.updateOne(
            { _id: ObjectId(this.owner._id.toString()) },
            { $set: { 'overleaf.id': 321321 } },
            err => {
              if (err) {
                return done(err)
              }
              this.owner.makeTokenBased(this.projectId, err => {
                if (err != null) {
                  return done(err)
                }
                db.projects.updateOne(
                  { _id: ObjectId(projectId) },
                  { $set: { overleaf: { id: 1234 } } },
                  err => {
                    if (err != null) {
                      return done(err)
                    }
                    this.owner.getProject(this.projectId, (err, project) => {
                      if (err != null) {
                        return done(err)
                      }
                      this.tokens = project.tokens
                      const docInfo = {
                        exists: true,
                        exported: false,
                        has_owner: true,
                        name: 'Test Project Import Example',
                      }
                      MockV1Api.setDocInfo(this.tokens.readAndWrite, docInfo)
                      MockV1Api.setDocInfo(this.tokens.readOnly, docInfo)
                      db.projects.deleteOne({ _id: ObjectId(projectId) }, done)
                    })
                  }
                )
              })
            }
          )
        }
      )
    })

    afterEach(function () {
      delete settings.projectImportingCheckMaxCreateDelta
      delete settings.overleaf
    })

    it('should show importing page for read, and read-write tokens', function (done) {
      async.series(
        [
          cb =>
            tryReadAndWriteTokenAccess(
              this.owner,
              this.tokens.readAndWrite,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              (response, body) => {
                expect(response.statusCode).to.equal(200)
                expect(body).to.deep.equal({
                  v1Import: {
                    status: 'canDownloadZip',
                    projectId: this.tokens.readAndWrite,
                    hasOwner: true,
                    name: 'Test Project Import Example',
                  },
                })
              },
              cb
            ),
          cb =>
            tryReadOnlyTokenAccess(
              this.owner,
              this.tokens.readOnly,
              (response, body) => {
                expect(response.statusCode).to.equal(200)
              },
              (response, body) => {
                expect(response.statusCode).to.equal(200)
                expect(body).to.deep.equal({
                  v1Import: {
                    status: 'canDownloadZip',
                    projectId: this.tokens.readOnly,
                    hasOwner: true,
                    name: 'Test Project Import Example',
                  },
                })
              },
              cb
            ),
          cb =>
            tryEditorAccess(
              this.owner,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(404)
              },
              cb
            ),
          cb =>
            tryContentAccess(
              this.other2,
              this.projectId,
              (response, body) => {
                expect(response.statusCode).to.equal(404)
              },
              cb
            ),
        ],
        done
      )
    })

    describe('when the v1 doc does not exist', function (done) {
      beforeEach(function (done) {
        const docInfo = null
        MockV1Api.setDocInfo(this.tokens.readAndWrite, docInfo)
        MockV1Api.setDocInfo(this.tokens.readOnly, docInfo)
        done()
      })

      it('should get a 404 response on the post endpoint', function (done) {
        async.series(
          [
            cb =>
              tryReadAndWriteTokenAccess(
                this.owner,
                this.tokens.readAndWrite,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                (response, body) => {
                  expect(response.statusCode).to.equal(404)
                },
                cb
              ),
            cb =>
              tryReadOnlyTokenAccess(
                this.owner,
                this.tokens.readOnly,
                (response, body) => {
                  expect(response.statusCode).to.equal(200)
                },
                (response, body) => {
                  expect(response.statusCode).to.equal(404)
                },
                cb
              ),
            cb =>
              tryEditorAccess(
                this.owner,
                this.projectId,
                (response, body) => {
                  expect(response.statusCode).to.equal(404)
                },
                cb
              ),
            cb =>
              tryContentAccess(
                this.other2,
                this.projectId,
                (response, body) => {
                  expect(response.statusCode).to.equal(404)
                },
                cb
              ),
          ],
          done
        )
      })
    })
  })
})
