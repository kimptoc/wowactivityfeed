global.wf ||= {}

require "./store_mongo"
require "./wowlookup"

require('./init_logger')


# this an in memory cache of the latest guild/char details
class wf.WoW

  store = new wf.StoreMongo()
  wowlookup = new wf.WowLookup()
  registered = {}
  registered_collection = "registered"

  get_hash: (h, key) ->
    val = h[key]
    if ! val
      val = {}
      h[key] = val
    return val 

  # close: ->
    # store?.close()

  ensure_registered: (region, realm, type, name, registered_handler) ->
    store.load registered_collection,
      region : region
      realm : realm
      type : type
      name : name, (doc) ->
        if doc?
          registered_handler?()
        else
          store.add registered_collection,
              region : region
              realm : realm
              type : type
              name : name, ->
                registered_handler?()
    # h_type = @get_hash registered, type
    # h_region = @get_hash h_type, region
    # a_realm = h_region[realm]
    # if ! a_realm
    #   a_realm = []
    #   h_region[realm] = a_realm 
    # a_realm.push(name) if ! (name in a_realm)
    # wf.debug "a_realm:#{JSON.stringify(a_realm)}"
    # registered[type][region][realm][name] = true

  get_registered: (registered_handler)->
    store.load_all registered_collection, (results) ->
      registered_handler?(results)

  clear_registered: (cleared_handler) ->
    store.remove_all registered_collection, cleared_handler

  get: (region, realm, type, name) ->
    if type == "guild" or type == "member"
      @ensure_registered(region, realm, type, name)
      store.load name
    else
      null

  armory_load: ->
    wf.info "armory_load..."
    for type, region of registered
      wf.debug "Processing type #{type}"
      for region_name, realm of region
        wf.debug "Processing region #{region_name}"
        for realm_name, items of realm
          wf.debug "Processing realm #{realm_name}"
          for item in items
            wf.debug "Processing item #{item}"
            wowlookup.get type, region_name, realm_name, item
    "TBD"
