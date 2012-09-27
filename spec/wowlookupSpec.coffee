require "./commonSpec"

require "./wowlookup"

describe "wow armory lookup", ->
  describe "get", ->
    it "valid armory lookup", ->

      call_result = null

      runs ->
        wow = new wf.WowLookup()

        wow.get "guild", "eu", "Darkspear", "Mean Girls", (result) ->
          call_result = result

      waitsFor (-> call_result != null), 3000

      runs ->
        expect(call_result).toBeDefined()

        # expect(thatObj).toEqual(someObj)