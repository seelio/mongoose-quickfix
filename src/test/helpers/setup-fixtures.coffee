mongoose = require "mongoose"
Quickfix  = require "../../"

Quickfix.setupConnection(mongoose.connections[0])
Quickfix.findFixtures(__dirname + "/../fixtures", ".js")
