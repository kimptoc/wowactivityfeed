global.wf ||= {}

Mongodb = require "mongodb"

#crude filesystem store
class wf.StoreMongo
  mongo_server = null
  mongo_db = null
  mongo_client = null

  constructor: ->
    console.log "StoreMongo.constructor"
    mongo_server = new Mongodb.Server('127.0.0.1',27017)
    mongo_db = new Mongodb.Db('wowfeed', mongo_server)
    # mongo_db.open (err, client) ->
    #   throw err if err
    #   mongo_client = client
    #   console.log "Connected to MongoDB"

  add: (collection_name, document_object, stored_handler) ->
    @with_connection ->
      mongo_db.collection collection_name, (err, coll) ->
        coll.insert document_object, (err, docs) ->
          throw err if err
          wf.debug "saved:#{document_object}"
          stored_handler?()

  load: (collection_name, document_key, loaded_handler) ->
    @with_connection ->
      mongo_db.collection collection_name, (err, coll) ->
        coll.findOne document_key, (err, doc) ->
          throw err if err
          loaded_handler?(doc)

  load_all: (collection_name, loaded_handler) ->
    @with_connection ->
      mongo_db.collection collection_name, (err, coll) ->
        results = []
        coll.forEach (element) ->
          results.push element
        return results    
  
  with_connection: (worker) ->
    if mongo_client
      worker()
    else
      mongo_db.open (err, client) ->
        throw err if err
        mongo_client = client
        wf.info "Connected to MongoDB"
        worker()

  # add: (key, obj, okHandler)->
    # console.log "saving #{key}, object:"
    # console.log obj
    # data = JSON.stringify(obj);
    # fs.writeFile "#{storeDir}/#{key}.json", data,  (err) ->
    #     if (err) 
    #         console.log('There has been an error saving your configuration data.')
    #         console.log(err.message)
    #         return
    #     console.log('Object saved successfully.')
    #     okHandler?()

  # load: (key)->
  #   console.log "loading #{key}"
  #   try 
  #     data = fs.readFileSync "#{storeDir}/#{key}.json"
  #     myObj = JSON.parse(data)
  #     # console.dir(myObj)
  #   catch err
  #     console.log('There has been an error parsing your JSON.')
  #     console.log(err)
  #   return myObj
