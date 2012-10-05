require "./commonSpec"

describe "Is this run first?", ->
  it "init...", ->
    wf.info "========================================================="
    wf.info "==============      TESTS BEGIN         ================="
    wf.info "========================================================="

    wf.mongo_info = 
      "hostname":"localhost"
      "port":27017
      "username":""
      "password":""
      "name":""
      "db":"db"
