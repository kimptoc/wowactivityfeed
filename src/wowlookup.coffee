global.wf ||= {}

armory = require('armory')

require "./store"
require('./init_logger')


store = new wf.Store()

class wf.WowLookup

  constructor: ->
    wf.info "WowLookup constructor"

  guild: (region, realm, guild) ->
    wf.debug "Finding guild info for #{region}, #{realm}, #{guild}"

  get: (type, region, realm, name, result_handler) ->
    wf.debug "Armory lookup #{type} info for #{region}, #{realm}, #{name}"
    switch type
      when "guild"
        armory.guild
          region: region
          realm: realm
          name: name
          fields: ["members","achievements","news"]
          (err,guild) ->
            if err
              wf.error(JSON.stringify(err))
              result_handler?(error: err.message, info: "Armory lookup #{type} info for #{region}, #{realm}, #{name}")
            else
              wf.debug "wowlookup result:#{JSON.stringify(guild)}"
              result_handler?(guild)
      when "member"
        armory.character
          region: region
          realm: realm
          name: name
          fields: ["achievements"]
          (err,char) ->
            if err
              wf.error(JSON.stringify(err))
              result_handler?(error: err.message, info: "Armory lookup #{type} info for #{region}, #{realm}, #{name}")
            else
              wf.debug "wowlookup result:#{JSON.stringify(char)}"
              result_handler?(char)
