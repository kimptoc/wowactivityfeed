window.wf ?= {}

class wf.SearchView extends Backbone.View
  tagName: 'div'
  className: 'container'
  id: 'searchView'

  template: _.template( $('#search-template').html() )

  initialize: ->
    @model.realms.bind('reset',@render)
    $('#search_now').on('click', @searchNowClicked)
    # _.bindAll(this, 'render')

  searchNowClicked: ->
    console.log "time to search!"

  render: =>
    # console.log $('#search-template').html() 
    # @$el.html( @template( @model.toJSON() ) )
    # model = new Backbone.Model()
    # model.set "foo","bar"
    @$el.html( @template( realms : @model.realms.toJSON() ) )
    # @$el.html( @template( ) )
    return this
