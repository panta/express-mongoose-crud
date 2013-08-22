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

  afterEach(fixtures.after)

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

  describe 'GET /api/v1/authors/:authorId', ->
    it 'should return the correct record for existing id values', (done) =>
      check_author = (author, cb) ->
        request(app)
          .get("/api/v1/authors/#{author.id}")
          .set('Accept', 'application/json')
          .expect('Content-Type', /json/)
          .expect(200)
          .end (err, res) ->
            throw (err)  if (err)
            should.equal res.statusCode, 200
            should.equal res.body.id, author.id
            should.equal res.body.name, author.name
            should.not.exist res.body.birth_date
            should.exist res.body.href
            cb()
      await
        for author in fixtures.authors
          check_author author, defer()
      done()

    it 'should return 404 for non-existing id values', (done) ->
      request(app)
        .get("/api/v1/authors/012345678901234567890123")
        .set('Accept', 'application/json')
        .expect(404)
        .end (err, res) ->
          throw (err)  if (err)
          should.equal res.statusCode, 404
          done()

  describe 'POST /api/v1/authors', ->
    it 'should give an error when required fields are not specified', (done) =>
      request(app)
        .post('/api/v1/authors')
        .set('Accept', 'application/json')
        .expect(500)
        .end (err, res) =>
          throw (err)  if (err)
          should.equal res.statusCode, 500
          done()

  describe 'POST /api/v1/authors', ->
    it 'should create a new record', (done) =>
      request(app)
        .post('/api/v1/authors')
        .send({ name: 'John Steinbeck', birth_date: new Date(1902, 1, 27) })
        .set('Accept', 'application/json')
        .expect('Content-Type', /json/)
        .expect(200)
        .end (err, res) =>
          throw (err)  if (err)
          should.equal res.statusCode, 200
          should.exist res.body.id
          should.equal res.body.name, "John Steinbeck"
          should.not.exist res.body.birth_date
          should.exist res.body.href
          done()

  describe 'PUT /api/v1/authors/:authorId', ->
    it 'should update an existing record', (done) =>
      update_author = (author, cb) ->
        request(app)
          .put("/api/v1/authors/#{author.id}")
          .send({ name: 'UPDATED', birth_date: new Date(2100, 0, 1) })
          .set('Accept', 'application/json')
          .expect('Content-Type', /json/)
          .expect(200)
          .end (err, res) ->
            throw (err)  if (err)
            should.equal res.statusCode, 200
            should.equal res.body.id, author.id
            should.equal res.body.name, 'UPDATED'
            should.not.exist res.body.birth_date
            should.exist res.body.href
            cb()
      await
        for author in fixtures.authors
          update_author author, defer()
      done()

    it 'should return 404 for non-existing id values', (done) ->
      request(app)
        .put("/api/v1/authors/012345678901234567890123")
        .send({ name: 'UPDATED', birth_date: new Date(2100, 0, 1) })
        .set('Accept', 'application/json')
        .expect(404)
        .end (err, res) ->
          throw (err)  if (err)
          should.equal res.statusCode, 404
          done()

    # it 'should give an error when excluded fields are specified', (done) =>
    #   author = fixtures.authors[0]
    #   console.log("author id:'#{author.id}'")
    #   request(app)
    #     .put("/api/v1/authors/#{author.id}")
    #     .send({ birth_date: 5 })
    #     .set('Accept', 'application/json')
    #     .expect(500)
    #     .end (err, res) =>
    #       throw (err)  if (err)
    #       should.equal res.statusCode, 500
    #       done()

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
