require "jasmine-node"

require "./store_mongo"

describe "mongo backed store", ->
  describe "save and load", ->

    store = null

    beforeEach ->
      store = new wf.StoreMongo

    afterEach ->
      store?.close()

    it "test1", ->

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