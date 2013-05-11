process.env.NODE_ENV='test'

i18n = require('i18n')

i18n.configure
  locales:['en_US','es_MX','pt_BR','en_GB','es_ES','fr_FR','ru_RU','de_DE','pt_PT','it_IT','ko_KR','zh_TW','zh_CN']
  defaultLocale: 'en_US'
  directory: 'locales'


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


