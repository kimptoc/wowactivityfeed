global.wf ||= {}

fs = require "fs"

#crude filesystem store
class wf.Store
  storeDir = "./store"

  constructor: (rootDir)->
    storeDir = rootDir if rootDir
    
  add: (key, obj, okHandler)->
    console.log "saving #{key}, object:"
    # console.log obj
    data = JSON.stringify(obj);
    fs.writeFile "#{storeDir}/#{key}.json", data,  (err) ->
        if (err) 
            console.log('There has been an error saving your configuration data.')
            console.log(err.message)
            return
        console.log('Object saved successfully.')
        okHandler?()

  load: (key)->
    console.log "loading #{key}"
    data = fs.readFileSync "#{storeDir}/#{key}.json"
    try 
      myObj = JSON.parse(data)
      # console.dir(myObj)
    catch err
      console.log('There has been an error parsing your JSON.')
      console.log(err)
    return myObj
