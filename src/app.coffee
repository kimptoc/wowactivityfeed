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
  wf.app.use(express.logger('dev'))  
  wf.app.use(require('stylus').middleware(__dirname + '\\..\\public'))  
  wf.app.use(express.static(path.join(__dirname + '\\..\\', 'public')))
  wf.app.wow = new wf.WoW()


wf.app.configure 'development', ->
  wf.app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))   
  
wf.app.configure 'production', ->
  wf.app.use(express.errorHandler())   

# Routes

wf.app.get '/', (req, res) ->
    res.render 'index', title: 'Home'
#    res.send 'Hello from WoW Feed2'

wf.app.get '/armory_load', (req, res) ->
  res.send "Armory load result: #{wf.app.wow.armory_load()}"

wf.app.get '/view/:type/:region/:realm/:name', (req, res) ->
    type = req.params.type
    region = req.params.region
    realm = req.params.realm
    name = req.params.name
    wowthing = wf.app.wow.get region, realm, type, name
    wf.debug JSON.stringify(wf.app.wow.get_registered())
    if wowthing
      #console.log wowthing
      res.render req.params.type, p: req.params, w: wowthing
    else
      res.send "Not found - registered for lookup at the Armory #{type}, #{region}/#{realm}/#{name}"

#wf.app.listen(process.env.VCAP_APP_PORT || 3000)

http.createServer(app).listen(app.get('port'), ->
  wf.info("Express server listening on port " + app.get('port')))