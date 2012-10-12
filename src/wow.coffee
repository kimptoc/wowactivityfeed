global.wf ||= {}

require "./store_mongo"
require "./wowlookup"

require('./init_logger')
require('./calc_changes')


# this an in memory cache of the latest guild/char details
class wf.WoW

  store = new wf.StoreMongo()
  wowlookup = new wf.WowLookup()
  registered_collection = "registered"
  armory_collection = "armory_history"
  armory_index_1 = {lastModified:1, type:1, region:1, realm:1, name:1}
  job_running_lock = false

  constructor: ->
    wf.info "WoW constructor"

  ensure_registered: (region, realm, type, name, registered_handler) ->
    wf.debug "Registering #{name}"
    store.load registered_collection, {region,realm,type,name}, null, (doc) ->
      wf.info "ensure_registered:#{JSON.stringify(doc)}"
      if doc?
        wf.debug "Registered already: #{name}"
        registered_handler?(true)
      else
        wf.debug "Not Registered #{name}"
        wf.armory_load_requested = true # new item/guild, so do an armory load soon
        store.add registered_collection,{region,realm,type,name}, ->
          wf.debug "Now Registered #{name}"
          registered_handler?(false)

  get_store: ->
    store

  get_wowlookup: ->
    wowlookup

  get_registered: (registered_handler)->
    store.load_all registered_collection, {}, {}, registered_handler

  clear_all: (cleared_handler) ->
    wf.debug "clear_all called"
    store.remove_all registered_collection, ->
      store.remove_all armory_collection, cleared_handler

  clear_registered: (cleared_handler) ->
    store.remove_all registered_collection, cleared_handler

  get: (region, realm, type, name, result_handler) =>
    if type == "guild" or type == "member"
      @ensure_registered region, realm, type, name, ->
        store.ensure_index armory_collection, armory_index_1, ->
          store.load armory_collection, {type, region, realm, name}, {sort: {"lastModified": -1}}, result_handler
    else
      result_handler?(null)

  get_loaded: (loaded_handler) ->
    store.ensure_index armory_collection, armory_index_1, ->
      store.load_all armory_collection, {}, {limit:30,sort: {"lastModified": -1}}, loaded_handler

  get_history: (region, realm, type, name, result_handler) =>
    if type == "guild" or type == "member"
      @ensure_registered region, realm, type, name, ->
        store.ensure_index armory_collection, armory_index_1, ->
          store.load_all armory_collection, {type, region, realm, name}, {limit:30, sort: {"lastModified": -1}}, result_handler
    else
      result_handler?(null)

  armory_load: (loaded_callback) =>
    wf.info "armory_load..."
    return if job_running_lock # only run one at a time....
    job_running_lock = true
    @get_registered (results_array) =>
      expected_responses = results_array.length
      wf.debug "expected_responses:#{expected_responses}"
      callback_done = false
      for item in results_array
        wf.debug "About to do Armory lookup for:#{JSON.stringify(item)}"
        wowlookup.get item.type, item.region, item.realm, item.name, (info) =>
          expected_responses -= 1
          wf.debug "expected_responses:#{expected_responses}"
          wf.info "Info back for #{info.name}, members:#{info?.members?.length}"
          @store_update info, =>
            # loaded_callback?(info)
            if info.type == "guild" and info?.members?
              expected_responses += info.members.length
              wf.debug "expected_responses:#{expected_responses}"
              for member in info.members
                wowlookup.get "member", info.region, info.realm, member.character.name, (member_info) =>
                  expected_responses -= 1
                  wf.debug "expected_responses:#{expected_responses}"
                  wf.info "Info back for guild #{item.name} member #{member.character.name}"
                  @store_update member_info, ->
                      # loaded_callback?(member_info)
                    if expected_responses == 0 and ! callback_done
                      callback_done = true
                      wf.debug "Got all responses (members), callback time"
                      job_running_lock = false
                      loaded_callback?(member_info)
            if expected_responses == 0 and ! callback_done
              callback_done = true
              wf.debug "Got all responses (guild), callback time"
              job_running_lock = false
              loaded_callback?(info)
    "In progress..."

  store_update: (info, stored_handler) => 
    # find prev entry
    # is it same one, if so done- nowt to do
    # if not same, calc diff, then save it
    store.ensure_index armory_collection, armory_index_1, ->
      store.load armory_collection,
        region : info.region
        realm : info.realm
        type : info.type
        name : info.name, {sort: {"lastModified": -1}}, (doc) ->
          wf.debug "store_update:#{JSON.stringify(doc)}"
          if doc? and doc.lastModified == info.lastModified
            wf.debug "Ignored as saved already: #{info.name}"
            stored_handler?()
          else
            wf.debug "Not saved #{info.name}"
            whats_changed = wf.calc_changes(doc, info)
            info.whats_changed = whats_changed
            store.add armory_collection, info, ->
                wf.debug "Now saved #{info.name}"
                stored_handler?()

