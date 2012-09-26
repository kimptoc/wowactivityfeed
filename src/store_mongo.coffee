global.wf ||= {}

Mongodb = require "mongodb"

require('./init_logger')

#crude filesystem store
class wf.StoreMongo
  mongo_server = null
  mongo_db = null
  mongo_client = null

  constructor: ->
    wf.info "StoreMongo.constructor"
    mongo_server = new Mongodb.Server('127.0.0.1',27017)
    mongo_db = new Mongodb.Db('wowfeed', mongo_server)

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

