global.wf ||= {}

require "./store_mongo"
require "./wowlookup"

require('./init_logger')


# this an in memory cache of the latest guild/char details
class wf.WoW

  store = new wf.StoreMongo()
  wowlookup = new wf.WowLookup()
  registered_collection = "registered"

  constructor: ->
    wf.info "WoW constructor"

  get_hash: (h, key) ->
    val = h[key]
    if ! val
      val = {}
      h[key] = val
    return val 

  # close: ->
    # store?.close()

  ensure_registered: (region, realm, type, name, registered_handler) ->
    wf.debug "Registering #{name}"
    store.load registered_collection,
      region : region
      realm : realm
      type : type
      name : name, (doc) ->
        wf.info "ensure_registered:#{JSON.stringify(doc)}"
        if doc?
          wf.debug "Registered already: #{name}"
          registered_handler?()
        else
          wf.debug "Not Registered #{name}"
          store.add registered_collection,
            region : region
            realm : realm
            type : type
            name : name, ->
              wf.debug "Now Registered #{name}"
              registered_handler?()

  get_registered: (registered_handler)->
    store.load_all registered_collection, (results) ->
      registered_handler?(results)

  clear_registered: (cleared_handler) ->
    store.remove_all registered_collection, cleared_handler

  get: (region, realm, type, name, result_handler) =>
    if type == "guild" or type == "member"
      @ensure_registered(region, realm, type, name)
      store.load @get_coll_name(type, region, realm, name), name: name, (info) ->
        result_handler(info)
    else
      result_handler(null)

  armory_load: =>
    wf.info "armory_load..."
    @get_registered (results_array) =>
      for item in results_array
        wf.info JSON.stringify(item)
        wowlookup.get item.type, item.region, item.realm, item.name, (info) =>
          wf.info "Info back for #{item.name}"
          coll_name = @get_coll_name(item.type, item.region, item.realm, item.name)
          store.add coll_name, info
    "In progress..."

  get_coll_name: (type, region_name, realm_name, item) ->
    return "#{type}:#{region_name}:#{realm_name}:#{item}"
