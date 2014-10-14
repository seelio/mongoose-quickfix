mongoose = require "mongoose"
Fixture  = require "../../fixture"

Fixture.setupConnection(mongoose.connections[0])
Fixture.setupConnection(mongoose.connections[1], false)
Fixture.findFixtures(__dirname + "/../fixtures", ".js")
