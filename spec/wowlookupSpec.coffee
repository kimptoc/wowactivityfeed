should = require 'should'
require "./commonSpec"

require "./wowlookup"

describe "wow armory lookup", ->
  describe "get", ->
    it "valid armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get "guild", "eu", "Darkspear", "Mean Girls", (result) ->
        should.exist result
        done()
