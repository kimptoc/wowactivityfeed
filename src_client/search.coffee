window.wf ?= {}

class wf.Search
  # models = {}
  # collections = {}
  # routers = {}
  # views = {}

  @init: ->
    console.log "Search.init"
    @realms = new wf.Realms()
    @searchView = new wf.SearchView(model : {realms : wf.Search.realms})
    @searchView.on('search:clicked', @searchClicked)
    # @app = new wf.Router()
    @realms.fetch()
    # this.app.index()
    Backbone.history.start({pushState: true})
    return this
# this.trips = new TimeTravel.Collections.Trips(tripData);
# this.app = new TimeTravel.Routers.TripRouter();

  @searchClicked: ->
    # ensure text entered
    # ensure realm selected
    search_text = $('#search_text').text()
    console.log $('#')
    console.log "Time to search for #{search_text}!"
