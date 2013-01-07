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
    # _.bindAll(this, 'render')

  searchNowClicked: =>
    @trigger('search:clicked')
    # ensure text entered
    # ensure realm selected
    # search_text = $('#search_text').text()
    # console.log $('#')
    # console.log "time to search for #{search_text}!"

  render: =>
    console.log "SearchView.render"
    # console.log $('#search-template').html() 
    # @$el.html( @template( @model.toJSON() ) )
    # model = new Backbone.Model()
    # model.set "foo","bar"
    @$el.html( @template( realms : @model.realms.toJSON(), results: @model.results.toJSON() ) )
    $container = $("#backbone_container");
    $container.append(@el);

    $('#search_now').on('click', @searchNowClicked)
    # @$el.html( @template( ) )
    return this
