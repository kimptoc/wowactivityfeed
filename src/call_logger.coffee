global.wf ?= {}

require './init_logger'

class wf.CallLogger

  constructor: (wow, wowlookup, store) ->
    wow.armory_get_logged_call = (item, doc, callback) =>
      wf.debug "Wrapped armory call"
      armory_stats = 
        type: item.type
        region: item.region
        name: item.name
        realm: item.realm
        start_time: new Date().getTime()
      wowlookup.get item.type, item.region, item.realm, item.name, doc?.lastModified, (info) =>
        armory_stats.end_time = new Date().getTime()
        armory_stats.error = info?.error
        armory_stats.not_modified = (info is undefined and !armory_stats.error?)
        armory_stats.had_error = info?.error?
        store.insert wow.get_calls_collection(), armory_stats, =>
          callback?(info)
    
    wow.armory_item_logged_call = (item_id, callback) =>
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
        store.insert wow.get_calls_collection(), armory_stats, =>
          callback?(info)
      
    wow.armory_realms_logged_call = (region, callback) =>
      armory_stats = 
        type: "realms"
        region: region
        name: "realms"
        realm: "na"
        start_time: new Date().getTime()
      wowlookup.get_realms region, (info) ->
        wf.info "get realms for region #{region} responded, realms:#{info.length}"
        armory_stats.end_time = new Date().getTime()
        armory_stats.error = info?.error
        armory_stats.not_modified = (info is undefined and !armory_stats.error?)
        armory_stats.had_error = info?.error?
        store.insert wow.get_calls_collection(), armory_stats, ->
          callback?(info)
      

