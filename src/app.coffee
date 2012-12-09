global.wf ?= {}

require './init_nodefly'

express = require('express')
http = require('http')
path = require('path')
rss = require('rss')
moment = require('moment')
_ = require('underscore')
async = require "async"

require './init_logger'

require './defaults'

require './wow'
require './feed_item_formatter'
require './prettify_json'
require './cron'
require './timing'
require './google_analytics'


wf.app = express()


wf.app.configure 'development', ->
  wf.info "Express app.configure/development"
  wf.app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))   
  
wf.app.configure 'production', ->
  wf.info "Express app.configure/production"
  wf.SITE_URL = wf.SITE_URL_PROD
  wf.SITE_URL = process.env.SITE_URL if process.env.SITE_URL?
  wf.app.use(express.errorHandler())   

wf.app.configure ->
  wf.info "App Startup/Express configure:env=#{wf.app.get('env')},dirname=#{__dirname}"
  wf.app.set('views', __dirname + '/../views')  
  wf.app.set('view engine', 'jade')  
  wf.app.engine('jade', require('jade').__express)
  wf.app.use(express.bodyParser())  
  wf.app.use(express.methodOverride())  
  wf.app.use(wf.app.router)  
  wf.app.set('port', process.env.VCAP_APP_PORT || process.env.PORT || 3000)
  wf.app.use(express.favicon())  
  # wf.app.use(express.logger('dev'))  
  wf.app.use(wf.expressLogger())

  wf.app.use(require('stylus').middleware(
    src: path.join(__dirname,'..', 'stylus')
    dest: path.join(__dirname,'..', 'public')
  ))  

  wf.app.use(express.static(path.join(__dirname,'..', 'public')))
  wf.wow ?= new wf.WoW()
  # todo - push this into wow object
  wf.feed_formatter = new wf.FeedItemFormatter()
  # wf.wow.static_load()


# Routes
sample = (a, n) ->
    return _.take(_.shuffle(a), n)

Array.prototype.sample = (n) -> sample(this, n)


wf.app.all '*', (req, res, next) ->
  wf.info "ALL:get #{JSON.stringify(req.route)}"
  next()

wf.app.get '/', (req, res) ->
  get_feed_all (feed)->
    res.render "index", title: 'Home', f: feed.sample(6)

wf.app.get '/registered', (req, res) ->
  wf.wow.get_registered (results) ->
    res.render "registered", reg: results

wf.app.get '/about', (req, res) ->
  res.render "about"

wf.app.get '/loaded', (req, res) ->
  get_feed_all (feed) ->
    res.render "loaded", f: feed

get_feed_all = (callback) ->    
  wf.wow.get_loaded (wowthings) ->
    get_feed wowthings, callback

get_feed = (wowthings, req = null, callback) ->
  if 'function' == typeof req
    callback = req
    req = null
  if req? and req.query['ts']?
    filterLastModified = parseInt(req.query['ts'])
  wf.debug "filterLastModified:#{filterLastModified}"
  feed = []
  if wowthings? and wowthings.length > 0
    #wf.debug wowthing
    feed_worker = (item, callback) ->
      # wf.debug "feed_queue; running:#{feed_queue.running()}, queued:#{feed_queue.length()}"
      wf.feed_formatter.process item, (fmt_items) ->
        for fi in fmt_items
          # wf.debug "Checking #{filterLastModified} vs #{fi.date}:#{filterLastModified == parseInt(fi.date)}"
          if  (!filterLastModified?) or filterLastModified == parseInt(fi.date)
            feed.push(fi) 
        callback?()
    # wf.debug "about to do async queue for formatting"
    feed_queue = async.queue feed_worker, 5
    feed_queue.drain = ->
      # wf.debug "feed_queue drain called!"
      feed.sort (a,b) ->
        return b.date - a.date
      feed = feed[0..wf.HISTORY_LIMIT*3]
      callback?(feed)
    for item in wowthings
      feed_queue.push item
  else
    callback?(feed)

