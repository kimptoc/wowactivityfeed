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

    it "basic item, update to items", (done)->
      f = new wf.FeedItemFormatter()
      item =
        name : "test"
        armory :
          level : 5
          items :
            averageItemLevel : 5
            averageItemLevelEquipped : 6
        whats_changed :
          overview : "UPDATE"
          changes :
            items :
              averageItemLevel : [3,5]
              averageItemLevelEquipped : [2,6]
        lastModified : 1
      f.process item, (d)->
        d[0].description.should.match /Average Item Level: 5/
        d[0].description.should.match /Average Item Level Equipped: 6/
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
        d[0].description.should.match /Now at level 5/
        d[0].date.should.equal 1
        done()

    it "get items", (done) ->
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
      done()

    it "get_name, no titles", (done) ->
      f = new wf.FeedItemFormatter()
      item =
        name : "test"
        armory :
          name : "Test"
      n = f.get_formal_name item
      n.should.equal "Test" # unchanged
      done()

    it "get_name, titles, none selected", (done) ->
      f = new wf.FeedItemFormatter()
      item =
        name : "test"
        armory:
          name : "Test"
          titles:
            [
              name: "123"
            ]
      n = f.get_formal_name item
      n.should.equal "Test" # unchanged
      done()

    it "get_name, titles, one selected", (done) ->
      f = new wf.FeedItemFormatter()
      item =
        name : "test"
        armory:
          name : "Test"
          titles:
            [
              name: "123-%s"
              selected: "YES"
            ]
      n = f.get_formal_name item
      n.should.equal "123-Test" # changed
      done()
