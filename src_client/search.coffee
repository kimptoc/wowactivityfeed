window.wf ?= {}

class wf.Search
  models = {}
  collections = {}
  routers = {}
  views = {}

  @init: ->
    console.log "Search.init"
    this.realms = new wf.Realms()
    this.app = new wf.Router()
    this.realms.fetch()
    this.app.index()
    Backbone.history.start({pushState: true})
    return this
# this.trips = new TimeTravel.Collections.Trips(tripData);
# this.app = new TimeTravel.Routers.TripRouter();
