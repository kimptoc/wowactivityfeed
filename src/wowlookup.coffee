global.wf ||= {}

require "./store"
require './init_logger'
portcheck = require 'portchecker'


store = new wf.Store()

class wf.WowLookup

  armory_instance = null

  constructor: ->
    wf.info "WowLookup constructor"

  get_armory: (callback) ->
    if process.env.NODE_ENV == "production"
      wf.info "Its production - dont use a proxy to the armory"
      armory = require('armory')
      callback(armory)
    else
      try
        portcheck.isOpen 8888,"localhost", (is_open)->
          wf.info "Port is open? #{is_open}"
          if is_open
            wf.info "Found the proxy, so use it:#{is_open}"
            armory = require('armory').defaults(request:{proxy:"http://localhost:8888"})
            callback(armory)
          else
            wf.info "Proxy not found, so connecting to armory direct"
            armory = require('armory')
            callback(armory)
      catch e
        wf.info "Proxy not found, so connecting to armory direct:#{e}"
        armory = require('armory')
        callback(armory)

  with_armory: (armory_handler) ->
    if armory_instance?
      armory_handler?(armory_instance)
    else
      @get_armory (armory) ->
        armory_instance = armory
        armory_handler?(armory_instance)

  get: (type, region, realm, name, result_handler) ->
    wf.debug "Armory lookup #{type} info for #{region}, #{realm}, #{name}"
    @with_armory (armory) ->
      switch type
        when "guild"
          armory.guild
            region: region
            realm: realm
            name: name
            fields: ["members","achievements","news","challenge"]
            (err,guild) ->
              if err
                wf.error("wowlookup error:#{err.message} : #{JSON.stringify(err)}")
                result_handler?(
                  type: type
                  region: region
                  realm: realm
                  name: name
                  error: err.message
                  lastModified: 0
                  info: "Armory lookup #{type} info for #{region}, #{realm}, #{name}")
              else
                wf.debug "wowlookup #{name}/#{guild.name} result:#{JSON.stringify(guild)}"
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
                wf.error("wowlookup error:#{err.message} : #{JSON.stringify(err)}")
                result_handler?(
                  type: type
                  region: region
                  realm: realm
                  name: name
                  error: err.message
                  lastModified: 0
                  info: "Armory lookup #{type} info for #{region}, #{realm}, #{name}")
              else
                wf.debug "wowlookup #{name}/#{char.name} result:#{JSON.stringify(char)}"
                char.type = type
                char.region = region
                result_handler?(char)
