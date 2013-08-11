global.wf ||= {}

_ = require "underscore"

get_args = require "arguejs"

async = require "async"

require './init_logger'
require './feed_item_formatter'
require "./wowlookup"
require './call_logger'

# this class handles loading info from the Armory and saving it to the db
class wf.WoWLoader

  wow = null
  store = null
  wowlookup = new wf.WowLookup()
  feed_formatter = null

  constructor: (@wow) ->
    store = @wow.get_store()
    new wf.CallLogger(@wow, wowlookup, store)
    feed_formatter = new wf.FeedItemFormatter()
    @wow.set_item_loader_queue async.queue(@item_loader, wf.ITEM_LOADER_THREADS)


#  ensure_registered_correct: (item, info, callback) =>
#    if item.register_check != false and !info.error? and (item.name != info.name or item.realm != info.realm or item.region != info.region or item.locale != info.locale)
#      wf.info "Registered entry is different, update registered"
#      item_key =
#        type: item.type
#        region: item.region
#        name: item.name
#        realm: item.realm
#        locale: item.locale
#      new_item_key =
#        type: info.type
#        region: info.region
#        name: info.name
#        realm: info.realm
#        locale: info.locale
#      item.realm = info.realm
#      item.region = info.region
#      item.name = info.name
#      item.locale = info.locale
#      item.updated_at = new Date()
#      store.load @wow.get_registered_collection(), new_item_key, null, (new_key_item)=>
#        if new_key_item?
#          # new key exists already, so delete old one
#          store.remove @wow.get_registered_collection(), item_key, ->
#            callback?(info)
#        else
#          store.upsert @wow.get_registered_collection(), item_key, item, ->
#            callback?(info)
#    else
#      callback?(info)


  format_armory_info: () ->
#  format_armory_info: (type, region, realm, name,locale, info, doc) ->
#    param = {type,region,realm,name,locale,info,doc}
    param = get_args(type:String,region:String,realm:String,name:String,locale:String,info:Object,doc:null)
    new_item = {region:param.region, realm:param.realm, type:param.type, name:param.name, locale:param.locale}
    new_item.lastModified = param.info.lastModified
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
    if param.info.members?
      members_map = {}
      for m in param.info.members
        members_map[m.character.name] = m
      param.info.members_map = members_map

    # remap professions
    if param.info.professions?
      professions_map = {}
      for own category, profs of param.info.professions
        for prof in profs
          professions_map[prof.name] = prof
      param.info.professions_map = professions_map

    # remap reputation
    if param.info.reputation?
      reputation_map = {}
      for rep in param.info.reputation
        reputation_map[rep.name.replace(/\./g,"")] = rep
      param.info.reputation_map = reputation_map

    # remap mounts
    if param.info.mounts?
      mounts_collected_map = {}
      for m in param.info.mounts.collected
        mounts_collected_map[m.name.replace(/\./g,"")] = m
      param.info.mounts_collected_map = mounts_collected_map

    if param.info.pets?
      pets_collected_map = {}
      for p in param.info.pets.collected
        pets_collected_map[p.name.replace(/\./g,"")] = p
      param.info.pets_collected_map = pets_collected_map

    if param.info.titles?
      titles_map = {}
      for t in param.info.titles
        base_name = t.name.replace /%s/,""
        titles_map[base_name] = t
      param.info.titles_map = titles_map

    # strip achievements as they are in the news/feeds items
    delete param.info.achievements

    new_item.armory = param.info
    saved_stuff_old = {}
    saved_stuff_new = {}
    items_to_save = ['feed','news','members','reputation','professions']
    for item in items_to_save
      if param.info[item]?
        saved_stuff_new[item] = param.info[item]
        param.info[item] = null
      if param.doc?.armory?[item]?
        saved_stuff_old[item] = param.doc.armory[item]
        param.doc.armory[item] = null
    whats_changed = wf.calc_changes(param.doc?.armory, param.info)
    for item in items_to_save
      if saved_stuff_new[item]?
        param.info[item] = saved_stuff_new[item]
      if saved_stuff_old[item]?
        param.doc.armory[item] = saved_stuff_old[item]
    new_item.whats_changed = whats_changed
    new_item.added_date = new Date()
    new_item.accessed_at = new Date()
    return new_item

  store_update: () =>
    param = get_args(type:String,region:String,realm:String,name:String,locale:String,info:Object,stored_handler:Function)
    if param.info.error?
      param.stored_handler?()
      return # dont save if we had an error

    wf.debug "store_update: locale=#{param.locale}"

    # find prev entry
    # is it same one, if so done- nowt to do
    # if not same, calc diff, then save it
    @wow.ensure_armory_indexes =>
      store.load @wow.get_armory_collection(), {region:param.region, realm:param.realm, type:param.type, name:param.name, locale:param.locale}, {sort: {"lastModified": -1}}, (doc) =>
        wf.debug "store_update:#{JSON.stringify(doc)}"
        if doc? and doc.lastModified == param.info.lastModified
          wf.debug "Ignored as no changes and saved already: #{param.name}"
          param.stored_handler?()
        else
          wf.debug "New or updated: #{param.info.name}/#{param.name}/#{doc}"
          new_item = @format_armory_info(param.type, param.region, param.realm, param.name, param.locale, param.info, doc)
          wf.debug "pre add"
          store.add @wow.get_armory_collection(), new_item, =>
            items_to_get = feed_formatter.get_items new_item
            wf.debug "Loading char items:#{items_to_get.length}"
            for item_id in items_to_get
              @wow.get_item_loader_queue().push {item_id,locale:param.locale,region:param.region}
            if doc?
              store.update @wow.get_armory_collection(), doc, {$unset:{armory:1}, $set:{archived_at:new Date()}}, =>
                wf.debug "Now saved #{param.info.name}/#{param.name}, updated old one"
                store.load_all_with_fields @wow.get_armory_collection(),  {region:param.region, realm:param.realm, type:param.type, name:param.name, locale:param.locale}, {lastModified:1}, {sort: {"lastModified": -1}, limit: wf.HISTORY_SAVE_LIMIT}, (docs) =>
                  # get last last mod date
                  wf.info "Current history - count:#{docs.length}"
                  last_doc_last_modified = docs[-1...-1].lastModified
                  # delete all entries with last mod date before date (less than)
                  store.remove @wow.get_armory_collection(), {region:param.region, realm:param.realm, type:param.type, name:param.name, locale:param.locale, lastModified : { $lt : last_doc_last_modified } }, (count)->
                    wf.info "Deleted old history - count:#{count}"
                    param.stored_handler?()
            else
              wf.debug "Now saved #{param.info.name}/#{param.name}, no old one"
              param.stored_handler?()



