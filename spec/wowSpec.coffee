should = require 'should'
sinon = require 'sinon'

require "./commonSpec"

require "./wow"

describe "wow wrapper:", ->
  describe "register:", ->

    wow = null
    mock_store = null
    mock_lookup = null

    beforeEach (done)->
      wf.info "wowSpec:beforeEach"
      wow = new wf.WoW()
      wow.clear_all ->
        done()

    afterEach ->
      mock_store.verify() if mock_store?
      mock_lookup.verify() if mock_lookup?
      # wf.info "wowSpec:afterEach"
      # wow?.close()

    it "mock sample", (done)->
      test_thing_api = { go: -> }
      mock_thing = sinon.mock(test_thing_api)
      mock_thing.expects("go").once().yields()
      test_thing_api.go ->
        done()


    it "mock store, clear reg", (done) ->
      mock_store = sinon.mock(wow.get_store())
      mock_store.expects("remove_all").once().yields()
      wow.clear_registered ->
        done()


    it "clear wow", (done) ->
      mock_store = sinon.mock(wow.get_store())
      mock_store.expects("remove_all").once().yields()
      mock_store.expects("load_all").once().yields([])
      wow.clear_registered ->
        wow.get_registered (items) ->
          items.length.should.equal 0
          done()

    it "add/check register", (done)->
      mock_store = sinon.mock(wow.get_store())
      mock_store.expects("load").once().yields()
      mock_store.expects("add").once().yields()
      mock_store.expects("load_all").once().yields([{}])
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

    it "armory load/valid guild/new/mock", (done) ->
      mock_lookup = sinon.mock(wow.get_wowlookup())
      mock_lookup.expects("get").twice().yields
        region:"eu"
        realm:"Darkspear"
        type:"guild"
        name:"Mean Girls"
        members:
          [character:
            region:"eu"
            realm:"Darkspear"
            type:"member"
            name:"Kimptoc" ]
      mock_store = sinon.mock(wow.get_store())
      mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}])
      mock_store.expects("ensure_index").twice().yields()
      mock_store.expects("load").twice().yields()
      mock_store.expects("add").twice().yields() # guild and members
      mock_store.expects("update").never()

      wow.armory_load ->
        done()

    it "armory load/valid guild/new/real", (done) ->
      this.timeout(60000);
      wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
        wow.armory_load ->
          setTimeout (->
            wow.get_loaded (docs) ->
              should.exist docs
              docs.length.should.equal 29
              for doc in docs
                doc.name.should.equal doc.armory.name
              done()
          ), 10000

    it "armory load/valid guild/update, no change", (done) ->
      mock_lookup = sinon.mock(wow.get_wowlookup())
      mock_lookup.expects("get").twice().yields
        region:"eu"
        realm:"Darkspear"
        type:"guild"
        name:"Mean Girls"
        lastModified:123
        members:
          [character:
            region:"eu"
            realm:"Darkspear"
            type:"member"
            name:"Kimptoc" 
            lastModified:123
          ]
      mock_store = sinon.mock(wow.get_store())
      mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}])
      mock_store.expects("ensure_index").twice().yields()
      mock_store.expects("load").twice().yields({lastModified:123})
      mock_store.expects("add").never()
      mock_store.expects("update").never()

      wow.armory_load ->
        done()

    it "armory load/valid guild/update, with change", (done) ->
      mock_lookup = sinon.mock(wow.get_wowlookup())
      mock_lookup.expects("get").twice().yields
        region:"eu"
        realm:"Darkspear"
        type:"guild"
        name:"Mean Girls"
        lastModified:124
        members:
          [character:
            region:"eu"
            realm:"Darkspear"
            type:"member"
            name:"Kimptoc" 
            lastModified:125
          ]
      mock_store = sinon.mock(wow.get_store())
      mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}])
      mock_store.expects("ensure_index").twice().yields()
      mock_store.expects("load").twice().yields({lastModified:122})
      mock_store.expects("add").twice().yields()
      mock_store.expects("update").twice().yields()

      wow.armory_load ->
        done()

    it "armory load/invalid guild/new", (done) ->
      mock_lookup = sinon.mock(wow.get_wowlookup())
      mock_lookup.expects("get").once().yields
        region:"eu"
        realm:"Darkspear"
        type:"guild"
        name:"Mean Girls"
        error: "not found"
      mock_store = sinon.mock(wow.get_store())
      mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}])
      mock_store.expects("ensure_index").once().yields()
      mock_store.expects("load").once().yields()
      mock_store.expects("add").once().yields() # guild

      wow.armory_load ->
        done()

    it "armory load/valid member", (done) ->
      mock_lookup = sinon.mock(wow.get_wowlookup())
      mock_lookup.expects("get").once().yields
        region:"eu"
        realm:"Darkspear"
        type:"member"
        name:"Mean Girls"
      mock_store = sinon.mock(wow.get_store())
      mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"member", name:"Mean Girls"}])
      mock_store.expects("ensure_index").once().yields()
      mock_store.expects("load").once().yields()
      mock_store.expects("add").once().yields() # member

      wow.armory_load ->
        done()

    it "basic get when none", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        lastModified: 123
      wow.get item.region,item.realm,item.type,item.name, (result) ->
        wf.debug "back from get"
        # todo - should.not.exist result
        done()

    it "basic get_history when none", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        lastModified: 123
      wow.get_history item.region,item.realm,item.type,item.name, (results) ->
        wf.debug "back from get_history"
        results.length.should.equal 0 
        done()

    it "try store update 1", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        lastModified: 123
      wow.store_update item.type, item.region, item.realm, item.name, item, ->
        wow.get_history item.region,item.realm,item.type,item.name, (results) ->
          results.length.should.equal 1 
          # should.exist results[0].whats_changed
          results[0].whats_changed.overview.should.equal "NEW"
          wow.get item.region,item.realm,item.type,item.name, (result) ->
            # should.exist result
            wf.debug "result:#{JSON.stringify(result)}"
            result.name.should.equal "test"
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
      wow.store_update item.type, item.region, item.realm, item.name, item, ->
        wow.store_update item2.type, item2.region, item2.realm, item2.name, item2, ->
          wow.get_history item.region,item.realm,item.type,item.name, (results) ->
            results.length.should.equal 2 
            results[0].lastModified.should.equal 124
            results[1].lastModified.should.equal 123
            # should.exist results[0].whats_changed
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
      wow.store_update item.type, item.region, item.realm, item.name, item, ->
        wow.store_update item.type, item.region, item.realm, item.name, item, ->
          wow.get_history item.region,item.realm,item.type,item.name, (results) ->
            results.length.should.equal 1 
            # should.exist results[0].whats_changed
            results[0].whats_changed.overview.should.equal "NEW" 
            done()

    it "should be no history initially", (done) ->
      wow.get_history "eu", "Darkspear", "guild", "Mean Girls", (results) ->
        results.length.should.equal 0
        done()

    it "load static/real", (done) ->
      this.timeout(20000);
      wow.static_load()
      setTimeout done, 18000


    
