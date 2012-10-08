should = require 'should'
require "./commonSpec"

require "./wow"

describe "wow wrapper:", ->
  describe "register:", ->

    wow = null

    beforeEach (done)->
      wf.info "wowSpec:beforeEach"
      wow = new wf.WoW()
      wow.clear_all ->
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

    it "armory load valid guild", (done) ->
      wf.info "load valid guild"
      callbacks = 0
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wow.armory_load ->
          callbacks += 1
          done() if callbacks == 29

    it "armory load/valid guild/get", (done) ->
      wf.info "load valid guild"
      first_pass = true
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wow.armory_load ->
          wow.get "eu", "Darkspear", "guild", "Mean Girls", (doc)->
            should.exist doc
            wow.get_named "wowitem-guild:eu:Darkspear:Mean Girls", (doc) ->
              should.exist doc
              wow.get_history_named "wowitem-guild:eu:Darkspear:Mean Girls", (docs) ->
                should.exist docs
                docs.length.should.equal 1
                if first_pass
                  first_pass = false
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
                wf.debug "Got armory callback:#{callbacks}"
                done() if callbacks == 29

    it "try store update 1", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        lastModified: 123
      wow.store_update item, ->
        wow.get_history item.region,item.realm,item.type,item.name, (results) ->
          results.length.should.equal 1 
          should.exist results[0].whats_changed
          results[0].whats_changed.overview.should.equal "NEW" 
          done()

    it "try store update 2diff", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        lastModified: 123
      item2 =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        lastModified: 124
      wow.store_update item, ->
        wow.store_update item2, ->
          wow.get_history item.region,item.realm,item.type,item.name, (results) ->
            results.length.should.equal 2 
            results[0].lastModified.should.equal 124
            results[1].lastModified.should.equal 123
            should.exist results[0].whats_changed
            results[0].whats_changed.overview.should.equal "UPDATE" 
            results[0].whats_changed.changes.should.eql 
              lastModified : [123, 124]
            done()

    it "try store update 2same", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        lastModified: 123
      wow.store_update item, ->
        wow.store_update item, ->
          wow.get_history item.region,item.realm,item.type,item.name, (results) ->
            results.length.should.equal 1 
            should.exist results[0].whats_changed
            results[0].whats_changed.overview.should.equal "NEW" 
            done()

    it "should be no history initially", (done) ->
      wow.get_history "eu", "Darkspear", "guild", "Mean Girls", (results) ->
        results.length.should.equal 0
        done()

    it "save new update for valid item", (done) ->
      callbacks = 0
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wow.armory_load ->
          wow.get_history "eu", "Darkspear", "guild", "Mean Girls", (results) ->
            should.exist results
            results.length.should.equal 1
            callbacks += 1
            done() if callbacks == 29

    it "save 2 updates, identical for valid item", (done)->
      callbacks = 0
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wow.armory_load ->
          wow.armory_load ->
            wow.get_history "eu", "Darkspear", "guild", "Mean Girls", (results) ->
              should.exist results
              results.length.should.equal 1
              callbacks += 1
              done() if callbacks == 29
    
    it "save new update for invalid item", (done)->
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls321", ->
        wow.armory_load ->
          wow.get_history "eu", "Darkspear", "guild", "Mean Girls321", (results) ->
            should.exist results
            results.length.should.equal 1
            done()

    it "save 2 updates, identical for invalid item", (done)->
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls321", ->
        wow.armory_load ->
          wow.armory_load ->
            wow.get_history "eu", "Darkspear", "guild", "Mean Girls321", (results) ->
              should.exist results
              results.length.should.equal 1
              done()

    
