global.wf ||= {}

Mongodb = require "mongodb"

require('./init_logger')

wf.mongo_db = null

class wf.StoreMongo
  mongo_server = null
  mongo_client = null
  collection_cache = {}

  constructor: ->
    wf.info "StoreMongo.constructor"
    mongo_server = new Mongodb.Server('127.0.0.1',27017)

  close: ->
    mongo_db?.close()

  remove_all: (collection_name, removed_handler) ->
    @with_collection collection_name, (coll) ->
      wf.debug "now to remove all"
      coll.remove (err) ->
        wf.error(err) if err
        removed_handler()

  get_collections: (collections_handler) ->
    @with_connection ->
      wf.mongo_db.collectionNames (err, results) ->
        wf.error(err) if err
        throw err if err
        collections_handler(results)
        
  add: (collection_name, document_object, stored_handler) ->
    @with_collection collection_name, (coll) ->
      coll.insert document_object, safe:true, (err, docs) ->
        wf.error(err) if err
        throw err if err
        wf.debug "saved:#{document_object}"
        coll.find document_object, (err, cur) ->
          wf.error(err) if err
          throw err if err
          cur.count (err, count) ->
            wf.error(err) if err
            throw err if err
            stored_handler?(count)

  count: (collection_name, document_key, count_handler) ->
    @with_collection (collection_name), (coll) ->
      coll.find document_key, (err, cur) ->
        wf.error(err) if err
        cur.count (err, count) ->
          wf.error(err) if err
          count_handler?(count)

  load: (collection_name, document_key, loaded_handler) ->
    @with_collection collection_name, (coll) ->
      coll.findOne document_key, (err, doc) ->
        wf.error(err) if err
        throw err if err
        loaded_handler?(doc)

  load_all: (collection_name, loaded_handler) ->
    @with_collection collection_name, (coll) ->
      coll.find().toArray (err, results) ->
        wf.error(err) if err
        throw err if err
        loaded_handler?(results)
  
  with_collection: (collection_name, worker) ->
    @with_connection ->
      return worker?(collection_cache[collection_name]) if collection_cache[collection_name]
      wf.mongo_db.collection collection_name, (err, coll) ->
        wf.error(err) if err
        throw err if err
        collection_cache[collection_name] ?= coll 
        worker?(coll)

  with_connection: (worker) ->
    if wf.mongo_db
      worker()
    else
      new Mongodb.Db('wowfeed', mongo_server).open (err, client) ->
        wf.error(err) if err
        throw err if err
        wf.mongo_db = client
        wf.info "Connected to MongoDB"
        worker()

