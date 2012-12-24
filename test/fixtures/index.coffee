mongoose = require('mongoose')
models = require('./models')

mongoose.connect('mongodb://localhost:27017/express_mongoose_crud_tests')

Author = exports.Author = models.Author
Book = exports.Book = models.Book
Review = exports.Review = models.Review

# setup the DB for the tests
exports.before = (done) =>
  exports.authors = []
  exports.books = []
  exports.reviews = []

  exports.named_authors = {}
  exports.named_books = {}

  await Author.create {
    name: "Giacomo Leopardi"
    birth_date: new Date(1798, 5, 29)
  }, defer(err, leopardi)
  done(err)  if (err)
  exports.authors.push leopardi
  exports.named_authors.leopardi = leopardi

  await Book.create { title: "Zibaldone", author: leopardi }, defer(err, zibaldone)
  done(err)  if (err)
  exports.books.push zibaldone
  exports.named_books.zibaldone = zibaldone

  await Author.create {
    name: "Alessandro Manzoni"
    birth_date: new Date(1785, 2, 7)
  }, defer(err, manzoni)
  done(err)  if (err)
  exports.authors.push manzoni
  exports.named_authors.manzoni = manzoni

  await Book.create { title: "I Promessi Sposi", author: manzoni }, defer(err, promessi_sposi)
  done(err)  if (err)
  exports.books.push promessi_sposi
  exports.named_books.promessi_sposi = promessi_sposi

  await Review.create {
      title: "Zibaldone: first impressions"
      book: zibaldone
      text: "It was a dark and stormy night"
  }, defer(err, review_zibaldone)
  done(err)  if (err)
  exports.reviews.push review_zibaldone

  await Review.create {
      title: "About 'I Promessi Sposi'"
      book: promessi_sposi
      text: "The quick brown fox..."
  }, defer(err, review_promessi_sposi)
  done(err)  if (err)
  exports.reviews.push review_promessi_sposi

  done()

# teardown the DB after a testshave been performed
exports.after = (done) ->
  await Review.remove {}, defer (err)
  done(err)  if (err)

  await Book.remove {}, defer (err)
  done(err)  if (err)

  await Author.remove {}, defer (err)
  done(err)  if (err)

  done()
