require "./commonSpec"

Mongodb = require "mongodb"

describe "understand mongo", ->
  it "test1", ->

    # mongo_server = new Mongodb.Server('127.0.0.1',27017)
    # mongo_db = new Mongodb.Db('mongo_spec_db', mongo_server)

    # mongo_open = false
    # runs ->
    #   mongo_db.open (err, client) ->
    #     mongo_open = true
    # waitsFor (-> mongo_open), "open mongo", 1000
    # runs ->
    #   expect(mongo_open).toEqual(true)

    # mongo_db.close(true)


    # mongo_server = new Mongodb.Server('127.0.0.1',27017)
    # mongo_db = new Mongodb.Db('mongo_spec_db', mongo_server)

    # mongo_db.close()

