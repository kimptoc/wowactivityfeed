global.wf ||= {}

async = require "async"
cheerio = require "cheerio"
request = require "request"

require "./defaults"
require './init_logger'
portcheck = require 'portchecker'
require "./wowlookup"
require "./wow"

# not using search - maybe I should delete that
class wf.WowSearch

  wowlookup = null

  constructor: (@wow) ->
    wf.info "WowSearch ctor..."
    wowlookup = @wow.get_wowlookup()

# do in parallel, return both results - could be 0,1 or 2 returned
  search_name:(name, region, realm, callback) =>
    async.parallel [ 
      (done) ->
        wowlookup.get 'member', region, realm, name, null, (result) ->
          found = "no"
          found = "yes" if result? and !result.error?
    #      wf.info "error:#{result.error}"
          wf.info "search for member #{name}: found? #{found}"
          done?(null, result)
    , (done) ->
      wowlookup.get 'guild', region, realm, name, null, (result) ->
        found = "no"
        found = "yes" if result? and !result.error?
  #      wf.info "error:#{result.error}"
        wf.info "search for guild #{name}: found? #{found}"
        done?(null, result)
    ], callback

  search_member: (query, region, url, results, callback) ->
    request uri: url, (error, response, body) ->
      $ = cheerio.load(body, ignoreWhitespace: true)
      result_rows = $('.table tbody tr')
      for row_src in result_rows
        char =
          type: 'member'
          region: region
        results.push(char)
        row = $(row_src).find('td')
        char['name'] = row.eq(0).children('strong').text()
        char['realm'] = row.eq(6).text()
        wf.info "found:#{char['name']}/#{char['realm']}/#{char['region']}"
        #        char['guild'] = row.eq(5).children().first().text()
        #        wf.info "guild:#{char['guild']}"
      #        name = row.$('strong').text()
      #      name = $('.row1 strong').text()
      #        wf.info "WOW response:#{name}"
      callback?(results)

# TODO handle multiple - querying them and how to show?
  search: (query, callback) =>
    wf.info "Searching for:#{query}"
    results = []
    request uri: "http://eu.battle.net/wow/en/search?q=#{encodeURI(query)}&f=wowguild", (error, response, body) ->
      $ = cheerio.load(body, ignoreWhitespace: true)
      result_rows = $('.table tbody tr')
      for row_src in result_rows
        char =
          type: 'guild'
          region: 'eu'
        results.push(char)
        row = $(row_src).find('td')
        char['name'] = row.eq(0).children('strong').text()
        wf.info "name:#{char['name']}"
        char['realm'] = row.eq(1).text()
        wf.info "realm:#{char['realm']}"
      #        name = row.$('strong').text()
      #      name = $('.row1 strong').text()
      #        wf.info "WOW response:#{name}"
      callback?(results)
    regions = ["eu","us","kr","tw"]
    for region in regions
      url = "http://#{region}.battle.net/wow/en/search?f=wowcharacter&q=#{encodeURI(query)}"
      @search_member(query, region, url, results,  callback)
    url = "http://#{region}.battle.net/wow/en/search?f=wowcharacter&q=#{encodeURI(query)}"
    @search_member(query, region, url, results,  callback)

