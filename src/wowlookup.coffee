global.wf ||= {}

armory = require('armory')
require "./store"

store = new wf.Store()

class wf.WowLookup

  guild: (region, realm, guild) ->
    console.log "Finding guild info for #{region}, #{realm}, #{guild}"

  get: (type, region, realm, name) ->
    console.log "Armory lookup #{type} info for #{region}, #{realm}, #{name}"
    armory.guild
      region: region
      realm: realm
      name: name
      fields:["members","achievements","news"]
      (err,guild) ->
        console.log "wowlookup result:#{JSON.stringify(guild)}"
        store.add name,guild
