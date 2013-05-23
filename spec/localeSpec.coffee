should = require 'should'
assert = require 'assert'

require "./commonSpec"
require './init_logger'
require "./locale"
require "./wow"


describe "locale helpers", ->

  it "check realm loading", (done) ->
    new wf.WoW (wow)->
      wf.wow = wow
      wf.ensure_realms_loaded ->
        wf.all_realms.should.exist
        wf.all_realms.length.should.be.above 10
        done()

  it "basics, no locale or url default", ->
    req =
      headers:
        "accept-language":'en-GB,x'
      params:
        region: 'eu'
    locale = wf.sort_locale(req)
    locale.should.equal 'en_GB'

  it "basics, no locale or url default, but have invalid loc", ->
    req =
      headers:
        "accept-language":''
      params:
        region: 'eu'
    locale = wf.sort_locale(req)
    locale.should.equal 'en_US'

  it "basics, no locale or url default, but have invalid loc/2", ->
    req =
      headers:
        "accept-language":'foobar'
      params:
        region: 'eu'
    locale = wf.sort_locale(req)
    locale.should.equal 'en_US'

  it "basics, url/realm based default", (done)->
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
        done()

  it "basics, locale based default", (done)->
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
        done()

  it "basics, locale based default/invalid1", (done) ->
    new wf.WoW (wow)->
      wf.wow = wow
      wf.ensure_realms_loaded ->
        req =
          headers:
            "accept-language":'en-US,x'
          params:
            region: 'eu'
            realm: 'Darkspear'
            locale: ''
        locale = wf.sort_locale(req)
        locale.should.equal 'en_GB'
        done()

  it "basics, locale based default, invalid2", (done)->
    new wf.WoW (wow)->
      wf.wow = wow
      wf.ensure_realms_loaded ->
        req =
          headers:
            "accept-language":'en-US,x'
          params:
            region: 'eu'
            realm: 'Darkspear'
            locale: 'foobar2'
        locale = wf.sort_locale(req)
        locale.should.equal 'en_GB'
        done()