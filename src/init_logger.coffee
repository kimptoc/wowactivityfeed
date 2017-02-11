global.wf ||= {}

path = require "path"
log4js = require "log4js"


wf.logs_collection = "logs"


if process.env.LOG4JS_SYNC
  log4js.configure(path.join('config','log4js_config_sync.json'))
else if process.env.NODE_ENV == "test"
  log4js.configure(path.join('config','log4js_config_test.json'))
else if process.env.NODE_ENV == "production"
  log4js.configure(path.join('config','log4js_config_prod.json'))
else
  log4js.configure(path.join('config','log4js_config.json'))

wf.logger = log4js.getLogger()

store_error = (x, type) ->
  message = x
  stack = ""
  error_arguments = ""
  error_type = ""
  if x instanceof Error
    message = x.message
    stack = x.stack
    error_arguments = x.arguments
    error_type = x.type
  if wf.log_store?
    log_entry =
      timestamp: new Date()
      message: message
      type: type
      stack: stack
      error_arguments: error_arguments
      error_type: error_type
    wf.log_store?.insert wf.logs_collection, log_entry

wf.error = (x) ->
  wf.logger.error(x)
  store_error(x, "ERROR")

wf.warn = (x) ->
  wf.logger.warn(x)
  store_error(x, "WARN")

wf.timing = (x) ->
  wf.logger.warn(x)
  store_error(x, "TIMING")

wf.error_no_store = (x) ->
  wf.logger.error(x)

wf.info = (x) ->
  wf.logger.info(x)

wf.debug = (x) ->
  wf.logger.debug(x)

wf.expressLogger = ->
  log4js.connectLogger(wf.logger)

wf.info "Running in environment:#{process.env.NODE_ENV}"


wf.logging_init = (store) ->
  wf.log_store = store
  store.create_collection wf.logs_collection, capped:true, autoIndexId:true, size: 40000000, (err, result)=>
    wf.info "Created logs collection:#{wf.logs_collection}. #{err}, #{result}"

wf.get_logs = (type, callback) ->
  wf.log_store?.load_all wf.logs_collection, {type}, {limit:50, sort: {timestamp:-1}}, callback
