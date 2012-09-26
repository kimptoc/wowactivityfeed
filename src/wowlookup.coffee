global.wf ||= {}

armory = require('armory')
require "./store"

store = new wf.Store()

class wf.WowLookup

  guild: (region, realm, guild) ->
    wf.debug "Finding guild info for #{region}, #{realm}, #{guild}"

  get: (type, region, realm, name) ->
    wf.debug "Armory lookup #{type} info for #{region}, #{realm}, #{name}"
    armory.guild
      region: region
      realm: realm
      name: name
      fields:["members","achievements","news"]
      (err,guild) ->
        # console.log "wowlookup result:#{JSON.stringify(guild)}"
        store.add name,guild
