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
        wf.debug "store complete"
        thatObj = store.load "foo"

        wf.debug "reloaded obj:"
        wf.debug thatObj

        expect(thatObj).toEqual(someObj)