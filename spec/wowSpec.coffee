should = require 'should'
require "./commonSpec"

require "./wow"

describe "wow wrapper", ->
  describe "register", ->

    wow = null

    beforeEach (done)->
      wf.info "wowSpec:beforeEach"
      wow = new wf.WoW()
      wow.clear_registered ->
        done()

    afterEach ->
      wf.info "wowSpec:afterEach"
      # wow?.close()

    it "clear wow", (done) ->
      wow.clear_registered ->
        wow.get_registered (items) ->
          items.length.should.equal 0
          done()

    it "add/check register", (done)->
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wow.get_registered (items) ->
          items.length.should.equal 1
          done()

    it "dont double register", (done)->
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
          wow.get_registered (items) ->
            items.length.should.equal 1
            wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls2", ->
              wow.get_registered (items) ->
                items.length.should.equal 2
                done()

    it "armory load/valid guild", (done) ->
      wf.info "load valid guild"
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wow.armory_load ->
          done()

    it "armory load/invalid guild", (done) ->
      wf.info "load invalid guild"
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls321", ->
        wow.armory_load ->
          done()

    it "armory load/valid member", (done) ->
      wf.info "load valid member"
      wow.ensure_registered "eu", "Darkspear", "member", "Kimptocii", ->
        wow.armory_load ->
          done()

    it "armory load/invalid member", (done) ->
      wf.info "load invalid member"
      wow.ensure_registered "eu", "Darkspear", "member", "Kimptocii555", ->
        wow.armory_load ->
          done()

    it "armory load several valid/invalid", (done) ->
      wf.info "load several valid/invalid"
      callbacks = 0
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wow.ensure_registered "eu", "Darkspear", "guild", "Mean GirlsQQQ", ->
          wow.ensure_registered "eu", "Darkspear", "member", "Kimptonite", ->
            wow.ensure_registered "eu", "Darkspear", "member", "Kimptonite444", ->
              wow.armory_load ->
                callbacks += 1
                done() if callbacks == 4
