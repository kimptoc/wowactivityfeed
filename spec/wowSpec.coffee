should = require 'should'
sinon = require 'sinon'

require "./commonSpec"
require './init_logger'

require "./wow"
require "./wow_loader"

describe "wow wrapper:", ->
  describe "register:", ->

    wow = null
    mock_store = null
    mock_lookup = null

    beforeEach (done)->
      wf.info "wowSpec:beforeEach"
      wow = new wf.WoW (wow)->
        wow.clear_all ->
          done()

    afterEach ->
      mock_store.verify() if mock_store?
      mock_lookup.verify() if mock_lookup?

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
      mock_store.expects("ensure_index").twice().yields()
      wow.ensure_registered {region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}, ->
        wow.get_registered (items) ->
          items.length.should.equal 1
          done()

    it "dont double register", (done)->
      wow.ensure_registered {region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}, ->
        wow.ensure_registered {region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}, ->
          wow.get_registered (items) ->
            items.length.should.equal 1
            wow.ensure_registered {region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls2"}, ->
              wow.get_registered (items) ->
                items.length.should.equal 2
                done()

    # getting too big to test, need to break it down
    # it "armory load/valid guild/new/mock", (done) ->
    #   mock_lookup = sinon.mock(wow.get_wowlookup())
    #   mock_lookup.expects("get").twice().yields
    #     region:"eu"
    #     realm:"Darkspear"
    #     type:"guild"
    #     name:"Mean Girls"
    #     members:
    #       [character:
    #         region:"eu"
    #         realm:"Darkspear"
    #         type:"member"
    #         name:"Kimptoc" ]
    #   mock_store = sinon.mock(wow.get_store())
    #   mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}])
    #   mock_store.expects("ensure_index").thrice().yields()
    #   mock_store.expects("load").exactly(4).yields()
    #   mock_store.expects("insert").twice().yields()
    #   mock_store.expects("add").twice().yields() # guild and members
    #   mock_store.expects("update").never()

    #   wowload = new wf.WoWLoader(wow)
    #   wow.armory_load ->
    #     done()


            #TODO too complicated - need to simplify it all!
#    it "armory load/valid guild/update, no change", (done) ->
#      mock_lookup = sinon.mock(wow.get_wowlookup())
#      mock_lookup.expects("get").twice().yields
#        region:"eu"
#        realm:"Darkspear"
#        type:"guild"
#        name:"Mean Girls"
#        lastModified:123
#        members:
#          [character:
#            region:"eu"
#            realm:"Darkspear"
#            type:"member"
#            name:"Kimptoc"
#            lastModified:123
#          ]
#      mock_store = sinon.mock(wow.get_store())
#      mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}])
#      mock_store.expects("ensure_index").thrice().yields()
#      mock_store.expects("load").thrice().yields({lastModified:123})
#      mock_store.expects("add").once()
#      mock_store.expects("update").never()
#
#      wowload = new wf.WoWLoader(wow)
#      wowload.armory_load ->
#        done()

    it "armory realms load", (done) ->
     @timeout(20000)
     wowload = new wf.WoWLoader(wow)
     wowload.realms_loader (realms)->
       realms.length.should.be.above 10
       done()

#    it "armory races load", (done) ->
#     @timeout(20000)
#     wowload = new wf.WoWLoader(wow)
#     wowload.races_loader (races)->
#       races.length.should.be.above 5
#       done()
#
#    it "armory classes load", (done) ->
#     @timeout(20000)
#     wowload = new wf.WoWLoader(wow)
#     wowload.classes_loader (classes)->
#       classes.length.should.be.above 5
#       done()

    it "static load", (done) ->
     @timeout(20000)
     wowload = new wf.WoWLoader(wow)
     wowload.static_loader ->
       done()

    #TODO - simplify
#    it "armory load/valid guild/update, with change", (done) ->
#      mock_lookup = sinon.mock(wow.get_wowlookup())
#      mock_lookup.expects("get").twice().yields
#        region:"eu"
#        realm:"Darkspear"
#        type:"guild"
#        name:"Mean Girls"
#        lastModified:124
#        members:
#          [character:
#            region:"eu"
#            realm:"Darkspear"
#            type:"member"
#            name:"Kimptoc"
#            lastModified:125
#          ]
#      mock_store = sinon.mock(wow.get_store())
#      mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}])
#      mock_store.expects("ensure_index").thrice().yields()
#      mock_store.expects("load").twice().yields({lastModified:122})
#      mock_store.expects("add").twice().yields()
#      mock_store.expects("update").twice().yields()
#
#      wowload = new wf.WoWLoader(wow)
#      wowload.armory_load ->
#        done()

        #TODO - simplify
#    it "armory load/invalid guild/new", (done) ->
#      mock_lookup = sinon.mock(wow.get_wowlookup())
#      mock_lookup.expects("get").once().yields
#        region:"eu"
#        realm:"Darkspear"
#        type:"guild"
#        name:"Mean Girls"
#        error: "not found"
#      mock_store = sinon.mock(wow.get_store())
#      mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"guild", name:"Mean Girls"}])
#      mock_store.expects("ensure_index").twice().yields()
#      mock_store.expects("load").once().yields()
#      mock_store.expects("add").once().yields() # guild
#
#      wowload = new wf.WoWLoader(wow)
#      wowload.armory_load ->
#        done()

    #TODO fix/simplify
#    it "armory load/valid member", (done) ->
#      mock_lookup = sinon.mock(wow.get_wowlookup())
#      mock_lookup.expects("get").once().yields
#        region:"eu"
#        realm:"Darkspear"
#        type:"member"
#        name:"Mean Girls"
#      mock_store = sinon.mock(wow.get_store())
#      mock_store.expects("load_all").once().yields([{region:"eu", realm:"Darkspear", type:"member", name:"Mean Girls"}])
#      mock_store.expects("ensure_index").twice().yields()
#      mock_store.expects("load").once().yields()
#      mock_store.expects("add").once().yields() # member
#
#      wowload = new wf.WoWLoader(wow)
#      wowload.armory_load ->
#        done()

    it "try item_loader", (done) ->
      wowload = new wf.WoWLoader(wow)
      wowload.item_loader {item_id:87417, locale:'en_GB', region:'eu'}, ->
        done()

    it "basic get when none", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        lastModified: 123
        locale:"en_GB"
      wow.get item.region,item.realm,item.type,item.name,item.locale, (result) ->
        wf.debug "back from get"
        # todo - should.not.exist result
        done()

#    it "basic get_history when none", (done) ->
#      item =
#        type: "guild"
#        region: "eu"
#        realm: "wwewe"
#        locale:"en_GB"
#        name: "test"
#        lastModified: 123
#      wow.get_history item.region, item.realm, item.type, item.name, item.locale, (results) ->
#        wf.debug "back from get_history"
#        results.length.should.equal 0
#        done()

    it "try store update 1", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        locale:"en_GB"
        lastModified: 123
      wowload = new wf.WoWLoader(wow)
      wowload.store_update item.type, item.region, item.realm, item.name, item.locale, item, ->
        wow.get_history item.region, item.realm, item.type, item.name,item.locale, (results) ->
          results.length.should.equal 1 
          # should.exist results[0].whats_changed
          results[0].whats_changed.overview.should.equal "NEW"
          wow.get item.region,item.realm,item.type,item.name,item.locale, (result) ->
            # should.exist result
            wf.debug "result:#{JSON.stringify(result)}"
            result.name.should.equal "test"
            done()

    it "try store update guild+", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        locale:"en_GB"
        lastModified: 123
      item_member =
        type: "member"
        region: "eu"
        realm: "wwewe"
        name: "test_mem"
        locale:"en_GB"
        lastModified: 123
        guild:
          name: "test"
      wowload = new wf.WoWLoader(wow)
      wowload.store_update item.type, item.region, item.realm, item.name, item.locale, item, ->
        wowload.store_update item_member.type, item_member.region, item_member.realm, item_member.name, item_member.locale, item_member, ->
          wow.get_history item.region, item.realm, item.type, item.name, item.locale, (results) ->
            wf.info "first item:#{results[0].type}/#{results[0].name}"
            setInterval( ->
            results.length.should.equal 2
            # should.exist results[0].whats_changed
            results[0].whats_changed.overview.should.equal "NEW"
            done(), 1000)

    it "try store update member", (done) ->
      item =
        type: "member"
        region: "eu"
        realm: "wwewe"
        name: "test_mem"
        locale:"en_GB"
        lastModified: 123
      wowload = new wf.WoWLoader(wow)
      wowload.store_update item.type, item.region, item.realm, item.name, item.locale, item, ->
        wow.get_history item.region, item.realm, item.type, item.name,item.locale, (results) ->
          results.length.should.equal 1
          # should.exist results[0].whats_changed
          results[0].whats_changed.overview.should.equal "NEW"
          done()

    it "try store update 2diff", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        locale:"en_GB"
        lastModified: 123
      item2 =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        name: "test"
        locale:"en_GB"
        lastModified: 124
      wowload = new wf.WoWLoader(wow)
      wowload.store_update item.type, item.region, item.realm, item.name,item.locale, item, ->
        wowload.store_update item2.type, item2.region, item2.realm, item2.name,item2.locale, item2, ->
          wow.get_history item.region,item.realm,item.type,item.name,item.locale, (results) ->
            results.length.should.equal 2 
            results[0].lastModified.should.equal 124
            results[1].lastModified.should.equal 123
            # should.exist results[0].whats_changed
            wf.info JSON.stringify(results)
            results[0].whats_changed.overview.should.equal "UPDATE"
            results[0].whats_changed.changes.should.eql lastModified: [123, 124]
            done()

    it "try store update 2same", (done) ->
      item =
        type: "guild"
        region: "eu"
        realm: "wwewe"
        locale:"en_GB"
        name: "test"
        lastModified: 123
      wowload = new wf.WoWLoader(wow)
      wowload.store_update item.type, item.region, item.realm, item.name, item.locale, item, ->
        wowload.store_update item.type, item.region, item.realm, item.name, item.locale, item, ->
          wow.get_history item.region,item.realm,item.type,item.name,item.locale, (results) ->
            results.length.should.equal 1 
            # should.exist results[0].whats_changed
            results[0].whats_changed.overview.should.equal "NEW" 
            done()

    #TODO fix/simplify - now retries
#    it "should be no history initially", (done) ->
#      wow.get_history "eu", "Darkspear", "guild", "Mean Girls", (results) ->
#        results.length.should.equal 0
#        done()

    # static disabled at the moment, takes up space and not used....
    # it "load static/real", (done) ->
    #   this.timeout(20000);
    #   wow.static_load()
    #   setTimeout done, 18000


    