build_feed = (items, feed, callback) ->
  get_feed items, (items_to_publish) ->
    for item in items_to_publish[0...wf.HISTORY_LIMIT*3]
      feed.item item
    callback? feed.xml()

handle_view = (req, res) ->
  type = req.params.type
  type = 'member' if type == "character"
  region = req.params.region.toLowerCase()
  realm = req.params.realm
  name = req.params.name
  wf.wow.get_history region, realm, type, name, (wowthings) ->
    if wowthings? and wowthings.length > 0
      get_feed wowthings, req, (feed) ->
        guild_item = null
        if type == "guild"
          for item in wowthings
            wf.debug "Checking type:#{item.type}/#{JSON.stringify(item)}"
            guild_item = item if item.type == "guild" and guild_item == null
        guild_item = wowthings[0] unless guild_item?
        # delete guild_item.whats_changed.changes.news if guild_item.whats_changed.changes.news?
        # delete guild_item.whats_changed.changes.lastModified if guild_item.whats_changed.changes.lastModified?
        # delete guild_item.whats_changed.changes.members if guild_item.whats_changed.changes.members?
        res.render req.params.type, p: req.params, w: guild_item, h: wowthings, f: feed, fmtdate: (d) -> moment(d).format("D MMM YYYY H:mm")
    else
      res.render "message", msg: "Not found - registered for lookup at the Armory #{type}, #{region}/#{realm}/#{name}"

wf.app.get '/wow/:region/:type/:realm/:name', (req, res) ->
  handle_view(req, res)
  
wf.app.get '/view/:type/:region/:realm/:name', (req, res) ->
  handle_view(req, res)

wf.app.get '/feedold/all.rss', (req, res) ->

  feed = new rss
    title: 'WoW Activity Feed'
    description: 'Test all changes feed'
    feed_url: "#{wf.SITE_URL}feed/all.rss"
    site_url: "#{wf.SITE_URL}"
    image_url: 'http://www.google.com/icon.png'

  wf.wow.get_loaded (items) ->
    build_feed items, feed, (xml) ->
      res.set('Content-Type', 'application/xml')
      res.send xml
 
wf.app.get '/feed/all.rss', (req, res) ->
  wf.debug "Tracking:#{req.path}"
  wf.ga.trackPage(req.path);

  wf.wow.get_loaded (items) ->
    get_feed items, (items_to_publish) ->
      res.set('Content-Type', 'application/xml')
      res.render "rss", 
        title: 'WoW Activity Feed'
        description: 'WoW Activity Feed - all changes'
        feed_url: "#{wf.SITE_URL}feed/all.rss"
        site_url: "#{wf.SITE_URL}"
        image_url: 'http://www.google.com/icon.png'
        feed:items_to_publish
 
wf.app.get '/feed/:type/:region/:realm/:name.rss', (req, res) ->
  wf.warn JSON.stringify(req.headers)
  wf.ga.trackPage(req.path);
  wf.ga.trackEvent
    category: req.path
    action: req.headers
    label: req.header('user-agent')
    value: 42

  wf.timing_on("/feed/#{req.params.name}")

  type = req.params.type
  type = 'member' if type == "character"
  region = req.params.region.toLowerCase()
  realm = req.params.realm
  name = req.params.name

  wf.wow.get_history region, realm, type, name, (items)->
    wf.timing_off("/feed/#{name}")
    get_feed items, (items_to_publish) ->
      res.set('Content-Type', 'application/xml')
      res.render "rss", 
        title: "WoW Activity Feed for #{name}"
        description: "WoW Activity Feed for #{type} #{name}, of #{region} realm #{realm}"
        feed_url: "#{wf.SITE_URL}feed/#{type}/#{escape(region)}/#{escape(realm)}/#{escape(name)}.rss"
        site_url: "#{wf.SITE_URL}view/#{type}/#{escape(region)}/#{escape(realm)}/#{escape(name)}"
        image_url: 'http://www.google.com/icon.png'
        feed:items_to_publish

