ObjectId = require('mongodb').BSONNative.ObjectID

# from http://stackoverflow.com/questions/11060631/how-do-i-clone-copy-an-instance-of-an-object-in-coffeescript
clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = new obj.constructor()
  for key of obj
    temp[key] = clone(obj[key])
  temp

massage_record = (obj) ->
  copy = clone(obj)
  copy.id = "#{obj._id}"
  delete copy._id
  copy

push_record = (items, obj) ->
  items.push massage_record(obj)

exports.authors = []
exports.books = []
exports.reviews = []

exports.by_model = {}

exports.by_model.Author =
  leopardi:
    _id: new ObjectId()
    name: "Giacomo Leopardi"
    birth_date: new Date(1798, 5, 29)
  manzoni:
    _id: new ObjectId()
    name: "Alessandro Manzoni"
    birth_date: new Date(1785, 2, 7)
for key, obj of exports.by_model.Author
  push_record exports.authors, obj

exports.by_model.Book =
  zibaldone:
    _id: new ObjectId()
    title: "Zibaldone"
    author: exports.by_model.Author.leopardi._id
  promessi_sposi:
    _id: new ObjectId()
    title: "I Promessi Sposi"
    author: exports.by_model.Author.manzoni._id
for key, obj of exports.by_model.Book
  push_record exports.books, obj

exports.by_model.Review =
  zibaldone_1:
    _id: new ObjectId()
    title: "Zibaldone: first impressions"
    book: exports.by_model.Book.zibaldone._id
    text: "It was a dark and stormy night"
  promessi_sposi_1:
    _id: new ObjectId()
    title: "About 'I Promessi Sposi'"
    book: exports.by_model.Book.promessi_sposi._id
    text: "The quick brown fox..."
for key, obj of exports.by_model.Review
  push_record exports.reviews, obj
