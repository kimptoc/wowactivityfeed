global.wf ?= {}

require './init_logger'

class wf.CallLogger

  constructor: (wow, wowlookup, store) ->

    wowlookup_get = wowlookup.get    
    wowlookup.get = (type, region, realm, name, lastModified, callback) ->
      wf.debug "Wrapped armory call"
      armory_stats = 
        type: type
        region: region
        name: name
        realm: realm
        start_time: new Date().getTime()
      wowlookup_get.apply wowlookup, [type, region, realm, name, lastModified, (info) ->
        armory_stats.end_time = new Date().getTime()
        armory_stats.error = info?.error
        armory_stats.not_modified = (info is undefined and !armory_stats.error?)
        armory_stats.had_error = info?.error?
        store.insert wow.get_calls_collection(), armory_stats, ->
          callback?(info)
      ]
    
    wowlookup_get_item = wowlookup.get_item
    wowlookup.get_item = (item_id, region, callback) ->
      armory_stats = 
        type: "item"
        region: "eu"
        name: item_id
        realm: "na"
        start_time: new Date().getTime()
      wowlookup_get_item.apply wowlookup, [item_id, region, (info) ->
        armory_stats.end_time = new Date().getTime()
        armory_stats.error = info?.error
        armory_stats.not_modified = (info is undefined and !armory_stats.error?)
        armory_stats.had_error = info?.error?
        store.insert wow.get_calls_collection(), armory_stats, ->
          callback?(info)
      ]
      
    wowlookup_get_races = wowlookup.get_races
    wowlookup.get_races = (region, callback) ->
      armory_stats = 
        type: "races"
        region: region
        name: "races"
        realm: "na"
        start_time: new Date().getTime()
      wowlookup_get_races.apply wowlookup, [region, (info) ->
        armory_stats.end_time = new Date().getTime()
        armory_stats.error = info?.error
        armory_stats.not_modified = (info is undefined and !armory_stats.error?)
        armory_stats.had_error = info?.error?
        store.insert wow.get_calls_collection(), armory_stats, ->
          callback?(info)
      ]

    wowlookup_get_classes = wowlookup.get_classes
    wowlookup.get_classes = (region, callback) ->
      armory_stats = 
        type: "classes"
        region: region
        name: "classes"
        realm: "na"
        start_time: new Date().getTime()
      wowlookup_get_classes.apply wowlookup, [region, (info) ->
        armory_stats.end_time = new Date().getTime()
        armory_stats.error = info?.error
        armory_stats.not_modified = (info is undefined and !armory_stats.error?)
        armory_stats.had_error = info?.error?
        store.insert wow.get_calls_collection(), armory_stats, ->
          callback?(info)
      ]

    wowlookup_get_realms = wowlookup.get_realms
    wowlookup.get_realms = (region, callback) ->
      armory_stats = 
        type: "realms"
        region: region
        name: "realms"
        realm: "na"
        start_time: new Date().getTime()
      wowlookup_get_realms.apply wowlookup, [region, (info) ->
        wf.info "get realms for region #{region} responded, realms:#{info.length}"
        armory_stats.end_time = new Date().getTime()
        armory_stats.error = info?.error
        armory_stats.not_modified = (info is undefined and !armory_stats.error?)
        armory_stats.had_error = info?.error?
        store.insert wow.get_calls_collection(), armory_stats, ->
          callback?(info)
      ]
      