wf.app.get '/feedold/:type/:region/:realm/:name.rss', (req, res) ->

  wf.timing_on("/feedold/#{req.params.name}")

  type = req.params.type
  type = 'member' if type == "character"
  region = req.params.region.toLowerCase()
  realm = req.params.realm
  name = req.params.name

  feed = new rss
    title: "WoW Activity Feed for #{name}"
    description: "WoW Activity Feed for #{type} #{name}, of #{region} realm #{realm}"
    feed_url: "#{wf.SITE_URL}feed/#{type}/#{region}/#{realm}/#{name}.rss"
    site_url: "#{wf.SITE_URL}view/#{type}/#{region}/#{realm}/#{name}"
    image_url: 'http://www.google.com/icon.png'

  wf.wow.get_history region, realm, type, name, (items)->
    wf.timing_off("/feed/#{name}")
    build_feed items, feed, (xml) ->
      res.set('Content-Type', 'application/xml')
      res.send xml

wf.app.get '/debug/search', (req, res) ->
  wf.wow.get_realms (realms) ->
    res.render 'search', {realms}

wf.app.get '/debug/wireframe1', (req, res) ->
  res.render "wireframe1" 

wf.app.get '/debug/wireframe2', (req, res) ->
  res.render "wireframe2" 

wf.app.get '/debug/wireframe3', (req, res) ->
  res.render "wireframe3" 

wf.app.get '/debug/wireframe4', (req, res) ->
  res.render "wireframe4" 

wf.app.get '/debug/wireframe5', (req, res) ->
  res.render "wireframe5" 

wf.app.get '/debug/wireframe6', (req, res) ->
  res.render "wireframe6" 

wf.app.get '/debug/wireframe7', (req, res) ->
  res.render "wireframe7" 

wf.app.get '/debug/fonts', (req, res) ->
  res.render "fonts"

wf.app.get '/debug/colours', (req, res) ->
  res.render "colours"

wf.app.get '/debug/armory_load', (req, res) ->
  wf.armory_load_requested = true
  wf.wow.get_registered (regs) ->
    res.render "armory_load", res: "Armory load requested - #{regs.length} registered members/guilds"

wf.app.get '/debug/statsold', (req, res) ->
  wf.wow.armory_calls_old (result) ->
    res.render "message", msg: "<pre>"+wf.syntaxHighlight(JSON.stringify(result, undefined, 4))+"</pre>"

wf.app.get '/debug/stats', (req, res) ->
  wf.wow.armory_calls (result) ->
    res.render "message", msg: "<pre>"+wf.syntaxHighlight(JSON.stringify(result, undefined, 4))+"</pre>"

wf.app.get '/debug/logs/:type', (req, res) ->
  wf.get_logs req.params.type, (logs) ->
    res.render "logs", {logs}

wf.app.get '/debug/clear_all', (req, res) ->
  wf.wow.clear_all ->
    res.render "message", msg: "Database cleared!"

wf.app.get '/debug/load_realms', (req, res) ->
  wf.wow.realms_loader()
  res.render 'message', msg: "Realms load in progress"

wf.app.get '/debug/sample_data', (req, res) ->
  wf.wow.get_history "eu", "Soulflayer", "guild", "Мб Ро"
  wf.wow.get_history "eu", "Darkspear", "guild", "Mean Girls"
  wf.wow.get_history "us", "Earthen Ring", "guild", "alea iacta est"
  wf.wow.get_history "eu", "Darkspear", "member", "Kimptopanda"
  wf.wow.get_history "us", "kaelthas", "member", "Feåtherz"
  res.render "message", msg: "Sample data registered"


http.createServer(wf.app).listen(wf.app.get('port'), ->
  wf.info("Express server listening on port " + wf.app.get('port')))