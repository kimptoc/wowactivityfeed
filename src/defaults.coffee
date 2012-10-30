global.wf ||= {}

wf.SITE_URL = "http://localhost:3000"
wf.SITE_URL_PROD = "http://waf1.eu01.aws.af.cm/"
wf.HISTORY_LIMIT = 10
wf.HISTORY_SAVE_LIMIT = 5
wf.ARMORY_CALL_THREADS = 6
wf.ITEM_LOADER_THREADS = 6
wf.ARMORY_CALL_TIMEOUT = 30000
# wf.REGISTERED_ITEM_TIMEOUT = 60*1  # 1 mins
wf.REGISTERED_ITEM_TIMEOUT = 60*60*24*7   # 7 days

wf.mongo_info = 
    "hostname":"localhost"
    "port":27017
    "username":""
    "password":""
    "name":""
    "db":"wowfeed"

