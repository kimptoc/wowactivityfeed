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

    it "handle null", (done)->
      f = new wf.FeedItemFormatter()
      f.process null, (d) ->
        d.length.should.equal 0
        done()

    it "basic item, new", (done)->
      f = new wf.FeedItemFormatter()
      item = 
        whats_changed :
          overview : "NEW"
        lastModified : 0
      f.process item, (d) ->
        d[0].description.should.match /^And as if by magic.*/
        d[0].date.should.equal 0
        done()

    it "basic item, no whats_changed", (done)->
      f = new wf.FeedItemFormatter()
      item = 
        lastModified : 0
      f.process item, (d) ->
        d.length.should.equal 0
        done()

    it "basic item, update", (done)->
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
        done()

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

    it "get_name, no titles", ->
      f = new wf.FeedItemFormatter()
      item = 
        name : "test"
      n = f.get_name item
      n.should.equal "test" # unchanged

    it "get_name, titles, none selected", ->
      f = new wf.FeedItemFormatter()
      item = 
        name : "test"
        armory:
          titles:
            [
              name: "123"
            ]
      n = f.get_name item
      n.should.equal "test" # unchanged

    it "get_name, titles, one selected", ->
      f = new wf.FeedItemFormatter()
      item = 
        name : "test"
        armory:
          titles:
            [
              name: "123-%s"
              selected: "YES"
            ]
      n = f.get_name item
      n.should.equal "123-test" # changed