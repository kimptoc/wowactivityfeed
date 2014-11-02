global.wf ||= {}

get_args = require "arguejs"

require "./defaults"
require './init_logger'
portcheck = require 'portchecker'

class wf.WowLookup

  armory_instance = null
  armory_connecting = false
  armory_calls =
    guild: "guild"
    member: "character"
    character: "character"

  armory_fields =
    guild: ["members","achievements","news","challenge"]
    member:    ["achievements","guild","feed","hunterPets","professions","progression","pvp","quests","reputation","stats","talents","titles","items","pets","petSlots","mounts"]
    character: ["achievements","guild","feed","hunterPets","professions","progression","pvp","quests","reputation","stats","talents","titles","items","pets","petSlots","mounts"]

  constructor: ->
    wf.info "WowLookup constructor"

  get_armory: () ->
    param = get_args(callback:Function)
    armory_defaults =
      publicKey: wf.WOW_API_PUBLIC_KEY
      privateKey: wf.WOW_API_PRIVATE_KEY

    request_defaults =
      timeout: wf.ARMORY_CALL_TIMEOUT
      # pool: false
      maxSockets: 1000

    if process.env.NODE_ENV == "production"
      wf.info "Its production - dont use a proxy to the armory"
      armory_defaults.request = request_defaults
      armory = require('armory').defaults(armory_defaults)
      param.callback(armory)
    else
      try
        portcheck.isOpen 8888,"localhost", (is_open)->
          wf.info "Port is open? #{is_open}"
          if is_open
            wf.info "Found the proxy, so use it:#{is_open}"
            request_defaults.strictSSL = false
            request_defaults.proxy = "http://localhost:8888"
            armory_defaults.request = request_defaults
            armory = require('armory').defaults(armory_defaults)
            param.callback(armory)
          else
            wf.info "Proxy not found, so connecting to armory direct"
            armory_defaults.request = request_defaults
            armory = require('armory').defaults(armory_defaults)
            param.callback(armory)
      catch e
        wf.info "Proxy not found, so connecting to armory direct:#{e}"
        armory_defaults.request = request_defaults
        armory = require('armory').defaults(armory_defaults)
        param.callback(armory)

  with_armory: (armory_handler) ->
    if armory_instance?
      armory_handler?(armory_instance)
    else
      if armory_connecting
        setTimeout (=> @with_armory(armory_handler)), 100
      else
        armory_connecting = true
        @get_armory (armory) ->
          armory_instance = armory
          armory_handler?(armory_instance)

#  get: (item_info, lastModified, result_handler) ->
  get: () ->
    param = get_args(item_info:Object, lastModified:null, result_handler:Function)
#    param = {item_info,lastModified,result_handler}
    realm = param.item_info.realm
    region = param.item_info.region
    name = param.item_info.name
    type = param.item_info.type
    locale = param.item_info.locale || wf.REGION_LOCALE[region]
    wf.debug "Armory lookup #{type} info for #{region}, #{realm}, #{name}, last mod:#{new Date(param.lastModified)}"
    @with_armory (armory) ->
      armory[armory_calls[type]] {region, realm, name, locale, fields: armory_fields[type], lastModified:param.lastModified}, (err,thing) ->
        if err is null and thing is undefined # no changes
          wf.debug "wowlookup #{name} - not modified"
          param.result_handler?(undefined)
        else if err
          wf.warn("wowlookup error looking for #{name},#{realm},#{region},#{locale},#{type}:#{err.message} : #{JSON.stringify(err)}")
          param.result_handler?(
            type: type
            region: region
            realm: realm
            name: name
            locale: locale
            error: err.message
            lastModified: 0
            info: "Armory lookup #{type} info for #{region}/#{locale}, #{realm}, #{name}")
        else
          wf.debug "wowlookup #{name}/#{thing?.name}, err:#{JSON.stringify(err)}, result:#{JSON.stringify(thing)}"
          thing?.type = type
          thing?.region = region?.toLowerCase()
          thing?.locale = locale
          param.result_handler?(thing)

  get_item: (item_id, locale, region = "eu", context = null, callback) ->
    wf.debug "Item lookup:#{item_id}/#{context}/#{locale}/#{region}"
    @with_armory (armory) ->
      armory.item {id:item_id, context, region, locale}, (err, item) ->
        if err
          wf.warn "WOWAPI:Problem finding item id:#{item_id}/#{context}/#{locale}/#{region} error:#{err.message} : #{JSON.stringify(err)}"
          callback?(null)
        else
          item.item_id = item_id
          item.context = context
          item.locale = locale
          item.region = region
          callback?(item)

#  get_races: (region = "eu", callback) ->
#    @with_armory (armory) ->
#      armory.races {region}, (err, races) ->
#        if err
#          wf.error "Problem finding races for region:#{region} error:#{err.message} : #{JSON.stringify(err)}"
#          callback?(null)
#        else
#          callback?(races)
#
#  get_classes: (region = "eu", callback) ->
#    @with_armory (armory) ->
#      armory.classes {region}, (err, classes) ->
#        if err
#          wf.error "Problem finding classes for region:#{region} error:#{err.message} : #{JSON.stringify(err)}"
#          callback?(null)
#        else
#          callback?(classes)

  get_realms: (region, locale, callback) ->
    @with_armory (armory) ->
      armory.realmStatus {region, locale}, (err, realms) ->
        date_retrieved = new Date()
        all_realms = [] # results
        if err
          wf.warn "WOWAPI:Problem finding realms for region:#{region} error:#{err.message} : #{JSON.stringify(err)}"
        else
          wf.info "Region #{region} found #{realms.length} realm(s)"
          for realm in realms
            realm.region = region
            realm.lookup_locale = locale
            realm.date_retrieved = date_retrieved
            all_realms.push realm
        callback?(all_realms)

#  get_static: (static_load_method, region = "eu", callback) ->
#    @with_armory (armory) ->
#      armory[static_load_method] {region}, (err, things) ->
#        if err
#          wf.error("wowlookup get_static(#{static_load_method}) error:#{err.message} : #{JSON.stringify(err)}")
#          callback?(null)
#        else
#          wf.debug "wowlookup get_static(#{static_load_method}) result:[#{things.length}]#{JSON.stringify(things)}"
#          callback?(things)
