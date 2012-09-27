require "jasmine-node"

require "./store_mongo"

#todo - handle registered collection, of guilds/members, add/find
#todo - handle guilds/members collections, one each, holding history of object
#todo - handle guild/member history/audit collections, whats changed, ready for feed
#todo - are/can collections ordered?

describe "mongo backed store", ->
  describe "save and load", ->

    store = null

    beforeEach ->
      store = new wf.StoreMongo

    afterEach ->
      store?.close()

    it "test add/count db", ->

      someObj = 
        id: 123
        name: "foo"

      thatObj = null

      runs ->
        store.add "foo",someObj, ->
          wf.debug "store complete"
          store.load "foo", id: 123, (obj) -> thatObj = obj

      waitsFor (-> thatObj != null), 1000

      runs ->
        expect(thatObj.id).toEqual(someObj.id)
        expect(thatObj.name).toEqual(someObj.name)

      count = -1
      runs ->
        store.count "foo", someObj, (n) ->
          count = n

      waitsFor (-> count > -1), 1000

      runs ->
        expect(count).toEqual(1)
