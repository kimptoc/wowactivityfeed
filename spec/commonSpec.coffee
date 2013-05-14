process.env.NODE_ENV='test'

i18n = require('i18n')

i18n.configure wf.i18n_config


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