#  static_load: =>
#    # load achievements / #not used, at the moment
#    try
#      @save_achievements("characterAchievements")
#      @save_achievements("guildAchievements")
#    catch e
#      wf.error "static_load:#{e}"

#  save_achievements: (name) ->
#    # load achievements / #not used, at the moment
#    wowlookup.get_static name, "eu", (achievements) ->
#      # data returned is quite structured - so flatten it out to save it
#      # go through all groups
#      return unless achievements?
#      for achievementGroup in achievements
#        # get groups categories
#        if achievementGroup.achievements?
#          for groupAchievement in achievementGroup.achievements
#            groupAchievement.static_type = name
#            groupAchievement.group_name = achievementGroup.name
#            groupAchievement.group_id = achievementGroup.id
#            store.ensure_index @wow.get_static_collection(), @wow.get_static_index_1(), null, ->
#              store.upsert @wow.get_static_collection(), {static_type:name, id:groupAchievement.id}, groupAchievement
#        # get categories and their achievements
#        if achievementGroup.categories?
#          for groupCategory in achievementGroup.categories
#            for categoryAchievement in groupCategory.achievements
#              categoryAchievement.static_type = name
#              categoryAchievement.category_name = groupCategory.name
#              categoryAchievement.category_id = groupCategory.id
#              categoryAchievement.group_name = achievementGroup.name
#              categoryAchievement.group_id = achievementGroup.id
#              store.upsert @wow.get_static_collection(), {static_type:name, id:categoryAchievement.id}, categoryAchievement


  armory_item_loader: (item, callback) =>
    wf.debug "armory_item_loader:#{item?.name}"
    store.load @wow.get_armory_collection(), {type: item.type, region: item.region, name: item.name, realm: item.realm, locale: item.locale}, {sort: {"lastModified": -1}}, (doc) =>
      wowlookup.get item, doc?.lastModified, (info) =>
        # wf.info "Info back for #{info?.name}, members:#{info?.members?.length}"
        if info?
          @store_update item.type, item.region, item.realm, item.name, item.locale, info, =>
            # wf.debug "Checking registered:#{item.name} vs #{info.name} and #{item.realm} vs #{info.realm}, error?#{info.error == null}"
            callback?(info)
