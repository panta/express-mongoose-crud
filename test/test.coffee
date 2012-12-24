chai = require('chai')
assert = chai.assert
expect = chai.expect
should = chai.should()
express = require('express')
request = require('supertest')

fixtures = require('./fixtures')

express_mongoose_crud = require('../src/index.coffee')

app = express.createServer()
app.configure ->
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session(secret: 'everyone knows')
  app.use app.router
app.enable("jsonp callback")

r_author = new express_mongoose_crud.Resource
  model: fixtures.Author
  exclude: ['birth_date']
r_author.mount(app)

r_book = new express_mongoose_crud.Resource
  model: fixtures.Book
r_book.mount(app)

r_review = new express_mongoose_crud.Resource
  model: fixtures.Review
r_review.mount(r_book, { relation: 'book' })

describe 'WHEN working with the library', ->
  beforeEach(fixtures.before)
  # before (done) ->
  #   done()

  afterEach(fixtures.after)
  # after (done) ->
  #   done()

  describe 'library', ->
    it 'should exist', (done) ->
      should.exist express_mongoose_crud
      done()

  describe 'GET /api/v1/authors', ->
    it 'should return the correct number of records', (done) =>
      request(app)
        .get('/api/v1/authors')
        .set('Accept', 'application/json')
        .expect('Content-Type', /json/)
        .expect(200)
        .end (err, res) =>
          throw (err)  if (err)
          should.equal res.statusCode, 200
          should.equal res.body.length, fixtures.authors.length
          done()

  describe 'GET /api/v1/books', ->
    it 'should return the correct number of records', (done) =>
      request(app)
        .get('/api/v1/books')
        .set('Accept', 'application/json')
        .expect('Content-Type', /json/)
        .expect(200)
        .end (err, res) =>
          throw (err)  if (err)
          should.equal res.statusCode, 200
          should.equal res.body.length, fixtures.books.length
          done()

  describe 'GET /api/v1/books/:bookId', ->
    it 'should return the correct record for existing id values', (done) =>
      check_book = (book, cb) ->
        request(app)
          .get("/api/v1/books/#{book.id}")
          .set('Accept', 'application/json')
          .expect('Content-Type', /json/)
          .expect(200)
          .end (err, res) ->
            throw (err)  if (err)
            should.equal res.statusCode, 200
            should.equal res.body.id, book.id
            should.equal res.body.title, book.title
            should.equal res.body.author, book.author.toString()
            cb()
      await
        for book in fixtures.books
          check_book book, defer()
      done()

    it 'should return 404 for non-existing id values', (done) ->
      request(app)
        .get("/api/v1/books/012345678901234567890123")
        .set('Accept', 'application/json')
        .expect(404)
        .end (err, res) ->
          throw (err)  if (err)
          should.equal res.statusCode, 404
          done()
