async = require "async"

Revert = (collections, documents) ->
  @collections = collections
  @documents   = documents

  @


Revert::restoreCollection = (collection, done) ->
  docs = @collections[collection.name]

  collection.secureChannel.remove {}, (err) ->
    collection.secureChannel.insert docs, done


Revert::unremoveDocById = (id, collection, done) ->
  doc            = @documents[collection.name][String(id)]

  collection.secureChannel.insert doc, done

    
Revert::uninsertDocById = (id, collection, done) ->
  collection.secureChannel.remove { _id: id }, done


Revert::unupdateDocById = (id, collection, done) ->
  doc            = @documents[collection.name][String(id)]

  collection.secureChannel.update { _id: id }, doc, done


Revert::insert = (id, collection, opts, done) ->
  @uninsertDocById(id, collection, done)


Revert::remove = (id, collection, opts, done) ->
  @unremoveDocById id, collection, done


Revert::update = (id, collection, opts, done) ->
  @unupdateDocById id, collection, done


Revert::findAndModify = (id, collection, opts, done) ->
  if opts.remove
    @unremoveDocById(id, collection, done)
  else
    @unupdateDocById(id, collection, done)


Revert::revertTransaction = (method, dataitem, done) ->
  collection = dataitem.collection
  findparams = dataitem.args["0"]
  ids        = null

  ids =
    if findparams?._id?['$in']?
      findparams._id['$in']
    else
      [findparams._id]

  opts = 
    if method == 'findAndModify'
      { remove: dataitem.args["3"].remove }
    else
      {}

  async.eachSeries ids, (id, nextId) =>
    @[method](id, collection, opts, nextId)
  ,
    done


Revert::handle = (method, dataitem, done) ->
  collection = dataitem.collection
  findparams = dataitem.args["0"]

  if findparams?._id?
    return @revertTransaction(method, dataitem, done)
  else
    return @restoreCollection(collection, done)


module.exports = Revert
