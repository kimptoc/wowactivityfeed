should = require 'should'
require "./commonSpec"

require "./store"

describe "simple file store:", ->
  describe "save and load:", ->
    it "test1", (done) ->
      store = new wf.Store

      someObj =
        id: 123
        name: "foo"

      thatObj = null

      store.add "foo",someObj, ->
        wf.debug "store complete"
        thatObj = store.load "foo"

        wf.debug "reloaded obj:"
        wf.debug thatObj

        thatObj.should.eql someObj
        done()

