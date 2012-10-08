global.wf ||= {}

express = require('express')
http = require('http')
path = require('path')

require('./init_logger')
require('./wow')

#wf.app = express()

app = module.exports = express()

wf.app = app

# Configuration

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
  wf.app.wow = new wf.WoW()
  
wf.app.configure 'production', ->
  wf.info "Express app.configure/production"
  env = JSON.parse(process.env.VCAP_SERVICES)
  wf.mongo_info = env['mongodb-1.8'][0]['credentials']
  wf.app.use(express.errorHandler())   
  wf.app.wow = new wf.WoW()

# Routes

wf.app.get '/', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  res.render 'index', title: 'Home'
#    res.send 'Hello from WoW Feed2'

wf.app.get '/armory_load', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.armory_load()
  res.render "armory_load", res: "Processing ? items"

wf.app.get '/registered', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.get_registered (results) ->
    res.render "registered", reg: results

wf.app.get '/loaded', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.get_loaded (results) ->
    #TODO - get latest entry in each, only feed collections
    res.render "loaded", colls: results

wf.app.get '/view_named/:coll_name', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.get_history_named req.params.coll_name, (wowthings) ->
    wf.debug JSON.stringify(wowthings)
    type = req.params.coll_name.split('-')[1].split(':')[0]
    if wowthings and wowthings.length > 0
      #wf.debug wowthing
      res.render type, p: req.params, w: wowthings[0], h: wowthings
    else
      res.render "message", msg: "Not found - #{req.params.coll_name}"

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
      res.render req.params.type, p: req.params, w: wowthings[0], h: wowthings
    else
      res.render "message", msg: "Not found - registered for lookup at the Armory #{type}, #{region}/#{realm}/#{name}"

wf.app.get '/wow/:region/:type/:realm/:name', (req, res) ->
  handle_view(req, res)
  
wf.app.get '/view/:type/:region/:realm/:name', (req, res) ->
  handle_view(req, res)


wf.app.get '/debug/clear_all', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.clear_all ->
    res.render "message", msg: "Database cleared!"

wf.app.get '/debug/sample_data', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
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