# express-mongoose-crud example

coffee = require('coffee-script')
express = require('express')
http = require('http')
mongoose = require('mongoose')
express_mongoose_crud = require('../src/index')

path = require('path')

models = require('./models')

db = mongoose.connect("mongodb://localhost/express_mongoose_crud_example")

app = module.exports = express()
app.configure ->
  app.set "views", path.join(__dirname, "/views")
  app.set "view engine", "jade"
  app.use express.logger()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session(secret: 'everyone knows')
  app.use app.router
  app.use express.static(path.join(__dirname, "public"))

app.enable("jsonp callback")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

app.configure "production", ->
  app.use express.errorHandler()

app.configure "test", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

get_or_create_model = (model, search_field, data, cb) ->
  search_criteria = {}
  search_criteria[search_field] = data[search_field]
  model.findOne search_criteria, (err, item) ->
    throw err  if err
    if item
      cb(item)
    else
      model.create data, (err, item) ->
        throw err  if (err)
        cb(item)

get_or_create_model models.Author, 'name', {
  name: "Giacomo Leopardi"
  birth_date: new Date(1798, 5, 29)
}, (author) ->
  get_or_create_model models.Book, 'title', { title: "Zibaldone", author: author }, (book) ->
    get_or_create_model models.Review, 'title', {
      title: "Zibaldone: first impressions"
      book: book
      text: "It was a dark and stormy night"
    }, (review) ->
      review

get_or_create_model models.Author, 'name', {
  name: "Alessandro Manzoni"
  birth_date: new Date(1785, 2, 7)
}, (author) ->
  get_or_create_model models.Book, 'title', { title: "I Promessi Sposi", author: author }, (book) ->
    get_or_create_model models.Review, 'title', {
      title: "About 'I Promessi Sposi'"
      book: book
      text: "The quick brown fox..."
    }, (review) ->
      review

r_author = new express_mongoose_crud.Resource
  model: models.Author
  exclude: ['birth_date']
r_author.mount(app)

r_book = new express_mongoose_crud.Resource
  model: models.Book
r_book.mount(app)

# r_review = new express_mongoose_crud.Resource
#   model: models.Review
# r_review.mount(app)
r_review = new express_mongoose_crud.Resource
  model: models.Review
r_review.mount(r_book, { relation: 'book' })

if process.env.NODE_ENV != 'test'
  server = http.createServer(app)
  server.listen 8080, "127.0.0.1", 511, ->
    console.log "Express server listening on %d in %s mode", server.address().port, app.settings.env
