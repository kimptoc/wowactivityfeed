global.wf ||= {}

Mongodb = require "mongodb"

require './init_logger'
require './timing'

wf.mongo_db = null

class wf.StoreMongo
  collection_cache = {}
  mongo_connecting = false

  constructor: ->
    wf.info "StoreMongo.constructor"

  close: ->
    mongo_db?.close()

  remove_all: (collection_name, removed_handler) ->
    @with_collection collection_name, (coll) ->
      wf.debug "now to remove all '#{collection_name}'"
      coll.remove (err) ->
        wf.error(err) if err
        throw err if err
        removed_handler?()

  # get_loaded: (loaded_handler) ->
  #   @with_connection ->
  #     wf.mongo_db.collectionNames namesOnly:true, (err, results) ->
  #       wf.error(err) if err
  #       throw err if err
  #       wowthings = results.filter (thing) ->
  #         wf.debug "thing:#{JSON.stringify(thing)}"
  #         thing.indexOf("wowitem") >= 0
  #       wowthings = wowthings.map (thing) ->
  #         thing.substring(thing.indexOf(".")+1)
  #       loaded_handler?(wowthings)

  ensure_index: (collection_name, fieldSpec, callback) ->
    @with_collection collection_name, (coll) ->
      coll.ensureIndex fieldSpec, {unique: true, safe: true}, callback
      
  add: (collection_name, document_object, stored_handler) ->
    @insert collection_name, document_object, (coll)->
      coll.find document_object, (err, cur) ->
        wf.error(err) if err
        throw err if err
        cur.count (err, count) ->
          wf.error(err) if err
          throw err if err
          stored_handler?(count)

  insert: (collection_name, document_object, stored_handler) ->
    @with_collection collection_name, (coll) ->
      coll.insert document_object, safe:true, (err, docs) ->
        wf.error(err) if err
        throw err if err
        wf.debug "saved:#{document_object}"
        stored_handler?(coll)

  create_collection: (collection_name, options, callback) ->
    @with_connection ->
      wf.mongo_db.createCollection(collection_name, options, callback)

  drop_collection: (collection_name, callback) ->
    @with_connection ->
      wf.mongo_db.dropCollection(collection_name, callback)

  upsert: (collection_name, document_key, document_object, stored_handler) ->
    @with_collection collection_name, (coll) ->
      coll.update document_key, document_object, {safe:true, upsert:true}, (err, docs) ->
        wf.error(err) if err
        throw err if err
        wf.debug "saved:#{document_object}"
        coll.find document_key, (err, cur) ->
          wf.error(err) if err
          throw err if err
          cur.count (err, count) ->
            wf.error(err) if err
            throw err if err
            stored_handler?(count)

  remove: (collection_name, document_key, callback) ->
    @with_collection collection_name, (coll) ->
      coll.remove document_key, safe:true, (err, docs) ->
        wf.error(err) if err
        throw err if err
        wf.debug "removed:#{JSON.stringify(document_key)}"
        callback?()

  update: (collection_name, document_key, new_document, update_handler) ->
    @with_collection collection_name, (coll) ->
      coll.update document_key, new_document, safe:true, (err, docs) ->
        wf.error(err) if err
        throw err if err
        wf.debug "updated:#{JSON.stringify(new_document)}"
        update_handler?()

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
      wf.debug "load:coll:#{collection_name}, key:#{JSON.stringify(document_key)}, options:#{JSON.stringify(options)}"
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
              wf.error "In collection #{collection_name} did not find any matching for key:#{JSON.stringify(document_key)}"
              loaded_handler?(null)
        else
          wf.error "No cursor returned for coll: #{collection_name} key:#{JSON.stringify(document_key)}"
          loaded_handler?(null)

  load_all: (collection_name, document_key, options, loaded_handler) ->
    @load_all_with_fields collection_name, document_key, undefined, options, loaded_handler

  load_all_with_fields: (collection_name, document_key, fields, options, loaded_handler) ->
    wf.timing_on("load_all-#{collection_name}")
    @with_collection collection_name, (coll) ->
      wf.debug "load_all, got collection:#{collection_name}, now query by key:#{JSON.stringify(document_key)}"
      coll.find document_key, fields, options, (err, cur) ->
        wf.debug "load_all, got collection:#{collection_name} contents"
        wf.error("load_all:#{err}") if err
        throw err if err
        cur.toArray (err, docs) ->
          wf.timing_off("load_all-#{collection_name}")
          wf.debug "load_all, got collection:#{collection_name} contents, now as array, err:#{err}"
          wf.error(err) if err
          throw err if err
          wf.debug "load_all/2, got collection:#{collection_name} contents, now as array(#{docs.length}), err:#{err}"
          loaded_handler?(docs)
  
  dbstats: (coll1, coll2, coll3, callback) ->
    results = {}
    @with_connection (db) =>
      db.stats {scale:1000000},(err,stats) =>
        wf.error(err) if err
        throw err if err
        results.dbstats = stats
        if coll1?
          @with_collection coll1, (coll) =>
            coll.stats {scale:1000000}, (err,cstats1) =>
              wf.error(err) if err
              throw err if err
              results[coll1] = cstats1
              if coll2?
                @with_collection coll2, (coll) =>
                  coll.stats {scale:1000000}, (err,cstats2) =>
                    wf.error(err) if err
                    throw err if err
                    results[coll2] = cstats2
                    if coll3?
                      @with_collection coll3, (coll) ->
                        coll.stats {scale:1000000}, (err,cstats3) ->
                          wf.error(err) if err
                          throw err if err
                          results[coll3] = cstats3
                          callback?(results)
                    else
                      callback?(results)
              else
                callback?(results)
        else
          callback?(results)

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
      if mongo_connecting
        # todo - handle this properly... probably some async tool
        wf.error("already opening connecting, try again later...")
        setTimeout (=> @with_connection(worker)), 5000
        return
      mongo_connecting = true
      mongo_server = new Mongodb.Server(wf.mongo_info.hostname,wf.mongo_info.port,wf.mongo_info)
      new Mongodb.Db(wf.mongo_info.db, mongo_server, safe:true).open (err, client) ->
        wf.error(err) if err
        throw err if err
        if wf.mongo_info.username? and wf.mongo_info.username.length >0
          wf.info "Have username, so calling authenticate...."
          client.authenticate wf.mongo_info.username,wf.mongo_info.password, (err, reply) ->
            wf.error(err) if err
            throw err if err
            wf.mongo_db = client
            wf.info "Connected and logged in to MongoDB:#{client}"
            mongo_connecting = false
            worker?(client)
        else
          wf.mongo_db = client
          wf.info "Connected to MongoDB:#{client}"
          mongo_connecting = false
          worker?(client)

