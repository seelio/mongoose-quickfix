Fixture = require "../"

expect = require "expect.js"
mongoose = require "mongoose"

ShadowPlace = mongoose.connections[1].models.Place

describe "ShadowPlace model", ->
  before (done) ->
    Fixture.use([])
    Fixture.initModels(done)

  beforeEach (done) ->
    Fixture.populate(done)

  it "should be empty", (done) ->
    ShadowPlace.find {}, (err, places) ->
      throw err if err
      expect(places).to.be.empty()
      done()

  it "should be able to insert things", (done) ->
    place = new ShadowPlace({ name: "Shadow Detroit" })
    place.save (err) ->
      throw err if err

      ShadowPlace.findOne { name: "Shadow Detroit"}, (err, detroit) ->
        throw err if err
        expect(detroit.name).to.be("Shadow Detroit")
        done()

  it "shouldn't be there anymore", (done) ->
    ShadowPlace.find {}, (err, places) ->
      throw err if err
      expect(places).to.be.empty()
      done()
