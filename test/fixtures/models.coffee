mongoose = require('mongoose')

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

# -- Author -----------------------------------------------------------

AuthorSchema = new Schema
  name: { type: String, required: true, index: true }
  birth_date: Date
  notes: String

AuthorSchema.methods.toString = () ->
  id = @get('id')
  name = @get('name')
  if name
    return "#{name}"
  return "<Author id:#{id}>"

AuthorSchema.methods.getBooks = (cb) ->
  module.exports.Book.find({ author: @get('id') }, cb)

# -- Book -------------------------------------------------------------

BookSchema = new Schema
  author: { type: ObjectId, ref: 'Author', required: false, default: null, index: true }
  title: { type: String, required: true }
  subtitle: String
  year: Number
  description: String
  notes: String

BookSchema.methods.toString = () ->
  id = @get('id')
  title = @get('title')
  if title
    return "#{title}"
  return "<Book id:#{id}>"

BookSchema.methods.getAuthor = (cb) ->
  module.exports.Author.findOne({ _id: @get('author') }, cb)

# -- Review -----------------------------------------------------------

ReviewSchema = new Schema
  book: { type: ObjectId, ref: 'Book', required: true, index: true }
  title: { type: String, required: true }
  text: String
  date: Date
  notes: String

ReviewSchema.methods.toString = () ->
  id = @get('id')
  return "<Review id:#{id}>"

ReviewSchema.methods.getBook = (cb) ->
  module.exports.Book.findOne({ _id: @get('book') }, cb)

# -- exports ----------------------------------------------------------

module.exports =
  Author: mongoose.model('Author', AuthorSchema)
  Book: mongoose.model('Book', BookSchema)
  Review: mongoose.model('Review', ReviewSchema)
