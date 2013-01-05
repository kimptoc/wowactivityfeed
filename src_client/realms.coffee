window.wf ?= {}

class wf.Realm extends Backbone.Model

class wf.Realms extends Backbone.Collection
  model: wf.Realm
  url: '/json/realms'