global.wf ||= {}

startup_time = new Date().getTime()

async = require "async"
moment = require "moment"

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
  static_collection = "armory_static"
  calls_collection = "armory_calls"

  fields_to_select = {name:1,realm:1,region:1,type:1, lastModified:1, whats_changed:1, "armory.news":1, "armory.feed":1, "armory.thumbnail":1, "armory.members":1}

  registered_index_1 = {name:1, realm:1, region:1, type:1}
  armory_index_1 = {name:1, realm:1, region:1, type:1, lastModified:1}
  armory_static_index_1 = {static_type:1, id:1}
  job_running_lock = false
  armory_pending_queue = []

  constructor: (callback)->
    wf.info "WoW constructor"
    store.create_collection calls_collection, capped:true, autoIndexId:false, size: 2000000, (err, result)=>
      wf.info "Created capped collection:#{calls_collection}. #{err}, #{result}"
      callback?(this)

  ensure_registered: (region, realm, type, name, registered_handler) ->
    wf.debug "Registering #{name}"
    store.load registered_collection, {region,realm,type,name}, null, (doc) ->
      wf.info "ensure_registered:#{JSON.stringify(doc)}"
      if doc?
        wf.debug "Registered already: #{name}"
        registered_handler?(true)
      else
        wf.debug "Not Registered #{name}"
        armory_pending_queue.push {region, realm, type, name}
        wf.armory_load_requested = true # new item/guild, so do an armory load soon
        store.add registered_collection,{region,realm,type,name}, ->
          wf.debug "Now Registered #{name}"
          registered_handler?(false)

  get_store: ->
    store

  get_wowlookup: ->
    wowlookup

  get_registered: (registered_handler)->
    store.ensure_index registered_collection, registered_index_1, ->
      store.load_all registered_collection, {}, {}, registered_handler

  clear_all: (cleared_handler) ->
    wf.debug "clear_all called"
    store.remove_all registered_collection, ->
      store.remove_all armory_collection, ->
        store.drop_collection calls_collection, ->
          store.remove_all static_collection, cleared_handler


  clear_registered: (cleared_handler) ->
    store.remove_all registered_collection, cleared_handler

  get: (region, realm, type, name, result_handler) =>
    if type == "guild" or type == "member"
      @ensure_registered region, realm, type, name, ->
        store.ensure_index armory_collection, armory_index_1, ->
          store.load armory_collection, {type, region, realm, name}, {sort: {"lastModified": -1}}, result_handler
    else
      result_handler?(null)

  armory_calls: (callback)->
    info = 
      startup_time: moment(startup_time).format('H:mm:ss ddd')
      total_calls: 0
      total_errors: 0
      total_not_modified: 0
      todays_calls: 0
      todays_errors: 0
      todays_not_modified: 0
      earliest: Infinity
      latest: 0
      error_summary :{}
      armory_load_running: job_running_lock
    store.dbstats armory_collection, calls_collection, registered_collection, (stats) ->
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
          if moment().sod().format("DDD") == moment(call.start_time).format("DDD")
            info.todays_calls += 1
            info.todays_errors += 1 if call.had_error
            info.todays_not_modified += 1 if call.not_modified
        info.earliest = moment(info.earliest).format('H:mm:ss ddd')
        info.latest = moment(info.latest).format('H:mm:ss ddd')
        callback?(info)

  get_loaded: (loaded_handler) ->
    store.ensure_index armory_collection, armory_index_1, ->
      # store.load_all armory_collection, {}, {limit:wf.HISTORY_LIMIT,sort: {"lastModified": -1}}, loaded_handler
      store.load_all_with_fields armory_collection, {}, 
        fields_to_select,  
        {limit:wf.HISTORY_LIMIT, sort: {"lastModified": -1}}, loaded_handler

  get_history: (region, realm, type, name, result_handler) =>
    if type == "guild" or type == "member"
      @ensure_registered region, realm, type, name, ->
        store.ensure_index armory_collection, armory_index_1, ->
          selector = {type, region, realm, name}
          store.load_all_with_fields armory_collection, selector, fields_to_select, {limit:wf.HISTORY_LIMIT, sort: {"lastModified": -1}}, (results) ->
            if type == "guild" # if its a guild, also query for guild members
              wf.debug "Got a guild, so also query for members..."
              selector = {type:"member", region, realm, "armory.guild.name":name}
              store.load_all_with_fields armory_collection, selector, fields_to_select, {limit:wf.HISTORY_LIMIT, sort: {"lastModified": -1}}, (members) ->
                for m in members
                  results.push m
                result_handler?(results)
            else
              result_handler?(results)
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
            store.ensure_index static_collection, armory_static_index_1, ->
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

  armory_item_loader: (item, callback) =>
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
        armory_stats.not_modified = (info is undefined)
        armory_stats.had_error = info?.error?
        store.insert calls_collection, armory_stats, =>
          # wf.info "Info back for #{info?.name}, members:#{info?.members?.length}"
          if info?
            @store_update info.type, info.region, info.realm, info.name, info, ->
              wf.debug "Checking registered:#{item.name} vs #{info.name} and #{item.realm} vs #{info.realm}, error?#{info.error == null}"
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
      loader_queue = async.queue(@armory_item_loader, 5) # 5 max threads 
      loader_queue.drain = ->
        job_running_lock = false
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
    # todo, remove orig achievements entry, maybe

    # strip achievements as they are in the news/feeds items
    delete info.achievements

    new_item.armory = info
    whats_changed = wf.calc_changes(doc?.armory, info)
    new_item.whats_changed = whats_changed
    return new_item

  store_update: (type, region, realm, name, info, stored_handler) => 
    # find prev entry
    # is it same one, if so done- nowt to do
    # if not same, calc diff, then save it
    store.ensure_index armory_collection, armory_index_1, =>
      store.load armory_collection, {region, realm, type, name}, {sort: {"lastModified": -1}}, (doc) =>
          wf.debug "store_update:#{JSON.stringify(doc)}"
          if doc? and doc.lastModified == info.lastModified
            wf.debug "Ignored as saved already: #{name}"
            stored_handler?()
          else
            # only save errors for new updates (assume others are transient)
            unless doc? and info.error?
              wf.debug "New or updated: #{info.name}/#{name}"
              new_item = @format_armory_info(type, region, realm, name, info, doc)
              wf.debug "pre add"
              store.add armory_collection, new_item, ->
                if doc?
                  store.update armory_collection, doc, {$unset:{armory:1}}, ->
                    wf.debug "Now saved #{info.name}/#{name}, updated old one"
                    stored_handler?()
                else
                  wf.debug "Now saved #{info.name}/#{name}, no old one"
                  stored_handler?()

