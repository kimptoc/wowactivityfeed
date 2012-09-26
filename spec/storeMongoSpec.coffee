require "jasmine-node"

require "./store_mongo"

describe "mongo backed store", ->
  describe "save and load", ->
    it "test1", ->
      store = new wf.StoreMongo

      someObj = 
        id: 123
        name: "foo"

      store.add "foo",someObj, ->
        console.log "store complete"
        thatObj = store.load "foo", id: 123

        console.log "reloaded obj:"
        console.log thatObj

        expect(thatObj).toEqual(someObj)