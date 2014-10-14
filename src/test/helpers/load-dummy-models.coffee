mongoose = require "mongoose"

personSchema = new mongoose.Schema({ name: 'string' })
Person = mongoose.model('Person', personSchema)

placeSchema = new mongoose.Schema({ name: 'string' })
Place = mongoose.model('Place', placeSchema)
