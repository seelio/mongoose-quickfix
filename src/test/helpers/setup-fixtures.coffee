mongoose = require "mongoose"
Fixture  = require "../../fixture"

Fixture.setupConnection(mongoose.connections[0])
Fixture.findFixtures(__dirname + "/../fixtures", ".js")
