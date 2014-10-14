mongoose = require "mongoose"

mongoose.connect("mongodb://localhost/fixture_primary_test")
mongoose.createConnection("mongodb://localhost/fixture_secondary_test")
