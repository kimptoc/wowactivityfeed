require "jasmine-node"

require "./store"

describe "simple file store", ->
  describe "save and load", ->
    it "test1", ->
      store = new wf.Store

      expect(1).toEqual(1)

      someObj = 
        id: 123
        name: "foo"

      thatObj = null

      runs ->
        store.add "foo",someObj, ->
          wf.debug "store complete"
          thatObj = store.load "foo"

          wf.debug "reloaded obj:"
          wf.debug thatObj

      waitsFor (-> thatObj != null), 1000

      runs ->
        expect(thatObj).toEqual(someObj)