require "jasmine-node"

require "./wowlookup"

describe "wow armory lookup", ->
  describe "get", ->
    it "valid", ->

      call_result = null

      runs ->
        wow = new wf.WowLookup()

        wow.get "guild", "eu", "Darkspear", "Mean Girls", (result) ->
          call_result = result

      waitsFor (-> call_result != null), 1000

      runs ->
        expect(call_result).toBeDefined()

        # expect(thatObj).toEqual(someObj)