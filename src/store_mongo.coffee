global.wf ?= {}

async = require "async"
Mongodb = require "mongodb"

require './init_logger'
require './timing'

wf.mongo_db = null

class wf.StoreMongo
  # collection_cache = {}
  mongo_connecting = false

  constructor: ->
    wf.info "StoreMongo.constructor"
    wf.logging_init(this)

  # close: ->
  #   mongo_db?.close()

  remove_all: (collection_name, removed_handler) ->
    wf.debug "about to get collection: #{collection_name}"
    @with_collection collection_name, (coll) ->
      wf.debug "now to remove all '#{collection_name}'"
      coll.remove {}, safe:true, (err) ->
        if err
          wf.error "Problem removing all for '#{collection_name}'"
          wf.error(err)
        else
          wf.info "Successfully removed all for '#{collection_name}'"
        removed_handler?()

  ensure_index: (collection_name, fieldSpec, options, callback) ->
    @with_collection collection_name, (coll) ->
      options ?= {}
      options["unique"] ?= true
      options["safe"] ?= true
      coll.ensureIndex fieldSpec, options, (err, index_name) ->
        wf.error(err) if err
        wf.debug "Trying to create index on #{collection_name} - maybe did it:#{index_name}"
        callback?(index_name)

  add: (collection_name, document_object, stored_handler) ->
    @insert collection_name, document_object, (coll)->
      if coll?
        coll.find document_object, (err, cur) ->
          if err
            wf.error(err)
            stored_handler?(null)
          else
            cur.count (err, count) ->
              if err
                wf.error(err)
                stored_handler?(null)
              else
                stored_handler?(count)
      else
        stored_handler?(null)

  insert: (collection_name, document_object, stored_handler) ->
    wf.debug "debug to do insert"
    @with_collection collection_name, (coll) ->
      wf.debug "about to do insert/got collection:#{collection_name}:#{document_object?.name}-#{document_object?.region}:#{JSON.stringify(document_object)}"
      coll.insert document_object, safe:true, (err, docs) ->
        wf.debug "about to do insert/insert returned"
        if err
          wf.error "insert/got an error trying to save:#{collection_name}/#{document_object}"
          wf.error(err)
          stored_handler?(null)
        else
          wf.debug "saved in #{collection_name}:#{document_object}"
          stored_handler?(coll)

  insert_many: (collection_name, documents, stored_handler) ->
    wf.debug "about to do insert_many"
    @with_collection collection_name, (coll) ->
      wf.debug "about to do insert_many/got collection:#{collection_name}:#{documents?.length}:#{JSON.stringify(documents)}"
      coll.insertMany documents, safe:true, (err, docs) ->
        wf.debug "about to do insert_many/insert returned"
        if err
          wf.error "insert_many/got an error trying to save:#{collection_name}/#{JSON.stringify(documents)}"
          wf.error(err)
          stored_handler?(null)
        else
          wf.debug "insert_many/saved in #{collection_name}:#{documents}"
          stored_handler?(coll)

  insert_one: (collection_name, document, stored_handler) ->
    wf.debug "about to do insert_one"
    @with_collection collection_name, (coll) ->
      wf.debug "about to do insert_one/got collection:#{collection_name}:#{JSON.stringify(document)}"
      coll.insertOne document, safe:true, (err, docs) ->
        wf.debug "about to do insert_one/insert returned"
        if err
          wf.error "insert_one/got an error trying to save:#{collection_name}/#{JSON.stringify(document)}"
          wf.error(err)
          stored_handler?(null)
        else
          wf.debug "insert_one/saved in #{collection_name}:#{JSON.stringify(document)}"
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
        if err
          wf.error(err)
        stored_handler?(null)

  remove: (collection_name, document_key, callback) ->
    @with_collection collection_name, (coll) ->
      coll.remove document_key, safe:true, (err, count) ->
        wf.error(err) if err
        wf.debug "removed:#{JSON.stringify(document_key)}, ok:#{!err?}"
        callback?(count)

  update: (collection_name, document_key, new_document, update_handler) ->
    @with_collection collection_name, (coll) ->
      coll.update document_key, new_document, safe:true, (err, docs) ->
        wf.error(err) if err
        wf.debug "updated:#{JSON.stringify(new_document)}, ok:#{!err?}"
        update_handler?()

  count: (collection_name, document_key, count_handler) ->
    @with_collection (collection_name), (coll) ->
      coll.find document_key, (err, cur) ->
        wf.error(err) if err
        cur.count (err, count) ->
          wf.error(err) if err
          count_handler?(count)

  load: (collection_name, document_key, options, loaded_handler) ->
    wf.error "Collection name is null" unless collection_name?
    @with_collection collection_name, (coll) ->
      options ?= {}
      options["limit"] ?= -1
      options["batchSize"] ?= 1
      wf.debug "load:coll:#{collection_name}, key:#{JSON.stringify(document_key)}, options:#{JSON.stringify(options)}"
      coll.find document_key, options, (err, cur) ->
        if err
          wf.error(err)
          loaded_handler?(null)
        else if cur
          cur.toArray (err, docs) ->
            if err
              wf.error(err) if err
              loaded_handler?(null)
            else if docs.length >= 1
              loaded_handler?(docs[0])
            else
              wf.info "In collection #{collection_name} did not find any matching for key:#{JSON.stringify(document_key)}"
              loaded_handler?(null)
        else
          wf.error "No cursor returned for coll: #{collection_name} key:#{JSON.stringify(document_key)}"
          loaded_handler?(null)

  load_all: (collection_name, document_key, options, loaded_handler) ->
    @load_all_with_fields collection_name, document_key, undefined, options, loaded_handler

  load_all_with_fields: (collection_name, document_key, fields, options, loaded_handler) ->
    wf.timing_on("load_all:#{collection_name}, fields:#{JSON.stringify(fields)}")
    @with_collection collection_name, (coll) ->
      wf.info "load_all, got collection:#{collection_name}, options:#{JSON.stringify(options)}, now query by key:#{JSON.stringify(document_key)}"
      coll.find document_key, fields, options, (err, cur) ->
        wf.debug "load_all, got collection:#{collection_name} contents"
        if err
          wf.error("load_all:#{err}")
          loaded_handler?(null)
        else
          cur.toArray (err, docs) ->
            wf.timing_off("load_all:#{collection_name}, fields:#{JSON.stringify(fields)}")
            wf.debug "load_all, got collection:#{collection_name} contents, now as array, err:#{err}"
            if err
              wf.error(err)
              loaded_handler?(null)
            else
              wf.debug "load_all/2, got collection:#{collection_name} contents, now as array(#{docs.length}), err:#{err}"
              loaded_handler?(docs)


  aggregate: (collection_name, pipeline, options, callback) ->
    @with_collection collection_name, (coll) ->
    # @with_connection (db) ->
      # coll.count (err, result) ->
      #   wf.debug "Agg count:#{result}"
      # db.command aggregate: collection_name, pipeline: pipeline, (err, results) ->
      coll.aggregate pipeline, options, (err, results) ->
        if err
          wf.error("aggregate:#{err}")
        callback?(results)

  dbstats: (coll_array, callback) ->
    results = {}
    @with_connection (db) =>
      db.stats {scale:1000000},(err,stats) =>
        wf.error(err) if err
        results.dbstats = stats
        get_coll_stats = (name, coll_callback) =>
          @with_collection name, (coll) ->
            coll.stats {scale:1000000}, (err,cstats) =>
              wf.error(err) if err
              results[name] = cstats
              coll_callback?()
        async.forEach coll_array, get_coll_stats, ->
          callback?(results)

  with_collection: (collection_name, worker) ->
    @with_connection ->
      # return worker?(collection_cache[collection_name]) if collection_cache[collection_name]
      wf.mongo_db.collection collection_name, (err, coll) ->
        if err
          wf.error_no_store(err)
          worker?(null)
        else
          # collection_cache[collection_name] ?= coll
          worker?(coll)

  with_connection: (worker) ->
    if wf.mongo_db
      worker(wf.mongo_db)
    else
      if mongo_connecting
        # todo - handle this properly... probably some async tool
        wf.error_no_store("already opening connecting, try again later...")
        setTimeout (=> @with_connection(worker)), 100
        return
      mongo_connecting = true
      servers = new Array()
      mongo_server = new Mongodb.Server(wf.mongo_info.hostname,wf.mongo_info.port,wf.mongo_info)
      servers[0] = mongo_server
      if wf.mongo_info1?
        mongo_server1 = new Mongodb.Server(wf.mongo_info1.hostname,wf.mongo_info1.port,wf.mongo_info1)
        servers[1] = mongo_server1
        mongo_server = new Mongodb.ReplSet(servers)
      wf.info "Connecting to MongoDB:#{servers[0].host}:#{servers[0].port}, using #{servers.length} servers"
      new Mongodb.Db(wf.mongo_info.db, mongo_server, safe:true).open (err, client) ->
        if err
          wf.error_no_store(err)
          worker?(null)
        else if wf.mongo_info.username? and wf.mongo_info.username.length >0
          wf.info "Have username, so calling authenticate...."
          client.authenticate wf.mongo_info.username,wf.mongo_info.password, (err, reply) ->
            if err
              wf.error_no_store(err)
              worker?(null)
            else
              wf.mongo_db = client
              wf.info "Connected and logged in to MongoDB:#{client}"
              mongo_connecting = false
              worker?(client)
        else
          wf.mongo_db = client
          wf.info "Connected to MongoDB:#{client}"
          mongo_connecting = false
          worker?(client)
