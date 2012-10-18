should = require 'should'
assert = require 'assert'

require "./commonSpec"

require "./feed_item_formatter"

describe "feed item formatter", ->
  describe "basics", ->

    it "handle null", ->
      f = new wf.FeedItemFormatter()
      d = f.process(null)
      d.length.should.equal 1
      d[0].description.should.match /^Something.*/

    it "basic item, new", ->
      f = new wf.FeedItemFormatter()
      item = 
        whats_changed :
          overview : "NEW"
        lastModified : 0
      d = f.process(item)
      d[0].description.should.match /^And as if by magic.*/
      d[0].date.should.equal 0

    it "basic item, new, no whats_changed", ->
      f = new wf.FeedItemFormatter()
      item = 
        lastModified : 0
      d = f.process(item)
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
      d = f.process(item)
      d[0].description.should.match /is now level 5/
      d[0].date.should.equal 1
