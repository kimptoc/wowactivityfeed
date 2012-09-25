global.wf ||= {}

require "./store"

store = new wf.Store()

# this an in memory cache of the latest guild/char details
class wf.WoW

  get: (region, realm, type, name)->
    if type == "guild" or type == "member"
      store.load name
    else
      name : "Dummy"