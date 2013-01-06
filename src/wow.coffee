global.wf ||= {}


async = require "async"

require "./defaults"
require "./store_mongo"
require "./wowlookup"

require './init_logger'
require './calc_changes'
require './call_logger'

# this an in memory cache of the latest guild/char details
class wf.WoW

  store = new wf.StoreMongo()
  wowlookup = new wf.WowLookup()
  registered_collection = "registered"
  armory_collection = "armory_history"
  static_collection = "armory_static"
  calls_collection = "armory_calls"
  items_collection = "armory_items"
  realms_collection = "armory_realms"

  fields_to_select = {name:1,realm:1,region:1,type:1, lastModified:1, whats_changed:1, "armory.level":1, "armory.guild":1,"armory.news":1, "armory.feed":1, "armory.thumbnail":1, "armory.members":1, "armory.titles":1}

  static_index_1 = {id:1, static_type:1}
  registered_index_1 = {name:1, realm:1, region:1, type:1}
  registered_ttl_index_2 = { updated_at: 1 } 
  realms_index_1 = {name:1, slug:1, region:1}
  armory_index_1 = {name:1, realm:1, region:1, type:1, lastModified:1}
  armory_archived_ttl_index_2 = {archived_at:1}
  armory_accessed_ttl_index_3 = {accessed_at:1}
  armory_item_index_1 = {item_id:1}
  job_running_lock = false
  loader_queue = null
  armory_pending_queue = []
  item_loader_queue = null

  constructor: (callback)->
    wf.info "WoW constructor"
    new wf.CallLogger(this, wowlookup, store)
    store.create_collection calls_collection, capped:true, autoIndexId:false, size: 40000000, (err, result)=>
      wf.info "Created capped collection:#{calls_collection}. #{err}, #{result}"
      wf.wow ?= this
      callback?(this)

  get_loader_queue: ->
    loader_queue

  set_loader_queue: (queue) ->
    loader_queue = queue

  get_item_loader_queue: ->
    item_loader_queue

  set_item_loader_queue: (queue) ->
    item_loader_queue = queue

  get_armory_pending_queue: ->
    armory_pending_queue

  clear_armory_pending_queue: ->
    armory_pending_queue = []

  get_job_running_lock: ->
    job_running_lock

  set_job_running_lock: (running) ->
    job_running_lock = running

  get_collections: ->
    [armory_collection, calls_collection, registered_collection, items_collection, static_collection, realms_collection, wf.logs_collection]

  get_calls_collection: ->
    calls_collection

  get_armory_collection: ->
    armory_collection

  get_armory_index_1: ->
    armory_index_1

  get_armory_archived_ttl_index_2: ->
    armory_archived_ttl_index_2

  get_armory_accessed_ttl_index_3: ->
    armory_accessed_ttl_index_3

  get_registered_collection: ->
    registered_collection

  get_items_collection: ->
    items_collection

  get_realms_collection: ->
    realms_collection

  get_realms_index_1: ->
    realms_index_1

  get_static_collection: ->
    static_collection

  get_static_index_1: ->
    static_index_1

  ensure_registered: (region, realm, type, name, registered_handler) ->
    wf.debug "Registering #{name}"
    store.ensure_index registered_collection, registered_index_1, null, ->
      store.ensure_index registered_collection, registered_ttl_index_2, { unique: false, expireAfterSeconds: wf.REGISTERED_ITEM_TIMEOUT }, ->
        store.load registered_collection, {region,realm,type,name}, null, (doc) ->
          wf.info "ensure_registered:#{JSON.stringify(doc)}"
          if doc?
            wf.debug "Registered already: #{name}"
            store.update registered_collection, {region,realm,type,name}, $set: {updated_at:new Date()}, ->
              wf.debug "Registered #{name}, updated timestamp"
              registered_handler?(true)
          else
            wf.debug "Not Registered #{name}"
            armory_pending_queue.push {region, realm, type, name}
            wf.armory_load_requested = true # new item/guild, so do an armory load soon
            store.add registered_collection,{region,realm,type,name, updated_at:new Date()}, ->
              wf.debug "Now Registered #{name}"
              registered_handler?(false)

  get_store: ->
    store

  get_wowlookup: ->
    wowlookup

  get_registered: (registered_handler)->
    store.load_all registered_collection, {},  {sort: {"updated_at": -1}}, registered_handler

  clear_all: (cleared_handler) ->
    wf.debug "clear_all called"
    store.remove_all registered_collection, ->
      store.remove_all armory_collection, ->
        store.drop_collection calls_collection, ->
          store.remove_all items_collection, ->
            store.remove_all static_collection, cleared_handler


  clear_registered: (cleared_handler) ->
    store.remove_all registered_collection, cleared_handler

  get: (region, realm, type, name, result_handler) =>
    if type == "guild" or type == "member"
      @ensure_registered region, realm, type, name, ->
        @ensure_armory_indexes ->
          store.load armory_collection, {type, region, realm, name}, {sort: {"lastModified": -1}}, result_handler
    else
      result_handler?(null)


  get_loaded: (loaded_handler) ->
    @ensure_armory_indexes ->
      # store.load_all armory_collection, {}, {limit:wf.HISTORY_LIMIT,sort: {"lastModified": -1}}, loaded_handler
      store.load_all_with_fields armory_collection, {}, 
        fields_to_select,  
        {limit:wf.HISTORY_LIMIT, sort: {"lastModified": -1}}, loaded_handler

  ensure_armory_indexes: (callback)=>
    wf.debug "checking armory index/1"
    store.ensure_index armory_collection, armory_index_1, null, =>
      wf.debug "checking armory index/2"
      store.ensure_index armory_collection, armory_archived_ttl_index_2, { unique: false, expireAfterSeconds: wf.ARCHIVED_ITEM_TIMEOUT }, =>
        wf.debug "checking armory index/3"
        store.ensure_index armory_collection, armory_accessed_ttl_index_3, { unique: false, expireAfterSeconds: wf.ACCESSED_ITEM_TIMEOUT }, callback

  repatch_item_key: (item) ->
    item?.region+item?.realm+item?.type+item?.name

  repatch_results: (results, callback)  ->
    # assumed results are in descending time order ...
    previous_item_cache = {}
    for item in results
      if item.armory?
        # wf.debug "saving previous item:#{JSON.stringify(item.whats_changed)}"
        previous_item_cache[@repatch_item_key(item)] = item
      else
        previous_item = previous_item_cache[@repatch_item_key(item)]
        if previous_item?
          # for own name, value of previous_item.armory
            # wf.debug "armory item:#{name}"
          sanitised_changes = wf.makeCopy(previous_item.whats_changed)
          for own name, value of sanitised_changes.changes
            # wf.debug "checking if we have field:#{name}/#{previous_item.armory[name]}"
            unless previous_item.armory[name]?
              # wf.debug "we dont have field:#{name}, so deleting changes for it"
              delete sanitised_changes.changes[name]
          item.armory = wf.restore sanitised_changes, previous_item.armory
          # dont keep feed/news stuff from old entries - ideally should just do unique items on output... later perhaps 
          delete item.armory.feed if item.armory.feed?
          delete item.armory.news if item.armory.news?
          previous_item_cache[@repatch_item_key(item)] = item
    callback?(results)

  get_history: (region, realm, type, name, result_handler) =>
    @get_history_counted(region, realm, type, name, 1, result_handler)

  get_history_counted: (region, realm, type, name, counter, result_handler) =>
    if type == "guild" or type == "member"
      @ensure_registered region, realm, type, name, =>
        @ensure_armory_indexes =>
          @get_history_from_db region, realm, type, name, (results) =>
            if results? and results.length >0
              result_handler(results)
            else
              if counter < 30
                wf.info "wait for armory load to complete...#{counter}"
                setTimeout (=> @get_history_counted(region, realm, type, name, counter+1, result_handler)), 1000
              else
                result_handler?(null)
    else
      result_handler?(null)

  get_history_from_db: (region, realm, type, name, result_handler) =>
    selector = {type, region, realm, name}
    store.load_all_with_fields armory_collection, selector, fields_to_select, {limit:wf.HISTORY_LIMIT, sort: {"lastModified": -1}}, (results) =>
      if results? and results.length >0
        selector.lastModified = results[0].lastModified
        store.update armory_collection, selector, {$set:{accessed_at:new Date()}}, =>
          if type == "guild" # if its a guild, also query for guild members
            wf.debug "Got a guild, so also query for members..."
            selector = {type:"member", region, realm, "armory.guild.name":name}
            store.load_all_with_fields armory_collection, selector, fields_to_select, {limit:wf.HISTORY_LIMIT, sort: {"lastModified": -1}}, (members) =>
              store.update armory_collection, selector, {$set:{accessed_at:new Date()}}, =>
                for m in members
                  results.push m
                @repatch_results(results, result_handler)
          else
            @repatch_results(results, result_handler)
      else
        result_handler?(null)

  get_realms: (callback) ->
    store.load_all_with_fields realms_collection, {}, {name:1, region:1}, {sort:{name:1, region:1}}, callback

  load_items: (item_id_array, callback) ->
    if item_id_array? and item_id_array.length >0
      store.ensure_index items_collection, armory_item_index_1, {dropDups:true}, ->
        store.load_all items_collection, {item_id: {$in: item_id_array}}, null, (items) ->
          items_hash = {}
          for i in items
            items_hash[i.item_id] = i
          callback?(items_hash)
    else
      callback?({})


