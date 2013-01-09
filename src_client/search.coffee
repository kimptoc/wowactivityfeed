window.wf ?= {}

class wf.Search
  # models = {}
  # collections = {}
  # routers = {}
  # views = {}

  @init: ->
    console.log "Search.init"
    @realms = new wf.Realms()
    @results = new wf.Results()
    @results.searching = false
    @results.results_complete = false
    @searchView = new wf.SearchView(model : {realms: @realms, results: @results})
    @searchView.on('search:clicked', @searchClicked)
    # @app = new wf.Router()
    @realms.fetch()
    # this.app.index()
    Backbone.history.start({pushState: true})
    return this
# this.trips = new TimeTravel.Collections.Trips(tripData);
# this.app = new TimeTravel.Routers.TripRouter();

  @searchClicked: =>
    # ensure text entered
    # ensure realm selected
    name = $('#search_text').val()
    realm = $('#realm_region option:selected').attr('data-realm')
    region = $('#realm_region option:selected').attr('data-region')
    console.log "Time to search for #{name}/#{realm}/#{region}!"
    @results.results_complete = false
    @results.searching = true
    @searchView.render()
    @results.reset()
    @results.search name, region, realm, =>
      console.log "search complete..."
      @results.results_complete = true
      @results.searching = false
      @searchView.render()