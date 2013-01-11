window.wf ?= {}

class wf.SearchView extends Backbone.View
  # el: 'backbone_container'
  tagName: 'div'
  className: 'container'
  id: 'searchView'
  name: ''
  realm_region_id: ''

  template: _.template( $('#search-template').html() )

  initialize: =>
    @model.realms.bind('reset',@render)
    @model.results.bind('reset',@render)
    @model.results.bind('add',@render)

  searchNowClicked: =>
    @name = $('#search_text').val().trim()
    @realm_region_id = $('#realm_region option:selected').attr('id')
    error = ""
    error += "Enter a name to search for" unless @name? and @name.length >0
    unless @realm_region_id?
      error += " and " if error.length > 0
      error += "Select a realm/region"
    error += "!" unless error?
    if error.length > 0
      alert(error)
    else
      @trigger('search:clicked')
    return false

  render: =>
    console.log "SearchView.render"
    @$el.html( @template( 
      realms : @model.realms.toJSON(), 
      results: @model.results.toJSON(), 
      results_complete: @model.results.results_complete,
      searching: @model.results.searching,
      elapsed_seconds: @model.results.elapsed_seconds
      name: name ) )
    $container = $("#backbone_container");
    $container.append(@el);

    $('#search_text').val(@name)
    $('#'+@realm_region_id).attr('selected','selected')
    $('#search_now').on('click', @searchNowClicked)
    return this
