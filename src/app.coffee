global.wf ?= {}

require './init_nodefly'

express = require('express')
http = require('http')
path = require('path')
moment = require('moment')
_ = require('underscore')
async = require "async"
i18n = require('i18n')


require './init_logger'

require './string'

require './defaults'

require './locale'

require './wow'
require './wow_stats'
require './wow_loader'
require './feed_item_formatter'
require './prettify_json'
require './cron'
require './timing'
require './google_analytics'

sample = (a, n) ->
    return _.take(_.shuffle(a), n)

Array.prototype.sample = (n) -> sample(this, n)


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
  wf.app.set('port', wf.SITE_PORT)
  wf.app.use(express.favicon())  
  # wf.app.use(express.logger('dev'))  
  wf.app.use(wf.expressLogger())

  wf.app.use(require('stylus').middleware(
    src: path.join(__dirname,'..', 'stylus')
    dest: path.join(__dirname,'..', 'public')
  ))

  wf.app.use(express.static(path.join(__dirname,'..', 'public')))

  # default: using 'accept-language' header to guess language settings
  wf.app.use(i18n.init)

  wf.app.locals
    i18n: i18n.__
    i18n_locale: i18n.getLocale

  wf.wow ?= new wf.WoW ->
    wf.wow_stats = new wf.WoWStats()
    wf.wow_loader = new wf.WoWLoader(wf.wow)
    # todo - push this into wow object
    wf.feed_formatter = new wf.FeedItemFormatter()
    # wf.wow.static_load()
    wf.ensure_realms_loaded()


# Routes


wf.app.all '*', (req, res, next) ->
  wf.info "ALL:get #{JSON.stringify(req.route)}"
  next()

wf.app.get '/registered/:locale?', (req, res) ->
  wf.wow.get_registered (results) ->
    res.render "registered", reg: results, locales: wf.i18n_config.locales, root_url: '/registered/'

#wf.app.get '/about', (req, res) ->
#  res.render "about"

wf.app.get '/everyone/:locale?', (req, res) ->
  wf.sort_locale(req,i18n)
  get_feed_all (feed) ->
    res.render "everyone", f: feed, locales: wf.i18n_config.locales, root_url: '/everyone/'

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
#  locale = req.params.locale or wf.REGION_LOCALE[region]
  locale = wf.sort_locale(req,i18n)
  wf.wow.get_history region, realm, type, name, locale, (wowthings) ->
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
        res.render req.params.type,
          p: req.params, w: guild_item, h: wowthings, f: feed,
          fmtdate: ((d) -> moment(d).format("D MMM YYYY H:mm")), locales: wf.regions_to_locales[region], root_url: "/wow/#{region}/#{type}/#{realm}/#{name}/"
    else
      req.params.locale ?= ""
      res.render "#{req.params.type}_not_found",
        msg: i18n.__("Not found - will check the Armory soon %s, %s/%s/%s/%s",type, region, realm, name, locale)
        w: req.params
        p: req.params
        locales: wf.regions_to_locales[region]
        root_url: "/wow/#{region}/#{type}/#{realm}/#{name}/"

wf.app.get '/wow/:region/:type/:realm/:name/:locale?', (req, res) ->
  handle_view(req, res)
  
wf.app.get '/view/:type/:region/:realm/:name/:locale?', (req, res) ->
  handle_view(req, res)

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
 
wf.app.get '/feed/:type/:region/:realm/:name/:locale?.rss', (req, res) ->
  wf.warn "#{req.path}::#{req.header('user-agent')}==#{JSON.stringify(req.headers)}"
  locale = wf.sort_locale(req,i18n)
  wf.ga.trackPage(req.path);
  wf.ga.trackEvent
    action: req.path
    category: req.header('user-agent')
    label: JSON.stringify(req.headers)
    value: 1

  wf.timing_on("/feed/#{req.params.name}")

  type = req.params.type
  type = 'member' if type == "character"
  region = req.params.region.toLowerCase()
  realm = req.params.realm
  name = req.params.name
#  locale = req.params.locale or wf.REGION_LOCALE[region]

  wf.wow.get_history region, realm, type, name, locale, (items)->
    wf.timing_off("/feed/#{name}")
    get_feed items, (items_to_publish) ->
      res.set('Content-Type', 'application/xml')
      res.render "rss", 
        title: i18n.__("WoW Activity Feed for %s",name)
        description: i18n.__("WoW Activity Feed for %s %s, of %s realm %s", type, name, region, realm)
        feed_url: "#{wf.SITE_URL}feed/#{type}/#{encodeURIComponent(region)}/#{encodeURIComponent(realm)}/#{encodeURIComponent(name)}.rss"
        site_url: "#{wf.SITE_URL}view/#{type}/#{encodeURIComponent(region)}/#{encodeURIComponent(realm)}/#{encodeURIComponent(name)}"
        image_url: 'http://www.google.com/icon.png'
        feed:items_to_publish

#wf.app.get '/info', (req, res) ->
#  res.render 'info', info: wf.info_queue, locales: []

