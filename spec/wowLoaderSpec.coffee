should = require 'should'
sinon = require 'sinon'

require './init_logger'
require "./commonSpec"

require "./wow"
require "./wow_loader"

describe "wow loader:", ->
  describe "basics:", ->

    wow = null
    # mock_store = null
    # mock_lookup = null

    beforeEach (done)->
      wf.info "wowSpec:beforeEach"
      wow = new wf.WoW (wow)->
        wow.clear_all ->
          done()

    afterEach ->
      # mock_store.verify() if mock_store?
      # mock_lookup.verify() if mock_lookup?


    it "armory load/valid guild/new/real", (done) ->
      this.timeout(20000);
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wowload = new wf.WoWLoader(wow)
        wowload.armory_load ->
          wow.get_loaded (docs) ->
            should.exist docs
            docs.length.should.be.above 10
            done()

