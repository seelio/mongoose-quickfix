async = require 'async'
fs = require 'fs'
util = require './util'
# path = require 'path'


Fixture = ->
  @connections = []
  @collections = {}
  @documents   = {}
  @_fixtures   = []
  @_location   = null
  @_datacenter = []

  @_superDirty = true

# Internal: Adds "wiretaps" to the connections to log modifications to the
# database.
#
# collection - a connection's collection
Fixture::wiretap = (collection) ->
  return if collection.secureChannel?

  collection.unmodifiedMethods = {}
  collection.secureChannel = {}
  methods = ["insert", "update", "remove", "findAndModify"]

  methods.forEach (m) =>
    collection.unmodifiedMethods[m] = collection[m]
    collection.secureChannel[m] = collection[m].bind(collection)

    collection[m] = () =>
      dataitem =
        method: m
        args: arguments
        collection: collection

      @_datacenter.push(dataitem)

      collection.unmodifiedMethods[m].apply(collection, arguments)


# Internal: load fixtures from file and into @collection
#
# force - force reloading
Fixture::loadFixturesIntoMemory = (force = false) ->
  if force || Object.keys(@collections).length == 0
    @_superDirty = true

    @_fixtures.forEach (f) =>
      f.data = require(@_location + "/" + f.filename)

      f.data.forEach (fixtureDocument) =>
        util.castObjectIds fixtureDocument

      @collections[f.collection] = [] unless @collections[f.collection]?
      @collections[f.collection] = @collections[f.collection].concat(f.data)

    # here
    Object.keys(@collections).forEach (collectionName) =>
      @documents[collectionName] = {}
      @collections[collectionName].forEach (row) =>
        @documents[collectionName][String(row._id)] = row      


# Public: Finds all fixtures in directory. The filenames in the directory
# must be in the format of `$collection.[optional].js`.
#
# absFixturePath -
# extension      -
Fixture::findFixtures = (absFixturePath, extension) ->
  return @_fixtures if @_fixtures.length > 0

  @_location = absFixturePath

  files = fs.readdirSync(@_location)
  files = files.filter (filename) ->
    filename.substr(-extension.length) == extension

  files.forEach (file) =>
    collection = file.split('.')[0]
    @_fixtures.push
      filename: file
      collection: util.toCollectionName(collection)

  @_fixtures


# Public: Sets up (additional) connections
# 
# connections - an Array of mongoose connections
# done        - the callback to run
#
# Raises error if connection is bad
#
# Returns nothing
Fixture::setupConnection = (connection, load = true) ->
  @connections.push
    connection:   connection
    loadFixtures: !!load

  @connections


# Public: resets connections
Fixture::resetConnections = ->
  @connections = []


# Internal: Yields when all @connections are ready
#
# Returns nothing
Fixture::ensureConnectionsReady = (done) ->
  async.each @connections,
    (conn, next) ->
      if conn.connection.readyState == 1
        next()
      else
        conn.connection.on "open", ->
          next()
        conn.connection.on "error", ->
          next("err")
  ,
    () ->
      done()

Fixture::ensureCollectionsExistInConnection = (done) ->
  collectionNames = Object.keys(@collections)

  async.each @connections,
    (conn, nextConn) =>
      return nextConn() if conn.loadFixtures == false

      async.each collectionNames,
        (collectionName, nextCollection) =>
          conn.connection.collection(collectionName)
          nextCollection()
      ,
        nextConn
  ,
    done

Fixture::insertAllDataIntoDatabase = (done) ->
  collectionNames = Object.keys(@collections)

  async.each @connections,
    (conn, nextConn) =>
      return nextConn() if conn.loadFixtures == false

      async.each collectionNames,
        (collectionName, nextCollection) =>
          collection = conn.connection.collection(collectionName)
          data       = @collections[collectionName]

          collection.secureChannel.insert data, { safe: true }, (err, docs) =>
            nextCollection(err)
      ,
        nextConn
  ,
    (err) =>
      @_superDirty = false
      done()


