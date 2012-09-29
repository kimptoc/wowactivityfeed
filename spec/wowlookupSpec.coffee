should = require 'should'
require "./commonSpec"

require "./wowlookup"

describe "wow armory lookup", ->
  describe "get", ->
    it "valid guild armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get "guild", "eu", "Darkspear", "Mean Girls", (result) ->
        should.exist result
        result.name.should.equal "Mean Girls"
        should.not.exist result.error
        done()

    it "invalid guild armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get "guild", "eu", "Darkspear", "Mean Girlsaaa", (result) ->
        should.exist result
        should.exist result.error
        should.not.exist result.name
        done()

    it "valid member armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get "member", "eu", "Darkspear", "Kimptoc", (result) ->
        should.exist result
        should.not.exist result.error
        result.name.should.equal "Kimptoc"
        done()

    it "invalid member armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get "member", "eu", "Darkspear", "Kimptocaaa", (result) ->
        should.exist result
        should.exist result.error
        should.not.exist result.name
        done()
