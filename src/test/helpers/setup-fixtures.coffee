mongoose = require "mongoose"
Quickfix  = require "../../"

Quickfix.setupConnection(mongoose.connections[0])
Quickfix.setupConnection(mongoose.connections[1], false)
Quickfix.findFixtures(__dirname + "/../fixtures", ".js")
