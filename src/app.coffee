global.wf ||= {}

express = require('express')
http = require('http')
path = require('path')

#wf.app = express()

app = module.exports = express()

wf.app = app

# Configuration

wf.app.configure ->
  console.log "dirname=#{__dirname}"
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


wf.app.configure 'development', ->
  wf.app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))   
  
wf.app.configure 'production', ->
  wf.app.use(express.errorHandler())   

# Routes

wf.app.get '/', (req, res) ->
    res.render 'index', title: 'Home'
#    res.send 'Hello from WoW Feed2'


#wf.app.listen(process.env.VCAP_APP_PORT || 3000)

http.createServer(app).listen(app.get('port'), ->
  console.log("Express server listening on port " + app.get('port')))