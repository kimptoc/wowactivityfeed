should = require 'should'
require "./commonSpec"

require "./store_mongo"

#todo - handle registered collection, of guilds/members, add/find
#todo - handle guilds/members collections, one each, holding history of object
#todo - handle guild/member history/audit collections, whats changed, ready for feed
#todo - are/can collections ordered?

describe "mongo backed store:", ->
  describe "save and load:", ->

    store = null

    beforeEach ->
      wf.info "Running beforeEach, create StoreMongo"
      store = new wf.StoreMongo()

    # afterEach ->
      # wf.info "Running afterEach, close StoreMongo"
      # store?.close()

    it "just clear all", (done) ->
      store.clear_all (was_clear_done)->
        was_clear_done.should.equal true
        done()

#TODO - why this is not working, it used to...
    it "add item then clear all", (done) ->
      someObj =
        id: 123
        name: "foo"

      store.add "foo",someObj, (counter)->
        wf.debug "store complete, #{counter}"
        counter.should.equal 1
        store.clear_all (was_clear_done)->
          was_clear_done.should.equal true
          store.count "foo", someObj, (n) ->
            n.should.equal 0
            done()

    it "test call remove all", (done) ->

      store.remove_all "foo", ->
        done()

    it "test add/count db", (done) ->

      store.remove_all "foo", ->

        someObj =
          id: 123
          name: "foo"

        store.count "foo", someObj, (n) ->
          n.should.equal 0

          thatObj = null

          store.add "foo",someObj, (counter)->
            wf.debug "store complete, #{counter}"
            counter.should.equal 1
            store.load "foo", id: 123, {}, (obj) ->
              thatObj = obj
              should.exist thatObj
              thatObj.id.should.equal someObj.id
              thatObj.name.should.equal someObj.name

              store.count "foo", someObj, (n) ->
                n.should.equal 1

                store.load_all "foo", (matching) ->
                  wf.debug "matching.length:#{matching.length}"
                  matching.length.should.equal 1
                  done()

    it "check order of results", (done) ->
      store.remove_all "bar", ->
        obj1 =
          id: 123
          name: "one"
        obj2 = 
          id: 123
          name: "two"
        store.add "bar", obj1, (counter) ->
          # counter.should.equal 1
          store.add "bar", obj2, (counter) ->
            # todo - this should work...
            # counter.should.equal 2
            store.load "bar", id: 123,  {sort: {'name': 1} }, (doc)->
              should.exist doc
              doc.name.should.equal "one"
              store.load "bar", id: 123, {sort: {'name': -1} }, (doc)->
                should.exist doc
                doc.name.should.equal "two"
                done()

