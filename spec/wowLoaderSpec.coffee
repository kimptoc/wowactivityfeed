should = require 'should'
sinon = require 'sinon'

require "./commonSpec"
require './init_logger'

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
      wow.ensure_registered {region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}, ->
        wf.info "test/wowloader/registered"
        wowload = new wf.WoWLoader(wow)
        wf.info "test/wowloader/created wowload"
        wowload.armory_load ->
          wf.info "test/wowloader/loaded"
          wow.get_loaded (docs) ->
            wf.info "test/wowloader/got loaded"
            should.exist docs
            docs.length.should.be.above 10
            done()

