should = require 'should'
assert = require 'assert'

require "./commonSpec"

require "./store_mongo"

#todo - handle registered collection, of guilds/members, add/find
#todo - handle guilds/members collections, one each, holding history of object
#todo - handle guild/member history/audit collections, whats changed, ready for feed
#todo - are/can collections ordered?

describe "mongo backed store:", ->
  describe "save and load:", ->

    store = null

    beforeEach (done) ->
      wf.info "Running beforeEach, create StoreMongo"
      store = new wf.StoreMongo()
      # store.clear_all ->
      store.remove_all "foo", ->
        store.remove_all "bar", ->
          done()

    # afterEach ->
      # wf.info "Running afterEach, close StoreMongo"
      # store?.close()

    it "just clear all and count", (done) ->
      someObj =
        id: 123
        name: "foo"
      store.remove_all "foo", ->
      # store.clear_all (was_clear_done)->
        # was_clear_done.should.equal true
        store.count "foo", someObj, (n) ->
          n.should.equal 0
          done()

    it "add item then count", (done) ->
      someObj =
        id: 123
        name: "foo"

      store.add "foo",someObj, (counter)->
        wf.debug "store complete, #{counter}"
        counter.should.equal 1
        done()

    it "upsert item then count", (done) ->
      someObj =
        id: 467
        name: "foo1"

      store.upsert "foo",id:someObj.id,someObj, (counter) ->
        wf.debug "store complete, #{counter}"
        counter.should.equal 1
        someObj.name = "foo2"
        store.upsert "foo", id:someObj.id, someObj, (counter) ->
          counter.should.equal 1
          done()

    it "add then update via $unset", (done) ->
      someObj =
        id: 123
        name: "foo"
        colours:
          one:"blue"
          two:"red"

      store.add "foo",someObj, (counter)->
        wf.debug "store complete, #{counter}"
        should.exist someObj.colours
        counter.should.equal 1
        store.update "foo", id: 123, { $unset: {"colours",1} }, ->
          store.load "foo", id: 123, {}, (obj) ->
            should.not.exist obj.colours
            done()

    it "add then remove", (done) ->
      someObj =
        id: 123
        name: "foo"
        colours:
          one:"blue"
          two:"red"

      store.add "foo",someObj, (counter)->
        wf.debug "store complete, #{counter}"
        counter.should.equal 1
        store.remove "foo", id: 123, ->
          store.load "foo", id: 123, {}, (obj) ->
            should.not.exist obj
            done()

    it "add then update whole object by key", (done) ->
      someObj =
        id: 123
        name: "foo"
        colours:
          one:"blue"
          two:"red"

      store.ensure_index "foo", {name: 1}, ->
        store.add "foo",someObj, (counter)->
          wf.debug "store complete, #{counter}"
          counter.should.equal 1
          someObj.name = "foo2"
          someObj.id = 234
          store.update "foo", id: 123, someObj, ->
            store.load "foo", id: 234, {}, (obj) ->
              obj.name.should.equal "foo2"
              done()

    it "add item then clear all", (done) ->
      someObj =
        id: 123
        name: "foo"

      store.add "foo",someObj, (counter)->
        wf.debug "store complete, #{counter}"
        counter.should.equal 1
        store.remove_all "foo", ->
          store.count "foo", someObj, (n) ->
            n.should.equal 0
            done()

    it "test call remove all", (done) ->

      store.remove_all "foo", ->
        done()

    it "basic load_all", (done) ->
      store.load_all "foo", {}, {}, (docs) ->
        docs.length.should.equal 0
        done()

    it "ensure index basic", (done) ->
      store.ensure_index "foo", {a:1}, ->
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
              # should.exist thatObj
              assert thatObj
              thatObj.id.should.equal someObj.id
              thatObj.name.should.equal someObj.name

              store.count "foo", someObj, (n) ->
                n.should.equal 1

                store.load_all "foo", {}, {}, (matching) ->
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
              # should.exist doc
              assert doc
              doc.name.should.equal "one"
              store.load "bar", id: 123, {sort: {'name': -1} }, (doc)->
                # should.exist doc
                assert doc
                doc.name.should.equal "two"
                done()

