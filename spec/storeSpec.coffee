require "jasmine-node"

require "./store"

describe "simple file store", ->
  describe "save and load", ->
    it "test1", ->
      store = new wf.Store

      someObj = 
        id: 123
        name: "foo"

      store.add "foo",someObj, ->
        console.log "store complete"
        thatObj = store.load "foo"

        console.log "reloaded obj:"
        console.log thatObj

        expect(thatObj).toEqual(someObj)