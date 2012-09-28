require "./commonSpec"

require "./store_mongo"

#todo - handle registered collection, of guilds/members, add/find
#todo - handle guilds/members collections, one each, holding history of object
#todo - handle guild/member history/audit collections, whats changed, ready for feed
#todo - are/can collections ordered?

describe "mongo backed store", ->
  describe "save and load", ->

    store = null

    beforeEach ->
      wf.info "Running beforeEach, create StoreMongo"
      store = new wf.StoreMongo()

    # afterEach ->
      # wf.info "Running afterEach, close StoreMongo"
      # store?.close()

    it "test call remove all", ->

      removed = false

      runs -> 
        store.remove_all "foo", ->
          removed = true
      waitsFor (-> removed ), "removed wait",1000
      runs ->
        expect(removed).toEqual(true) 

    it "test add/count db", ->

      removed = false

      runs -> 
        store.remove_all "foo", ->
          removed = true
      waitsFor (-> removed ), "removed wait", 1000
      runs ->
        expect(removed).toEqual(true) 


      count = -1
      runs ->
        store.count "foo", someObj, (n) -> count = n
      waitsFor (-> count > -1),"count wait", 1000
      runs -> expect(count).toEqual(0)

      someObj = 
        id: 123
        name: "foo"

      thatObj = null

      add_count = -1
      runs ->
        store.add "foo",someObj, (counter)->
          wf.debug "store complete, #{counter}"
          add_count = counter
          store.load "foo", id: 123, (obj) -> thatObj = obj
      waitsFor (-> thatObj != null),"thatObj wait", 1000
      runs ->
        expect(thatObj).toBeDefined()
        expect(thatObj.id).toEqual(someObj.id)
        expect(thatObj.name).toEqual(someObj.name)
        expect(add_count).toEqual(1)


# TODO - work out why this doesnt work :(
      # count = -1
      # runs ->
      #   store.count "foo", someObj, (n) -> count = n
      # waitsFor (-> count > -1), 1000
      # runs -> expect(count).toEqual(1)

      elements_found = null
      runs ->
        store.load_all "foo", (matching) ->
          elements_found = matching
      waitsFor (-> elements_found != null),"elements_found wait", 1000
      runs ->
        expect(elements_found.length).toEqual(1)
