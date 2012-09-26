require "jasmine-node"

require "./wowlookup"

describe "wow armory lookup", ->
  describe "get", ->
    it "valid", ->
      wow = new wf.WowLookup()

      wow.get "guild", "eu", "Darkspear", "Mean Girls", (result) ->
        expect(result).toBeDefined()

        # expect(thatObj).toEqual(someObj)