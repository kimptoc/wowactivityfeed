global.wf ||= {}

wf.SITE_PORT = process.env.VCAP_APP_PORT || process.env.PORT || 4000
wf.SITE_URL = "http://localhost:#{wf.SITE_PORT}"
wf.SITE_URL_PROD = "http://waf1.eu01.aws.af.cm/"
wf.HISTORY_LIMIT = 12
wf.HISTORY_SAVE_LIMIT = 4
wf.ARMORY_CALL_THREADS = 6
wf.ITEM_LOADER_THREADS = 6
wf.ARMORY_CALL_TIMEOUT = 30000
# wf.REGISTERED_ITEM_TIMEOUT = 60*1  # 1 mins
wf.REGISTERED_ITEM_TIMEOUT = 60*60*24*7   # 7 days
wf.ARCHIVED_ITEM_TIMEOUT = 60*60*24 # 1 day
wf.ACCESSED_ITEM_TIMEOUT = 60*60*24*7   # 7 days

wf.WOW_API_PUBLIC_KEY = process.env.WOW_API_PUBLIC_KEY
wf.WOW_API_PRIVATE_KEY = process.env.WOW_API_PRIVATE_KEY

wf.info "WOW/Public:#{wf.WOW_API_PUBLIC_KEY}"
wf.info "WOW/Private:#{wf.WOW_API_PRIVATE_KEY}"

wf.mongo_info = 
    "hostname":"localhost"
    "port":27017
    "username":""
    "password":""
    "name":""
    "db":"wowfeed"

if process.env.MONGODB_P708DEFAULT_URL?
  dbparts = /mongodb:\/\/(.*):(.*)@(.*)\/(.*)/.exec(process.env.MONGODB_P708DEFAULT_URL)
  wf.mongo_info.hostname = dbparts[3]
  wf.mongo_info.username = dbparts[1]
  wf.mongo_info.password = dbparts[2]
  wf.mongo_info.db = dbparts[4]
  wf.info "Looks like a pogoapp host:#{process.env.MONGODB_P708DEFAULT_URL}/#{JSON.stringify(wf.mongo_info)}"
else if process.env.MONGO_HOST?
  wf.info "Found MONGO_HOST, using that"
  wf.mongo_info = {}
  wf.mongo_info.hostname = process.env.MONGO_HOST
  wf.mongo_info.port = parseInt(process.env.MONGO_PORT)
  wf.mongo_info.username = process.env.MONGO_USER
  wf.mongo_info.password = process.env.MONGO_PW
  wf.mongo_info.db = process.env.MONGO_DB
else if process.env.VCAP_SERVICES?
  wf.info "No MONGO_HOST, using #{process.env.VCAP_SERVICES}"
  env = JSON.parse(process.env.VCAP_SERVICES)
  wf.mongo_info = env['mongodb-1.8'][0]['credentials']