#wf.app.get '/feed/info.rss', (req, res) ->
#  res.set('Content-Type', 'application/xml')
#  res.render "rss",
#    title: "WoW Activity Feed Info"
#    description: "WoW Activity Feed Info"
#    feed_url: "#{wf.SITE_URL}feed/info.rss"
#    site_url: "#{wf.SITE_URL}info"
#    image_url: 'http://www.google.com/icon.png'
#    feed:wf.info_queue

wf.app.get '/json/realms', (req, res) ->
  wf.ensure_realms_loaded ->
    res.send JSON.stringify(wf.all_realms)

wf.app.get '/json/get/:type/:region/:realm/:name/:locale?', (req, res) ->
  locale = wf.sort_locale(req,i18n)
  wf.ga.trackPage(req.path);
  wf.ga.trackEvent
    action: req.path
    category: req.header('user-agent')
    label: JSON.stringify(req.headers)
    value: 1

  type = req.params.type
  type = 'member' if type == "character"
  region = req.params.region.toLowerCase()
  realm = req.params.realm
  name = wf.String.capitalise(req.params.name)
#  locale = req.params.locale or wf.REGION_LOCALE[region]
  wf.wow.get_history region, realm, type, name, locale, (items)->
    get_feed items, (items_to_publish) ->
      results = []
      if items? and items.length >0 # might get nothing back, so need to return empty array
        item = items[0] 
        item_lookup = {type, realm, region, name:item.name, locale}
        item_lookup.name = item.guild if type == "guild" and item.guild?
        item.waf_feed = items_to_publish
        item.waf_url = wf.feed_formatter.waf_url(item_lookup)
        item.waf_rss_url = wf.feed_formatter.waf_rss_url(item_lookup)
        item.armory_link = wf.feed_formatter.armory_link(item_lookup)
        item.armory_api_link = wf.feed_formatter.armory_api_link(item_lookup)
        item.wow_type = wf.feed_formatter.wow_type(type)
        item.name = item_lookup.name 
        results.push item
      res.send JSON.stringify(results)


wf.app.get '/debug/wireframe1', (req, res) ->
  res.render "wireframe1" 

wf.app.get '/debug/wireframe2', (req, res) ->
  res.render "wireframe2", locales: null

wf.app.get '/debug/wireframe3', (req, res) ->
  res.render "wireframe3", locales: null

wf.app.get '/debug/wireframe4', (req, res) ->
  res.render "wireframe4", locales: null

wf.app.get '/debug/wireframe5', (req, res) ->
  res.render "wireframe5", locales: null

wf.app.get '/debug/wireframe6', (req, res) ->
  res.render "wireframe6", locales: null

wf.app.get '/debug/wireframe7', (req, res) ->
  res.render "wireframe7", locales: null

wf.app.get '/debug/fonts', (req, res) ->
  res.render "fonts", locales: null

wf.app.get '/debug/colours', (req, res) ->
  res.render "colours", locales: null

wf.app.get '/debug/armory_load', (req, res) ->
  wf.armory_load_requested = true
  wf.wow.get_registered (regs) ->
    res.render "armory_load", res: "Armory load requested - #{regs.length} registered members/guilds", locales: null

wf.app.get '/debug/stats', (req, res) ->
  wf.wow_stats.armory_calls wf.wow, (result) ->
    res.render "message", msg: "<pre>"+wf.syntaxHighlight(JSON.stringify(result, undefined, 4))+"</pre>", locales: wf.i18n_config.locales, root_url: null

wf.app.get '/debug/logs/:type', (req, res) ->
  wf.get_logs req.params.type, (logs) ->
    res.render "logs", {logs, locales: null}

# wf.app.get '/debug/clear_all', (req, res) ->
#  wf.wow.clear_all ->
#    res.render "message", msg: "Database cleared!"

wf.app.get '/debug/sample_data', (req, res) ->
  wf.wow.get_history "eu", "Soulflayer", "guild", "Мб Ро","ru_RU"
  wf.wow.get_history "eu", "Darkspear", "guild", "Mean Girls","en_GB"
  wf.wow.get_history "us", "Earthen Ring", "guild", "alea iacta est","en_US"
  wf.wow.get_history "eu", "Chants éternels", "guild", "La XXVe Armée","fr_FR"
  wf.wow.get_history "eu", "Chants éternels", "guild", "La XXVe Armée","eu_GB"
  wf.wow.get_history "eu", "Darkspear", "member", "Kimptopanda","en_GB"
  wf.wow.get_history "us", "kaelthas", "member", "Feåtherz","pt_BR"
  res.render "message", msg: "Sample data registered", locales: null


wf.app.get '/:locale?', (req, res) ->
  wf.sort_locale(req,i18n)
  get_feed_all (feed)->
    res.render "index", title: 'Home', f: feed.sample(6), locales: wf.i18n_config.locales, root_url: '/'


http.createServer(wf.app).listen(wf.app.get('port'), ->
  wf.info("Express server listening on port " + wf.app.get('port')))