#            @ensure_registered_correct item, info, callback
        else
          # send old info back, needed for guilds so we can query the members
          callback?(doc?.armory) 

  armory_results_loader: (loader_queue, results_array) ->
    loader_queue.push results_array, (info) ->
      if info?.type == "guild" and info?.members?
        for member in info.members
          loader_queue.push type: "member", region: info.region.toLocaleLowerCase(), realm: info.realm.toLocaleLowerCase(), name: member.character.name.toLocaleLowerCase(), locale: info.locale, register_check:false

  armory_load: (loaded_callback) =>
    wf.info "armory_load..."
    return if @wow.get_job_running_lock() # only run one at a time....
    @wow.set_job_running_lock(true)
    try 
      @wow.set_loader_queue async.queue(@armory_item_loader, wf.ARMORY_CALL_THREADS ) # wf.ARMORY_CALL_THREADS  max threads 
      @wow.get_loader_queue().drain = =>
        wf.debug "armory_load:drain"
        @wow.set_job_running_lock(false)
        @wow.set_loader_queue(null)
        loaded_callback?()
      if @wow.get_armory_pending_queue()? and @wow.get_armory_pending_queue().length >0
        wf.info "Loading from armory_pending_queue, length:#{@wow.get_armory_pending_queue().length}"
        temp_pending_queue = @wow.get_armory_pending_queue()[..]
        wf.info "Loading from armory_pending_queue/temp, length:#{temp_pending_queue.length}"
        @wow.clear_armory_pending_queue()
        @armory_results_loader(@wow.get_loader_queue(), temp_pending_queue)
      else
        @wow.get_registered (results_array) =>
          @armory_results_loader(@wow.get_loader_queue(), results_array)
    catch e
      wf.error "armory_load:#{e}"

  static_loader: (callback) ->
#    async.parallel {realms:@realms_loader, races:@races_loader, classes:@classes_loader}, callback
    async.parallel {realms:@realms_loader}, callback

#TODO make this code handle locales...
#  load_static_claz: (type, claz, loaded_callback) ->
#    claz.static_type = type
#    store.ensure_index @wow.get_static_collection(), @wow.get_static_index_1(), null, =>
#      store.upsert @wow.get_static_collection(), {static_type:claz.static_type, id:claz.id}, claz, loaded_callback
#
#  classes_loader: (callback) =>
#    wowlookup.get_classes null, (classes) =>
#      if classes? and classes.length > 0
#        loader = (claz, loaded_callback) =>
#          @load_static_claz 'CLASS', claz, loaded_callback
#        async.forEach classes, loader, -> callback?(classes)
#
#  races_loader: (callback) =>
#    wowlookup.get_races null, (races) =>
#      if races? and races.length > 0
#        loader = (race, loaded_callback) =>
#          @load_static_claz 'RACE', race, loaded_callback
#        async.forEach races, loader, -> callback?(races)

  realms_loader: (callback) =>
    # load and then replace
    all_realms = {}
    get_realms_error = false
    get_region_locale_realms = (param, region_callback) =>
      wowlookup.get_realms param.region, param.locale, (realms) ->
        if realms.length == 0
          wf.warn "Uh-oh For region #{param.region}/#{param.locale}, realms returned:#{realms.length}"
          get_realms_error = true
        else
          wf.info "For region #{param.region}/#{param.locale}, realms returned:#{realms.length}"
        for realm in realms
          realm_region_key = realm.name + realm.region
          existing = all_realms[realm_region_key]
          unless existing
            all_realms[realm_region_key] = realm
        region_callback?()
    region_locales = []
    # you'd think this would be a good idea, but there are locales not connected, eg english for chinese region :)
#    for own region, locales of wf.regions_to_locales
#      for locale in locales

    for locale in wf.locales
      for region in wf.all_regions
        region_locales.push {region,locale}
    async.forEach region_locales, get_region_locale_realms, =>
      realms_array = []
      if ! get_realms_error
        realms_array = _.values(all_realms) if all_realms?
        wf.info "Realms calls done, time to persist:#{realms_array.length}"
        if realms_array? and realms_array.length > 0
          store.ensure_index @wow.get_realms_collection(), @wow.get_realms_index_1(), null, =>
            store.remove_all @wow.get_realms_collection(), =>
              store.insert @wow.get_realms_collection(), realms_array, -> callback?(realms_array)
        else
          callback?(realms_array)
      else
        wf.error "Got an error checking the realms, will ignore results this time"
        callback?(realms_array)


  item_loader: (item_info, callback) =>
    # see if we have it already
    # if not, go to armory
    # persist
    store.ensure_index @wow.get_items_collection(), @wow.get_armory_item_index_1(), {dropDups:true}, =>
      store.load @wow.get_items_collection(), item_info, null, (doc) =>
        unless doc?
          wowlookup.get_item item_info.item_id, item_info.locale, item_info.region, (item)=>
            if item?
              store.upsert @wow.get_items_collection(), {item_id:item_info.item_id, locale:item_info.locale, region:item_info.region} , item, callback
            else
              callback?()
        else
          callback?()
