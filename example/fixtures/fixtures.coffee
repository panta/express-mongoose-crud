ObjectId = require('mongodb').BSONNative.ObjectID

exports.Author =
  Leopardi:
    _id: new ObjectId()
    name: "Giacomo Leopardi"
    birth_date: new Date(1798, 5, 29)
  Manzoni:
    _id: new ObjectId()
    name: "Alessandro Manzoni"
    birth_date: new Date(1785, 2, 7)

exports.Book =
  Zibaldone:
    _id: new ObjectId()
    title: "Zibaldone"
    author: exports.Author.Leopardi._id
  PromessiSposi:
    _id: new ObjectId()
    title: "I Promessi Sposi"
    author: exports.Author.Manzoni._id

exports.Review =
  r_Zibaldone_1:
    _id: new ObjectId()
    title: "Zibaldone: first impressions"
    book: exports.Book.Zibaldone._id
    text: "It was a dark and stormy night"
  r_PromessiSposi_1:
    _id: new ObjectId()
    title: "About 'I Promessi Sposi'"
    book: exports.Book.PromessiSposi._id
    text: "The quick brown fox..."
