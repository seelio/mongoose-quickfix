async = require "async"

Revert = (collections, documents) ->
  @collections = collections
  @documents   = documents

  @


Revert::unDirtyifyCollection = (collection, done) ->
  docs = @collections[collection.name]

  collection.secureChannel.remove {}, (err) ->
    collection.secureChannel.insert docs, done


Revert::unremoveDocById = (findparam, collection, done) ->
  id             = String(findparam._id)
  collectionName = collection.name
  doc            = @documents[collectionName][id]

  collection.secureChannel.insert doc, done


Revert::restoreRemove = (dataitem, done) ->
  collection = dataitem.collection
  findparams = dataitem.args["0"]

  reinserts = null

  if findparams._id?
    if findparams._id['$in']?
      reinserts = findparams._id['$in']
    else
      reinserts = [findparams]

    async.each reinserts, (findparam, next) =>
      @unremoveDocById findparam, collection, next
    ,
      done
  else
    unDirtyifyCollection(collection, done)

    
Revert::uninsertDoc = (findparam, collection, done) ->
  collection.secureChannel.remove { _id: findparam._id }, done


Revert::restoreInsert = (dataitem, done) ->
  collection = dataitem.collection
  findparams = dataitem.args["0"]
  @uninsertDoc(findparams, collection, done)


Revert::unupdateDocById = (findparam, collection, done) ->
  id             = String(findparam._id)
  collectionName = collection.name
  doc            = @documents[collectionName][id]

  collection.secureChannel.update { _id: findparam._id }, doc, done


Revert::restoreUpdate = (dataitem, done) ->
  collection = dataitem.collection
  findparams = dataitem.args["0"]

  reinserts = null

  if findparams._id?
    if findparams._id['$in']?
      reinserts = findparams._id['$in']
    else
      reinserts = [findparams]

    async.each reinserts, (findparam, next) =>
      @unupdateDocById findparam, collection, next
    ,
      done
  else
    unDirtyifyCollection(collection, done)


Revert::restoreFindAndModify = (dataitem, done) ->
  collection = dataitem.collection
  findparams = dataitem.args["0"]
  remove     = dataitem.args["3"].remove

  if remove
    @unremoveDocById(findparams, collection, done)
  else
    @unupdateDocById(findparams, collection, done)


module.exports = Revert
