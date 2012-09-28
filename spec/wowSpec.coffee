require "./commonSpec"

require "./wow"

describe "wow wrapper", ->
  describe "register", ->

    wow = null

    beforeEach ->
      wow = new wf.WoW()

    # afterEach ->
      # wow?.close()

    it "clear wow", ->

      #check none registered before
      # registered_elements = null
      # runs ->
      #   wow.get_registered (items) ->
      #     registered_elements = items
      # waitsFor (-> registered_elements != null), 1000
      # runs ->
      #   expect(registered_elements.length).toEqual(0)

      # clean
      clear_done = false
      runs ->
        wow.clear_registered ->
          clear_done = true
      waitsFor (-> clear_done), 1000
      runs -> expect(clear_done).toEqual(true)

      #check none registered after
      registered_elements = null
      runs ->
        wow.get_registered (items) ->
          registered_elements = items
      waitsFor (-> registered_elements != null), 1000
      runs ->
        expect(registered_elements.length).toEqual(0)



    it "add/check register", ->

      registered_ok = false

      runs ->
        wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
          registered_ok = true
      waitsFor (-> registered_ok), 1000
      runs ->
        expect(registered_ok).toEqual(true)

      registered_elements = null
      runs ->
        wow.get_registered (items) ->
          registered_elements = items
      waitsFor (-> registered_elements != null), 1000
      runs ->
        expect(registered_elements.length).toEqual(1)


    it "dont double register", ->

      registered_ok = false

      runs ->
        wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
          registered_ok = true
      waitsFor (-> registered_ok), 1000
      runs ->
        expect(registered_ok).toEqual(true)

      runs ->
        wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls", ->
          registered_ok = true
      waitsFor (-> registered_ok), 1000
      runs ->
        expect(registered_ok).toEqual(true)

      registered_elements = null
      runs ->
        wow.get_registered (items) ->
          registered_elements = items
      waitsFor (-> registered_elements != null), 1000
      runs ->
        expect(registered_elements.length).toEqual(1)


      runs ->
        wow.ensure_registered "eu", "Darkspear", "guild", "Mean Girls2", ->
          registered_ok = true
      waitsFor (-> registered_ok), 1000
      runs ->
        expect(registered_ok).toEqual(true)

      registered_elements = null
      runs ->
        wow.get_registered (items) ->
          registered_elements = items
      waitsFor (-> registered_elements != null), 1000
      runs ->
        expect(registered_elements.length).toEqual(2)

