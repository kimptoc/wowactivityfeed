process.env.NODE_ENV='test'

require './locale'

beforeEach ->
  wf.info "========================================================="
  wf.info "==============      TESTS BEGIN         ================="
  wf.info "========================================================="

  wf.mongo_info = 
    "hostname":"localhost"
    "port":27017
    "username":""
    "password":""
    "name":""
    "db":"wowfeed-test"


