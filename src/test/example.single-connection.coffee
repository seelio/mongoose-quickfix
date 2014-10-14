Fixture = require "../"

async = require "async"
expect = require "expect.js"
mongoose = require "mongoose"

# This is the actual test
describe "Person model", ->
  before (done) ->
    Fixture.use([])
    Fixture.initModels(done)

  beforeEach (done) ->
    Fixture.populate(done)

  it "should be able to find things", (done) ->
    mongoose.models.Person.find {}, (err, people) ->
      expect(people).to.have.length(4)
      done()

  it "should find stuff", (done) ->
    mongoose.models.Person.findOne { name: "Elon Musk" }, (err, elon) ->
      expect(elon.name).to.be("Elon Musk")
      done()

  it "should delete stuff", (done) ->
    mongoose.models.Person.findOne { name: "Elon Musk" }, (err, elon) ->
      elon.remove()
      mongoose.models.Person.find {}, (err, people) ->
        expect(people).to.have.length(3)
        done()

  it "should reset deletions", (done) ->
    mongoose.models.Person.find {}, (err, people) ->
      expect(people).to.have.length(4)
      done()

  it "should modify stuff", (done) ->
    mongoose.models.Person.findOne { _id: "000000000000000000000004" }, (err, elon) ->
      expect(elon.name).to.be("Elon Musk")
      elon.name = "Elon Reeve Musk"
      elon.save(done)

  it "should reset modifications", (done) ->
    mongoose.models.Person.findOne { _id: "000000000000000000000004" }, (err, elon) ->
      throw err if err
      expect(elon.name).to.be("Elon Musk")
      done()

  it "should insert stuff", (done) ->
    jaymes = new mongoose.models.Person({ name: 'Jaymes Young' });
    jaymes.save (err) ->
      throw err if err
      mongoose.models.Person.findOne { name: 'Jaymes Young' }, (err, jaymes) ->
        throw err if err
        expect(jaymes.name).to.be('Jaymes Young')
        done()

  it "should reset insertions", (done) ->
    mongoose.models.Person.find {}, (err, people) ->
      expect(people).to.have.length(4)
      done()

  it "should findAndModify", (done) ->
    mongoose.models.Person.findByIdAndUpdate "000000000000000000000004", { name: "Elon Reeve Musk" }, (err, elon) ->
      throw err if err
      # expect(elon.name).to.be("Elon Reeve Musk")
      mongoose.models.Person.findOne { _id: "000000000000000000000004"}, (err, elon) ->
        throw err if err

        expect(elon.name).to.be("Elon Reeve Musk")
        done()

  it "should reset findAndModifyes", (done) ->
    mongoose.models.Person.findOne { _id: "000000000000000000000004" }, (err, elon) ->
      throw err if err
      expect(elon.name).to.be("Elon Musk")
      done()

  it "should find and remove (modify)", (done) ->
    mongoose.models.Person.findByIdAndRemove "000000000000000000000004", (err) ->
      throw err if err
      mongoose.models.Person.findOne { _id: "000000000000000000000004" }, (err, elon) ->
        expect(elon).to.be(null)
        done()

  it "should reset find and remove (modify)", (done) ->
    mongoose.models.Person.findOne { _id: "000000000000000000000004" }, (err, elon) ->
      expect(elon.name).to.be("Elon Musk")
      done()
