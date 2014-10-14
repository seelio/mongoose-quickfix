mongoose = require "mongoose"
exports.toCollectionName = require("mongoose/lib/utils").toCollectionName

routeCast = (item) ->
  # if item

castArray = (array) ->
  for item in array
    if Array.isArray(item)
      castArray(item)
    # else if typeof
      # ...
    
castObject = (obj) ->

castString = (str) ->

# Internal: Accepts an object and recursively converts values into MongoDB
# `ObjectId`s
#
# object - A JavaScript Object
#
# Returns an Object
exports.castObjectIds = castObjectIds = (object) ->
  for key of object
    continue  if key is "_bsontype"
    if typeof (object[key]) is "object" and not Array.isArray(object[key])
      castObjectIds object[key]
    else if key.search("_") is 0
      if typeof object[key] is "string"
        try
          object[key] = mongoose.Types.ObjectId(object[key])
        catch err
          console.warn "Error converting to object id for fixture generation; check that string maps correctly to an object_id, for key", key, "in", object._id
      else if Array.isArray(object[key])
        object[key].forEach (item) ->
          try
            unless item instanceof mongoose.Types.ObjectId
              object[key][object[key].indexOf(item)] = mongoose.Types.ObjectId(item)
          catch err
            console.warn "Error converting to object id for fixture generation; check that string maps correctly to an object_id, for key", key, "in", object._id

    else if Array.isArray(object[key])
      object[key].forEach (item) ->
        castObjectIds item  if typeof (item) is "object" or typeof (item) is "array"
