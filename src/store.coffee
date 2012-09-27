global.wf ||= {}

fs = require "fs"

require('./init_logger')


#crude filesystem store
class wf.Store
  storeDir = "./store"

  constructor: (rootDir)->
    storeDir = rootDir if rootDir
    
  add: (key, obj, okHandler)->
    wf.debug "saving #{key}, object:"
    # wf.debug obj
    data = JSON.stringify(obj);
    fs.writeFile "#{storeDir}/#{key}.json", data,  (err) ->
        if (err) 
            wf.error('There has been an error saving your configuration data.')
            wf.error(err.message)
            return
        wf.debug('Object saved successfully.')
        okHandler?()

  load: (key)->
    wf.debug "loading #{key}"
    try 
      data = fs.readFileSync "#{storeDir}/#{key}.json"
      myObj = JSON.parse(data)
    catch err
      wf.error('There has been an error parsing your JSON.')
      wf.error(err)
    return myObj
