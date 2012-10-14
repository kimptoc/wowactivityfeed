global.wf ||= {}

armory = require('armory')

require "./store"
require('./init_logger')


store = new wf.Store()

class wf.WowLookup

  constructor: ->
    wf.info "WowLookup constructor"

  get: (type, region, realm, name, result_handler) ->
    wf.debug "Armory lookup #{type} info for #{region}, #{realm}, #{name}"
    switch type
      when "guild"
        armory.guild
          region: region
          realm: realm
          name: name
          fields: ["members","achievements","news","challenge"]
          (err,guild) ->
            if err
              wf.error(JSON.stringify(err))
              result_handler?(
                type: type
                region: region
                realm: realm
                name: name
                error: err.message
                lastModified: 0
                info: "Armory lookup #{type} info for #{region}, #{realm}, #{name}")
            else
              wf.debug "wowlookup result:#{JSON.stringify(guild)}"
              guild.type = type
              guild.region = region
              result_handler?(guild)
      when "member"
        armory.character
          region: region
          realm: realm
          name: name
          fields: ["achievements","guild","feed","hunterPets","professions","progression","pvp","quests","reputation","stats","talents","titles"]
          (err,char) ->
            if err
              wf.error(JSON.stringify(err))
              result_handler?(
                type: type
                region: region
                realm: realm
                name: name
                error: err.message
                lastModified: 0
                info: "Armory lookup #{type} info for #{region}, #{realm}, #{name}")
            else
              wf.debug "wowlookup result:#{JSON.stringify(char)}"
              char.type = type
              char.region = region
              result_handler?(char)
