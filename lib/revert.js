// Generated by CoffeeScript 1.7.1
(function() {
  var Revert, async;

  async = require("async");

  Revert = function(collections, documents) {
    this.collections = collections;
    this.documents = documents;
    return this;
  };

  Revert.prototype.unDirtyifyCollection = function(collection, done) {
    var docs;
    docs = this.collections[collection.name];
    return collection.secureChannel.remove({}, function(err) {
      return collection.secureChannel.insert(docs, done);
    });
  };

  Revert.prototype.unremoveDocById = function(findparam, collection, done) {
    var collectionName, doc, id;
    id = String(findparam._id);
    collectionName = collection.name;
    doc = this.documents[collectionName][id];
    return collection.secureChannel.insert(doc, done);
  };

  Revert.prototype.restoreRemove = function(dataitem, done) {
    var collection, findparams, reinserts;
    collection = dataitem.collection;
    findparams = dataitem.args["0"];
    reinserts = null;
    if (findparams._id != null) {
      if (findparams._id['$in'] != null) {
        reinserts = findparams._id['$in'];
      } else {
        reinserts = [findparams];
      }
      return async.each(reinserts, (function(_this) {
        return function(findparam, next) {
          return _this.unremoveDocById(findparam, collection, next);
        };
      })(this), done);
    } else {
      return unDirtyifyCollection(collection, done);
    }
  };

  Revert.prototype.uninsertDoc = function(findparam, collection, done) {
    return collection.secureChannel.remove({
      _id: findparam._id
    }, done);
  };

  Revert.prototype.restoreInsert = function(dataitem, done) {
    var collection, findparams;
    collection = dataitem.collection;
    findparams = dataitem.args["0"];
    return this.uninsertDoc(findparams, collection, done);
  };

  Revert.prototype.unupdateDocById = function(findparam, collection, done) {
    var collectionName, doc, id;
    id = String(findparam._id);
    collectionName = collection.name;
    doc = this.documents[collectionName][id];
    return collection.secureChannel.update({
      _id: findparam._id
    }, doc, done);
  };

  Revert.prototype.restoreUpdate = function(dataitem, done) {
    var collection, findparams, reinserts;
    collection = dataitem.collection;
    findparams = dataitem.args["0"];
    reinserts = null;
    if (findparams._id != null) {
      if (findparams._id['$in'] != null) {
        reinserts = findparams._id['$in'];
      } else {
        reinserts = [findparams];
      }
      return async.each(reinserts, (function(_this) {
        return function(findparam, next) {
          return _this.unupdateDocById(findparam, collection, next);
        };
      })(this), done);
    } else {
      return unDirtyifyCollection(collection, done);
    }
  };

  Revert.prototype.restoreFindAndModify = function(dataitem, done) {
    var collection, findparams, remove;
    collection = dataitem.collection;
    findparams = dataitem.args["0"];
    remove = dataitem.args["3"].remove;
    if (remove) {
      return this.unremoveDocById(findparams, collection, done);
    } else {
      return this.unupdateDocById(findparams, collection, done);
    }
  };

  module.exports = Revert;

}).call(this);