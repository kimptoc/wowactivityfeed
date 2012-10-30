should = require 'should'
assert = require 'assert'

require "./commonSpec"
require "./wow"
require "./feed_item_formatter"

describe "feed item formatter", ->
  describe "basics", ->

    beforeEach (done) ->
      wow = new wf.WoW ->
        done()

    it "handle null", ->
      f = new wf.FeedItemFormatter()
      f.process null, (d) ->
        d.length.should.equal 1
        d[0].description.should.match /^Something.*/

    it "basic item, new", ->
      f = new wf.FeedItemFormatter()
      item = 
        whats_changed :
          overview : "NEW"
        lastModified : 0
      f.process item, (d) ->
        d[0].description.should.match /^And as if by magic.*/
        d[0].date.should.equal 0

    it "basic item, no whats_changed", ->
      f = new wf.FeedItemFormatter()
      item = 
        lastModified : 0
      f.process item, (d) ->
        d[0].description.should.match /^Something.*/
        d[0].date.should.equal 0

    it "basic item, update", ->
      f = new wf.FeedItemFormatter()
      item = 
        name : "test"
        armory :
          level : 5
        whats_changed :
          overview : "UPDATE"
          changes :
            level : [4,5]
        lastModified : 1
      f.process item, (d)->
        d[0].description.should.match /is now level 5/
        d[0].date.should.equal 1

    it "get items", ->
      f = new wf.FeedItemFormatter()
      item = 
        name : "test"
        armory :
          level : 5
          feed :
            [
              itemId : 87471
            ]
        whats_changed :
          overview : "UPDATE"
          changes :
            level : [4,5]
        lastModified : 1
      d = f.get_items(item)
      d.length.should.equal 1
      d[0].should.equal 87471
