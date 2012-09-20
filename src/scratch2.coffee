console.log "--> scratch2"

armory = require('armory').defaults realm:"Darkspear", region: "eu"

require "./store"

store = new wf.Store

armory.guild 
  name:"Mean Girls"
  fields:["members"]
  (err,guild) ->
    dwarvenHairColors = []
    console.log guild
    store.add "meangirls", guild, ->
      guild.members.forEach (member)->
        store.add member.character.name, member.character

    # guild.members.filter((member) -> console.log(member); member.character.race == 3)
    # .map((member) -> member.character.name)
    # .forEach (dwarf) -> 
    # 	console.log dwarf
    # 	armory.character 
    # 		name: dwarf
    # 		fields: ["appearance"]
    # 		(err, character) ->
    # 			console.log dwarf + " has hair of color " + character?.appearance?.hairColor