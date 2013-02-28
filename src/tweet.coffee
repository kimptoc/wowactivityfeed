global.wf ||= {}

Twit = require "twit"

require "./defaults"

require './init_logger'

class wf.Tweet

  constructor: (callback)->
    wf.info "wf.Tweet ctor"
    if process.env.WAF_CONSUMER_KEY?
      @twit = new Twit
        consumer_key:         process.env.WAF_CONSUMER_KEY
        consumer_secret:      process.env.WAF_CONSUMER_SECRET
        access_token:         process.env.WAF_ACCESS_TOKEN
        access_token_secret:  process.env.WAF_ACCESS_TOKEN_SECRET

  update: (message, callback) ->
    wf.debug "Sending Tweet update:#{message}"
    if @twit?
      @twit.post 'statuses/update', { status: message }, (err, reply)->
        wf.error JSON.stringify(err) if err?
        wf.debug JSON.stringify(reply) if reply?
    else
      wf.info "No twitter consumer_key - so not tweeting!"