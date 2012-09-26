global.wf ||= {}

log4js = require "log4js"

log4js.configure('log4js_config.json')

wf.logger = log4js.getLogger()

wf.error = (x) ->
  wf.logger.error(x)

wf.info = (x) ->
  wf.logger.info(x)

wf.debug = (x) ->
  wf.logger.debug(x)
