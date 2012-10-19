global.wf ||= {}

express = require('express')
http = require('http')
path = require('path')
rss = require('rss')
cronJob = require('cron').CronJob

require './init_logger'
require './wow'
require './feed_item_formatter'

#wf.app = express()

wf.SITE_URL = "http://localhost:3000"
wf.SITE_URL_PROD = "http://waf1.eu01.aws.af.cm/"
wf.HISTORY_LIMIT = 60

app = module.exports = express()

wf.app = app

# Configuration

wf.armory_load_requested = false

wf.hourlyjob = new cronJob '00 55 * * * *', (-> 
  wf.info "cronjob tick...hourly load"
  wf.armory_load_requested = true
  ),
  null, 
  true, #/* Start the job right now */,
  null #/* Time zone of this job. */

wf.loadjob = new cronJob '*/10 * * * * *', (-> 
  wf.debug "cronjob tick...check if armory load requested"
  if wf.armory_load_requested
    wf.armory_load_requested = false
    wf.info "time for armory_load..."
    wf.app.wow.armory_load()
  ),
  null, 
  true, #/* Start the job right now */,
  null #/* Time zone of this job. */

# wf.staticjob = new cronJob '00 00 00 * * *', (-> 
#   wf.debug "cronjob tick...load armory static"
#   wf.app.wow.static_load()
#   ),
#   null, 
#   true, #/* Start the job right now */,
#   null #/* Time zone of this job. */

wf.app.configure ->
  wf.info "App Startup/Express configure:env=#{app.get('env')},dirname=#{__dirname}"
  wf.app.set('views', __dirname + '/../views')  
  wf.app.set('view engine', 'jade')  
  wf.app.engine('jade', require('jade').__express)
  wf.app.use(express.bodyParser())  
  wf.app.use(express.methodOverride())  
  wf.app.use(wf.app.router)  
  wf.app.set('port', process.env.VCAP_APP_PORT || 3000)  
  wf.app.use(express.favicon())  
  # wf.app.use(express.logger('dev'))  
  wf.app.use(wf.expressLogger())

  wf.app.use(require('stylus').middleware(path.join(__dirname,'..', 'public')))  
  wf.app.use(express.static(path.join(__dirname,'..', 'public')))
  wf.app.wow = new wf.WoW()
  wf.app.feed_formatter = new wf.FeedItemFormatter()
  # wf.app.wow.static_load()


wf.app.configure 'development', ->
  wf.info "Express app.configure/development"
  wf.mongo_info = 
      "hostname":"localhost"
      "port":27017
      "username":""
      "password":""
      "name":""
      "db":"wowfeed"
  wf.app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))   
  
wf.app.configure 'production', ->
  wf.info "Express app.configure/production"
  wf.SITE_URL = wf.SITE_URL_PROD
  if process.env.VCAP_SERVICES?
    env = JSON.parse(process.env.VCAP_SERVICES)
    wf.mongo_info = env['mongodb-1.8'][0]['credentials']
    wf.app.use(express.errorHandler())   

# Routes

wf.app.get '/', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  res.render 'index', title: 'Home'
#    res.send 'Hello from WoW Feed2'

wf.app.get '/armory_load', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.armory_load_requested = true
  wf.app.wow.get_registered (regs) ->
    res.render "armory_load", res: "Armory load requested - #{regs.length} registered members/guilds"

wf.app.get '/registered', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.get_registered (results) ->
    res.render "registered", reg: results

wf.app.get '/loaded', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.get_loaded (results) ->
    #TODO - get latest entry in each, only feed collections
    res.render "loaded", colls: results

build_feed = (items, feed) ->
  items_to_publish = []
  for item in items
    formatted_items = wf.app.feed_formatter.process(item)
    for fi in formatted_items
      items_to_publish.push(fi)
  items_to_publish.sort (a,b) ->
    return b.date - a.date
  for item in items_to_publish[0...wf.HISTORY_LIMIT]
    feed.item item
  return feed.xml()

handle_view = (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  type = req.params.type
  type = 'member' if type == "character"
  region = req.params.region
  realm = req.params.realm
  name = req.params.name
  wf.app.wow.get_history region, realm, type, name, (wowthings) ->
    # wf.debug JSON.stringify(wf.app.wow.get_registered())
    if wowthings and wowthings.length > 0
      #wf.debug wowthing
      feed = []
      for item in wowthings
        fmt_items = wf.app.feed_formatter.process(item)
        for fi in fmt_items
          feed.push(fi)
      # todo - sort feed
      res.render req.params.type, p: req.params, w: wowthings[0], h: wowthings, f: feed
    else
      res.render "message", msg: "Not found - registered for lookup at the Armory #{type}, #{region}/#{realm}/#{name}"

wf.app.get '/wow/:region/:type/:realm/:name', (req, res) ->
  handle_view(req, res)
  
wf.app.get '/view/:type/:region/:realm/:name', (req, res) ->
  handle_view(req, res)

wf.app.get '/feed/all.rss', (req, res) ->

  feed = new rss
    title: 'WoW Activity Feed'
    description: 'Test all changes feed'
    feed_url: "#{wf.SITE_URL}/feed/all.rss"
    site_url: "#{wf.SITE_URL}"
    image_url: 'http://www.google.com/icon.png'
    author: 'Chris Kimpton'

  wf.app.wow.get_loaded (items) ->
    res.send build_feed(items, feed)
 
wf.app.get '/feed/:type/:region/:realm/:name.rss', (req, res) ->

  type = req.params.type
  type = 'member' if type == "character"
  region = req.params.region
  realm = req.params.realm
  name = req.params.name

  feed = new rss
    title: "WoW Activity Feed for #{name}"
    description: "WoW Activity Feed for #{type} #{name}, of #{region} realm #{realm}"
    feed_url: "#{wf.SITE_URL}/feed/#{type}/#{region}/#{realm}/#{name}.rss"
    site_url: "#{wf.SITE_URL}/view/#{type}/#{region}/#{realm}/#{name}"
    image_url: 'http://www.google.com/icon.png'
    author: 'Chris Kimpton'

  wf.app.wow.get_history region, realm, type, name, (items)->
    res.send build_feed(items, feed)
 

wf.app.get '/debug/clear_all', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.clear_all ->
    res.render "message", msg: "Database cleared!"

wf.app.get '/debug/sample_data', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.get_history "eu", "Soulflayer", "guild", "Мб Ро"
  wf.app.wow.get_history "eu", "Darkspear", "guild", "Mean Girls"
  wf.app.wow.get_history "us", "Earthen Ring", "guild", "alea iacta est"
  wf.app.wow.get_history "eu", "Darkspear", "member", "Kimptopanda"
  # wf.app.wow.get_history "eu", "Darkspear", "member", "Kimptoc"
  # wf.app.wow.get_history "eu", "Darkspear", "member", "Kimptocii"
  wf.app.wow.get_history "us", "kaelthas", "member", "Feåtherz"
  res.render "message", msg: "Sample data registered"

#wf.app.listen(process.env.VCAP_APP_PORT || 3000)

http.createServer(app).listen(app.get('port'), ->
  wf.info("Express server listening on port " + app.get('port')))