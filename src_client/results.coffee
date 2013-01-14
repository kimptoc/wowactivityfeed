window.wf ?= {}

class wf.Result extends Backbone.Model

class wf.Results extends Backbone.Collection
  model: wf.Result

  url: -> "/json/get/#{@type}/#{@region}/#{encodeURIComponent(@realm)}/#{encodeURIComponent(@name.trim())}"

  search: (@name, @region, @realm, search_complete_callback) =>
    async.parallel [
      (done) =>
        # console.log "search for guild named #{name}"
        @type = 'guild'
        @fetch {update:true, remove:false, success: done}
    , (done) =>
        # console.log "search for member named #{name}"
        @type = 'member'
        @fetch {update:true, remove:false, success: done}
    ], -> setTimeout search_complete_callback, 1000


