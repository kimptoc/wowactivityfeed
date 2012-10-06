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

  close: ->
    mongo_db?.close()

  remove_all: (collection_name, removed_handler) ->
    @with_collection collection_name, (coll) ->
      wf.debug "now to remove all"
      coll.remove (err) ->
        wf.error(err) if err
        throw err if err
        removed_handler()

  clear_all: (cleared_handler) ->
    @with_connection (client) ->
      wf.debug "clear_all about to drop db"
      client.dropDatabase (err, was_clear_done) ->
        wf.debug "clear_all completed:#{was_clear_done}"
        wf.error(err) if err
        throw err if err
        cleared_handler?(was_clear_done)

  get_collections: (collections_handler) ->
    @with_connection ->
      wf.mongo_db.collectionNames (err, results) ->
        wf.error(err) if err
        throw err if err
        collections_handler?(results)
        
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

  load: (collection_name, document_key, options, loaded_handler) ->
    @with_collection collection_name, (coll) ->
      options = options or {}
      options["limit"] = -1
      options["batchSize"] = 1
      wf.debug "options:#{JSON.stringify(options)}"
      coll.find document_key, options, (err, cur) ->
        wf.error(err) if err
        throw err if err
        if cur
          cur.toArray (err, docs) ->
            wf.error(err) if err
            throw err if err
            if docs.length >= 1
              loaded_handler?(docs[0])
            else
              wf.error "Did not find any matching documents for key:#{JSON.stringify(document_key)}"
              loaded_handler?(null)
        else
          wf.error "No cursor returned for key:#{JSON.stringify(document_key)}"
          loaded_handler?(null)

  load_all: (collection_name, loaded_handler) ->
    @with_collection collection_name, (coll) ->
      coll.find().toArray (err, results) ->
        wf.error("load_all:#{err}") if err
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
      worker(wf.mongo_db)
    else
      mongo_server = new Mongodb.Server(wf.mongo_info.hostname,wf.mongo_info.port,wf.mongo_info)
      new Mongodb.Db(wf.mongo_info.db, mongo_server).open (err, client) ->
        wf.error(err) if err
        throw err if err
        wf.mongo_db = client
        wf.info "Connected to MongoDB:#{client}"
        worker(client)

