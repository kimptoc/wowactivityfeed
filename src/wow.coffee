global.wf ||= {}

startup_time = new Date().getTime()

async = require "async"
moment = require "moment"

require "./defaults"
require "./store_mongo"
require "./wowlookup"
require './feed_item_formatter'

require('./init_logger')
require('./calc_changes')


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

  registered_index_1 = {name:1, realm:1, region:1, type:1}
  registered_ttl_index_2 = { updated_at: 1 } 
  armory_index_1 = {name:1, realm:1, region:1, type:1, lastModified:1}
  realms_index_1 = {slug:1, region:1}
  armory_archived_ttl_index_2 = {archived_at:1}
  armory_accessed_ttl_index_3 = {accessed_at:1}
  armory_static_index_1 = {static_type:1, id:1}
  armory_item_index_1 = {item_id:1}
  job_running_lock = false
  loader_queue = null
  armory_pending_queue = []
  item_loader_queue = null
  feed_formatter = null

  constructor: (callback)->
    wf.info "WoW constructor"
    feed_formatter = new wf.FeedItemFormatter()
    item_loader_queue = async.queue(@item_loader, wf.ITEM_LOADER_THREADS)
    store.create_collection calls_collection, capped:true, autoIndexId:false, size: 40000000, (err, result)=>
      wf.info "Created capped collection:#{calls_collection}. #{err}, #{result}"
      wf.wow ?= this
      callback?(this)

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

  armory_calls_old: (callback)->
    info = 
      startup_time: moment(startup_time).format('H:mm:ss ddd')
      total_calls: 0
      total_errors: 0
      total_not_modified: 0
      total_by_type: {}
      todays_calls: 0
      todays_errors: 0
      todays_not_modified: 0
      todays_by_type: {}
      earliest: Infinity
      latest: 0
      error_summary :{}
      memory_usage: process.memoryUsage()
      node_uptime: process.uptime()
      armory_load:
        armory_load_running: job_running_lock
        number_running: loader_queue?.running() 
        number_queued: loader_queue?.length()
      item_loader_queue:
        number_running: item_loader_queue?.running()
        number_queued: item_loader_queue?.length()
    store.dbstats [armory_collection, calls_collection, registered_collection, items_collection, wf.logs_collection], (stats) ->
      info.db = stats      
      store.load_all calls_collection, {}, {}, (entries) ->
        for call in entries
          info.earliest = call.start_time if call.start_time < info.earliest
          info.latest = call.start_time if call.start_time > info.latest
          info.total_calls += 1
          if call.had_error
            info.total_errors += 1 
            info["error_summary"][call.error] ?= 0 
            info["error_summary"][call.error] += 1
          info.total_not_modified += 1 if call.not_modified
          info.total_by_type[call.type] ?= 0
          info.total_by_type[call.type] += 1
          if moment().sod().format("DDD") == moment(call.start_time).format("DDD")
            info.todays_calls += 1
            info.todays_errors += 1 if call.had_error
            info.todays_not_modified += 1 if call.not_modified
            info.todays_by_type[call.type] ?= 0
            info.todays_by_type[call.type] += 1
        info.earliest = moment(info.earliest).format('H:mm:ss ddd')
        info.latest = moment(info.latest).format('H:mm:ss ddd')
        callback?(info)

  armory_calls: (callback)->
    info = 
      startup_time: moment(startup_time).format('H:mm:ss ddd')
      memory_usage: process.memoryUsage()
      node_uptime: process.uptime()
      armory_load:
        armory_load_running: job_running_lock
        number_running: loader_queue?.running() 
        number_queued: loader_queue?.length()
      item_loader_queue:
        number_running: item_loader_queue?.running()
        number_queued: item_loader_queue?.length()
    store.dbstats [armory_collection, calls_collection, registered_collection, items_collection, wf.logs_collection], (stats) ->
      info.db = stats      
      # > db.armory_history.aggregate( {$group : { _id:"$name", count:{$sum:1}}})
      start_of_day = moment().sod().valueOf()
      twohours_ago = moment().subtract({hours:2}).valueOf()
      store.aggregate calls_collection, 
        [
          { $project: 
            type: 1
            start_time: 1
            error: 1
            errors:{$cmp: ["$had_error", false]}
            not_modifieds:{$cmp: ["$not_modified", false]}
            date_category:{$cond:[{$gte:["$start_time", twohours_ago]},"last-2hours", $cond:[{$gte:["$start_time", start_of_day]},"today","before-today"]]}
          },
          { $group : 
            # _id: "$type"
            # _id:{ error:"$error", type:"$type"}
            _id:{ date_category:"$date_category", type:"$type", error:"$error"}
            totalByType:{ $sum:1 }
            earliest: {$min: "$start_time"}
            latest: {$max: "$start_time"}
            errors: {$sum: "$errors"} 
            not_modified: {$sum :"$not_modifieds"}
          }
        ], 
        {}, 
        (results) ->
          if results?
            results2 = {}
            for type_stat in results
              type_stat.earliest = moment(type_stat.earliest).format("H:mm:ss ddd")
              type_stat.latest = moment(type_stat.latest).format("H:mm:ss ddd")
              results2[type_stat._id.date_category] ?= {}
              if type_stat._id.error?
                key = type_stat._id.type + "/" + type_stat._id.error + "-" + type_stat.earliest + " - " + type_stat.latest
                total = type_stat.errors
                results2[type_stat._id.date_category][key] = total
              else
                key = type_stat._id.type + "-" + type_stat.earliest + " - " + type_stat.latest
                total = type_stat.totalByType
                results2[type_stat._id.date_category][key] = total
                key = type_stat._id.type + "/" + "not-modified" + "-" + type_stat.earliest + " - " + type_stat.latest
                total = type_stat.not_modified
                results2[type_stat._id.date_category][key] = total
            # info.aggregate = results
            info.aggregate_calls = results2
          callback?(info)

  get_loaded: (loaded_handler) ->
    @ensure_armory_indexes ->
      # store.load_all armory_collection, {}, {limit:wf.HISTORY_LIMIT,sort: {"lastModified": -1}}, loaded_handler
      store.load_all_with_fields armory_collection, {}, 
        fields_to_select,  
        {limit:wf.HISTORY_LIMIT, sort: {"lastModified": -1}}, loaded_handler

  ensure_armory_indexes: (callback)->
    store.ensure_index armory_collection, armory_index_1, null, ->
      store.ensure_index armory_collection, armory_archived_ttl_index_2, { unique: false, expireAfterSeconds: wf.ARCHIVED_ITEM_TIMEOUT }, ->
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
    if type == "guild" or type == "member"
      @ensure_registered region, realm, type, name, =>
        @ensure_armory_indexes =>
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
    else
      result_handler?(null)

  static_load: =>
    # load achievements
    try 
      @save_achievements("characterAchievements")
      @save_achievements("guildAchievements")
    catch e
      wf.error "static_load:#{e}"

  save_achievements: (name) ->
    wowlookup.get_static name, "eu", (achievements) ->
      # data returned is quite structured - so flatten it out to save it
      # go through all groups
      return unless achievements?
      for achievementGroup in achievements
        # get groups categories
        if achievementGroup.achievements?
          for groupAchievement in achievementGroup.achievements
            groupAchievement.static_type = name
            groupAchievement.group_name = achievementGroup.name
            groupAchievement.group_id = achievementGroup.id
            store.ensure_index static_collection, armory_static_index_1, null, ->
              store.upsert static_collection, {static_type:name, id:groupAchievement.id}, groupAchievement
        # get categories and their achievements
        if achievementGroup.categories?
          for groupCategory in achievementGroup.categories
            for categoryAchievement in groupCategory.achievements
              categoryAchievement.static_type = name
              categoryAchievement.category_name = groupCategory.name
              categoryAchievement.category_id = groupCategory.id
              categoryAchievement.group_name = achievementGroup.name
              categoryAchievement.group_id = achievementGroup.id
              store.upsert static_collection, {static_type:name, id:categoryAchievement.id}, categoryAchievement

      # for each, go through its categories/achievements and achievements, store in db
      # 

  armory_get_logged_call: (item, callback) =>
    armory_stats = 
      type: item.type
      region: item.region
      name: item.name
      realm: item.realm
      start_time: new Date().getTime()
    store.load armory_collection, {type: item.type, region: item.region, name: item.name, realm: item.realm}, {sort: {"lastModified": -1}}, (doc) =>
      wowlookup.get item.type, item.region, item.realm, item.name, doc?.lastModified, (info) =>
        armory_stats.end_time = new Date().getTime()
        armory_stats.error = info?.error
        armory_stats.not_modified = (info is undefined and !armory_stats.error?)
        armory_stats.had_error = info?.error?
        store.insert calls_collection, armory_stats, =>
          callback?(doc, info)
    
  armory_item_logged_call: (item_id, callback) =>
    armory_stats = 
      type: "item"
      region: "eu"
      name: item_id
      realm: "na"
      start_time: new Date().getTime()
    wowlookup.get_item item_id, null, (info) ->
      armory_stats.end_time = new Date().getTime()
      armory_stats.error = info?.error
      armory_stats.not_modified = (info is undefined and !armory_stats.error?)
      armory_stats.had_error = info?.error?
      store.insert calls_collection, armory_stats, =>
        callback?(info)
    
  ensure_registered_correct: (item, info, callback) =>
    if item.registered != false and !info.error? and (item.name != info.name or item.realm != info.realm or item.region != info.region)
      wf.info "Registered entry is different, update registered"
      item_key = 
        type: item.type
        region: item.region
        name: item.name
        realm: item.realm
      new_item_key = 
        type: info.type
        region: info.region
        name: info.name
        realm: info.realm
      item.realm = info.realm
      item.region = info.region
      item.name = info.name
      item.updated_at = new Date()
      store.load registered_collection, new_item_key, null, (new_key_item)->
        if new_key_item?
          # new key exists already, so delete old one
          store.remove registered_collection, item_key, ->
            callback?(info)
        else
          store.upsert registered_collection, item_key, item, ->
            callback?(info)
    else
      callback?(info)

  armory_item_loader: (item, callback) =>
    @armory_get_logged_call item, (doc, info) =>
      # wf.info "Info back for #{info?.name}, members:#{info?.members?.length}"
      if info?
        @store_update info.type, info.region, info.realm, info.name, info, =>
          # wf.debug "Checking registered:#{item.name} vs #{info.name} and #{item.realm} vs #{info.realm}, error?#{info.error == null}"
          @ensure_registered_correct item, info, callback
      else
        # send old info back, needed for guilds so we can query the members
        callback?(doc?.armory) 

  armory_results_loader: (loader_queue, results_array) ->
    loader_queue.push results_array, (info) ->
      if info?.type == "guild" and info?.members?
        for member in info.members
          loader_queue.push type: "member", region: info.region, realm: info.realm, name: member.character.name, registered:false

  armory_load: (loaded_callback) =>
    wf.info "armory_load..."
    return if job_running_lock # only run one at a time....
    job_running_lock = true
    try 
      loader_queue = async.queue(@armory_item_loader, wf.ARMORY_CALL_THREADS ) # wf.ARMORY_CALL_THREADS  max threads 
      loader_queue.drain = ->
        job_running_lock = false
        loader_queue = null
        loaded_callback?()
      if armory_pending_queue? and armory_pending_queue.length >0
        wf.info "Loading from armory_pending_queue, length:#{armory_pending_queue.length}"
        temp_pending_queue = armory_pending_queue[..]
        armory_pending_queue = []
        @armory_results_loader(loader_queue, temp_pending_queue)
      else
        @get_registered (results_array) =>
          @armory_results_loader(loader_queue, results_array)



  format_armory_info: (type, region, realm, name, info, doc) ->
    new_item = {region, realm, type, name}
    new_item.lastModified = info.lastModified
    # remap achievements as a map for ease of diff/use
    # if info.achievements?
    #   achievements_map = {}
    #   for i in [0..info.achievements.achievementsCompleted.length-1]
    #     achievements_map[info.achievements.achievementsCompleted[i]] = info.achievements.achievementsCompletedTimestamp[i]
    #   info.achievements_map = achievements_map
    #   achievements_criteria_map = {}
    #   for i in [0..info.achievements.criteria.length-1]
    #     achievements_criteria_map[info.achievements.criteria[i]] = 
    #       created: info.achievements.criteriaCreated[i]
    #       quantity: info.achievements.criteriaQuantity[i]
    #       timestamp: info.achievements.criteriaTimestamp[i]
    #   info.achievements_criteria_map = achievements_criteria_map

    # remap members as a map for ease of diff/use
    if info.members?
      members_map = {}
      for m in info.members
        members_map[m.character.name] = m
      info.members_map = members_map

    # remap professions
    if info.professions?
      professions_map = {}
      for own category, profs of info.professions
        for prof in profs
          professions_map[prof.name] = prof
      info.professions_map = professions_map

    # remap reputation
    if info.reputation?
      reputation_map = {}
      for rep in info.reputation
        reputation_map[rep.name.replace(/\./g,"")] = rep
      info.reputation_map = reputation_map

    # remap mounts
    if info.mounts?
      mounts_collected_map = {}
      for m in info.mounts.collected
        mounts_collected_map[m.name.replace(/\./g,"")] = m
      info.mounts_collected_map = mounts_collected_map

    if info.pets?
      pets_collected_map = {}
      for p in info.pets.collected
        pets_collected_map[p.name.replace(/\./g,"")] = p
      info.pets_collected_map = pets_collected_map

    if info.titles?
      titles_map = {}
      for t in info.titles
        base_name = t.name.replace /%s/,""
        titles_map[base_name] = t
      info.titles_map = titles_map

    # strip achievements as they are in the news/feeds items
    delete info.achievements

    new_item.armory = info
    saved_stuff_old = {}
    saved_stuff_new = {}
    items_to_save = ['feed','news','members','reputation','professions']
    for item in items_to_save
      if info[item]?
        saved_stuff_new[item] = info[item]
        info[item] = null
      if doc?.armory?[item]?
        saved_stuff_old[item] = doc.armory[item]
        doc.armory[item] = null
    whats_changed = wf.calc_changes(doc?.armory, info)
    for item in items_to_save
      if saved_stuff_new[item]?
        info[item] = saved_stuff_new[item]
      if saved_stuff_old[item]?
        doc.armory[item] = saved_stuff_old[item]
    new_item.whats_changed = whats_changed
    new_item.added_date = new Date()
    new_item.accessed_at = new Date()
    return new_item

  store_update: (type, region, realm, name, info, stored_handler) => 
    if info.error? 
      stored_handler?()
      return # dont save if we had an error

    # find prev entry
    # is it same one, if so done- nowt to do
    # if not same, calc diff, then save it
    @ensure_armory_indexes =>
      store.load armory_collection, {region, realm, type, name}, {sort: {"lastModified": -1}}, (doc) =>
        wf.debug "store_update:#{JSON.stringify(doc)}"
        if doc? and doc.lastModified == info.lastModified
          wf.debug "Ignored as no changes and saved already: #{name}"
          stored_handler?()
        else
          wf.debug "New or updated: #{info.name}/#{name}"
          new_item = @format_armory_info(type, region, realm, name, info, doc)
          wf.debug "pre add"
          store.add armory_collection, new_item, ->
            items_to_get = feed_formatter.get_items new_item
            wf.debug "Loading char items:#{items_to_get.length}"
            for item_id in items_to_get
              item_loader_queue.push item_id
            if doc?
              store.update armory_collection, doc, {$unset:{armory:1}, $set:{archived_at:new Date()}}, ->
                wf.debug "Now saved #{info.name}/#{name}, updated old one"
                store.load_all_with_fields armory_collection,  {region, realm, type, name}, {lastModified:1}, {sort: {"lastModified": -1}, limit: wf.HISTORY_SAVE_LIMIT}, (docs) =>
                  # get last last mod date
                  wf.info "Current history - count:#{docs.length}"
                  last_doc_last_modified = docs[-1...-1].lastModified
                  # delete all entries with last mod date before date (less than)
                  store.remove armory_collection, {region, realm, type, name, lastModified : { $lt : last_doc_last_modified } }, (count)->
                    wf.info "Deleted old history - count:#{count}"
                    stored_handler?()
            else
              wf.debug "Now saved #{info.name}/#{name}, no old one"
              stored_handler?()

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

  realms_loader: (callback) =>
    # load and then replace
    @armory_realms_logged_call (realms) ->
      wf.info "Realms returned:#{realms.length}"
      if realms? and realms.length > 0  
        #  TODO find a unique key!!!
        # store.ensure_index realms_collection, realms_index_1, null, ->
          store.remove_all realms_collection, ->
            store.insert realms_collection, realms, callback

  armory_realms_logged_call: (callback) =>
    armory_stats = 
      type: "realms"
      region: "all"
      name: "realms"
      realm: "na"
      start_time: new Date().getTime()
    wowlookup.get_realms (info) ->
      wf.info "get realms responded, realms:#{info.length}"
      armory_stats.end_time = new Date().getTime()
      armory_stats.error = info?.error
      armory_stats.not_modified = (info is undefined and !armory_stats.error?)
      armory_stats.had_error = info?.error?
      store.insert calls_collection, armory_stats, ->
        callback?(info)
    

  item_loader: (item_id, callback) =>
    # see if we have it already
    # if not, go to armory
    # persist
    store.load items_collection, {item_id}, null, (doc) =>
      unless doc?
        @armory_item_logged_call item_id, (item)->
          if item?
            item.item_id = item_id
            store.add items_collection, item, callback
          else
            callback?()
      else
        callback?()