Fixture::destroyAllDataFromDatabase = (done) ->
  collectionNames = Object.keys(@collections)
  @_superDirty = true

  async.each @connections,
    (conn, nextConn) =>
      async.each collectionNames,
        (collectionName, nextCollection) =>
          collection = conn.connection.collection(collectionName)

          collection.secureChannel.remove {}, { safe: true }, (err, docs) =>
            nextCollection(err)
      ,
        nextConn
  ,
    done


Fixture::commenceMassSurveillance = (done) ->
  async.each @connections, (conn, nextConn) =>
    async.each Object.keys(conn.connection.collections), (collectionName, nextCollection) =>
      @wiretap(conn.connection.collection(collectionName))
      nextCollection()
    ,
      nextConn
  ,
    done


# Public: Ensures all connections are ready. Ensures fixtures are read.
# Ensures collections are created.
Fixture::ready = (done) ->
  # throw new Error('Fixture::setupConnection asdf') if @connections.length == 0
  async.series [
    (next) =>
      @ensureConnectionsReady(next)
    (next) =>
      @loadFixturesIntoMemory()
      next()
    (next) =>
      @ensureCollectionsExistInConnection(next)
    (next) =>
      # wiretap
      @commenceMassSurveillance(next)
  ],
    done

Fixture::destroyDatacenter = (done) ->
  while (@_datacenter.length > 0)
    @_datacenter.pop()
  done()


Fixture::unDirtyifyCollection = (collection, done) ->
  docs = @collections[collection.name]

  collection.secureChannel.remove {}, (err) ->
    collection.secureChannel.insert docs, done


Fixture::unremoveDocById = (findparam, collection, done) ->
  id             = String(findparam._id)
  collectionName = collection.name
  doc            = @documents[collectionName][id]

  collection.secureChannel.insert doc, done


Fixture::restoreRemove = (dataitem, done) ->
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
    
Fixture::uninsertDoc = (findparam, collection, done) ->
  collection.secureChannel.remove { _id: findparam._id }, done


Fixture::restoreInsert = (dataitem, done) ->
  collection = dataitem.collection
  findparams = dataitem.args["0"]
  @uninsertDoc(findparams, collection, done)


Fixture::unupdateDocById = (findparam, collection, done) ->
  id             = String(findparam._id)
  collectionName = collection.name
  doc            = @documents[collectionName][id]

  collection.secureChannel.update { _id: findparam._id }, doc, done

Fixture::restoreUpdate = (dataitem, done) ->
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

Fixture::restoreFindAndModify = (dataitem, done) ->
  collection = dataitem.collection
  findparams = dataitem.args["0"]
  remove     = dataitem.args["3"].remove

  if remove
    @unremoveDocById(findparams, collection, done)
  else
    @unupdateDocById(findparams, collection, done)




Fixture::selectivelyRestoreDatabase = (done) ->
  async.whilst () => @_datacenter.length > 0
    ,
    (next) =>
      dataitem = @_datacenter.pop()

      switch dataitem.method
        when "insert"
          return @restoreInsert(dataitem, next)
        when "update"
          return @restoreUpdate(dataitem, next)
        when "remove"
          return @restoreRemove(dataitem, next)
        when "findAndModify"
          return @restoreFindAndModify(dataitem, next)
    ,
      done


Fixture::populate = (done) ->
  if @_superDirty
    async.series [
      (next) =>
        @destroyAllDataFromDatabase(next)
      (next) =>
        @insertAllDataIntoDatabase(next)
      (next) =>
        @destroyDatacenter(next)
    ],
      done
  else if @_datacenter.length > 0
    async.series [
      (next) =>
        @selectivelyRestoreDatabase(next)
    ],
      done
  else
    done()


# Deprecated: Use Fixture::ready
Fixture::initModels = (done) ->
  # console.warn "DEPRECATED: Use `Fixture::ready`"
  @ready(done)


# Deprecated: Specifies the models and fixtures to use and load.
Fixture::use = (ignore) ->
  # console.warn "DEPRECATED: This method doesn't do anything anymore"
  # do nothing

module.exports = new Fixture
