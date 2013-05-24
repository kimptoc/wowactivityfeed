should = require 'should'
assert = require 'assert'

require "./commonSpec"
require './init_logger'
require "./string"

describe "string extension(s)", ->
  describe "capitalise", ->

    it "basics", (done) ->
      wf.String.capitalise("abc").should.equal "Abc"
      wf.String.capitalise("Abc").should.equal "Abc"
      wf.String.capitalise("AbC").should.equal "Abc"
      wf.String.capitalise("abc def").should.equal "Abc Def"
      wf.String.capitalise("己二酸").should.equal "己二酸"
      done()
