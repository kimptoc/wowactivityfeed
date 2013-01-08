window.wf ?= {}

class wf.SearchView extends Backbone.View
  # el: 'backbone_container'
  tagName: 'div'
  className: 'container'
  id: 'searchView'

  template: _.template( $('#search-template').html() )

  initialize: =>
    @model.realms.bind('reset',@render)
    @model.results.bind('reset',@render)
    @model.results.bind('add',@render)

  searchNowClicked: =>
    @trigger('search:clicked')

  render: =>
    console.log "SearchView.render"
    @$el.html( @template( realms : @model.realms.toJSON(), results: @model.results.toJSON(), results_complete: @model.results.results_complete ) )
    $container = $("#backbone_container");
    $container.append(@el);

    $('#search_now').on('click', @searchNowClicked)
    return this
