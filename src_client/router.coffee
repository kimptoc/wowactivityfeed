window.wf ?= {}

# DONT THIS IS USED _ remote it?
class wf.Router extends Backbone.Router
  routes: 
    "": "index"

  index: ->
    $container = $("#backbone_container");
    $container.append(@searchView.render().el);

  initialize: ->
    @searchView = new wf.SearchView(model : {realms : wf.Search.realms})