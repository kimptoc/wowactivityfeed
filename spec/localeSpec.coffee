should = require 'should'
assert = require 'assert'

require "./commonSpec"
require './init_logger'
require "./locale"
require "./wow"


describe "locale helpers", ->

  it "check realm loading", ->
    new wf.WoW (wow)->
      wf.wow = wow
      wf.ensure_realms_loaded ->
        wf.all_realms.should.exist
        wf.all_realms.length.should.be.above 10

  it "basics, no locale or url default", ->
    req =
      headers:
        "accept-language":'en-GB,x'
      params:
        region: 'eu'
    locale = wf.sort_locale(req)
    locale.should.equal 'en_GB'

  it "basics, url/realm based default", ->
    new wf.WoW (wow)->
      wf.wow = wow
      wf.ensure_realms_loaded ->
        req =
          headers:
            "accept-language":'en-US,x'
          params:
            region: 'eu'
            realm: 'Darkspear'
        locale = wf.sort_locale(req)
        locale.should.equal 'en_GB'

  it "basics, locale based default", ->
    new wf.WoW (wow)->
      wf.wow = wow
      wf.ensure_realms_loaded ->
        req =
          headers:
            "accept-language":'en-US,x'
          params:
            region: 'eu'
            realm: 'Darkspear'
            locale: 'fr_FR'
        locale = wf.sort_locale(req)
        locale.should.equal 'fr_FR'