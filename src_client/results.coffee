window.wf ?= {}

class wf.Result extends Backbone.Model

class wf.Results extends Backbone.Collection
  model: wf.Result

  url: -> "/json/get/#{@type}/#{@region}/#{@realm}/#{@name}"

  search: (@name, @region, @realm) =>
    @type = 'guild'
    @fetch {update:true, remove:false}
    @type = 'member'
    @fetch {update:true, remove:false}

