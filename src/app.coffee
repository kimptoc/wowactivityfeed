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
  wf.info "App Startup/Express configure:dirname=#{__dirname}"
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

  wf.app.use(require('stylus').middleware(__dirname + '\\..\\public'))  
  wf.app.use(express.static(path.join(__dirname + '\\..\\', 'public')))
  wf.app.wow = new wf.WoW()


wf.app.configure 'development', ->
  wf.app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))   
  
wf.app.configure 'production', ->
  wf.app.use(express.errorHandler())   

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
  wf.app.wow.get_collections (results) ->
    res.render "loaded", colls: results

wf.app.get '/view/:type/:region/:realm/:name', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  type = req.params.type
  region = req.params.region
  realm = req.params.realm
  name = req.params.name
  wf.app.wow.get region, realm, type, name, (wowthing) ->
    wf.debug JSON.stringify(wf.app.wow.get_registered())
    if wowthing
      #wf.debug wowthing
      res.render req.params.type, p: req.params, w: wowthing
    else
      res.send "Not found - registered for lookup at the Armory #{type}, #{region}/#{realm}/#{name}"

wf.app.get '/debug/clear_all', (req, res) ->
  wf.info "get #{JSON.stringify(req.route)}"
  wf.app.wow.clear_all ->
    res.render "message", msg: "Database cleared!"


#wf.app.listen(process.env.VCAP_APP_PORT || 3000)

http.createServer(app).listen(app.get('port'), ->
  wf.info("Express server listening on port " + app.get('port')))