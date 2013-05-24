process.env.NODE_ENV='test'

require './locale'
require "./wow"

beforeEach (done) ->

  wf.info "========================================================="
  wf.info "==============      TEST BEGINS         ================="
  wf.info "========================================================="

  wf.mongo_info = 
    "hostname":"localhost"
    "port":27017
    "username":""
    "password":""
    "name":""
    "db":"wowfeed-test"

  new wf.WoW (wow)->
    wf.info "Created Test WoW object!"
    wf.wow = wow
    wow.clear_all ->
      done()

