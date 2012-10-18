should = require 'should'
require "./commonSpec"

require "./wowlookup"

checkAchievements = (docs) ->
  achievements = {}
  for achievementGroup in docs
    for achievement in achievementGroup.achievements
      should.not.exist achievements[achievement.id]
      achievements[achievement.id] = true
    if achievementGroup.categories?
      for category in achievementGroup.categories
        for achievement in category.achievements
          should.not.exist achievements[achievement.id]
          achievements[achievement.id] = true
  return achievements

describe "wow armory lookup:", ->
  describe "get:", ->
    it "valid guild armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get "guild", "eu", "Darkspear", "Mean Girls", (result) ->
        should.exist result
        should.not.exist result.error
        result.name.should.equal "Mean Girls"
        should.not.exist result.error
        done()

    it "invalid guild armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get "guild", "eu", "Darkspear", "Mean Girlsaaa", (result) ->
        should.exist result
        should.exist result.error
        should.exist result.name
        done()

    it "valid member armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get "member", "eu", "Darkspear", "Kimptoc", (result) ->
        should.exist result
        should.not.exist result.error
        result.name.should.equal "Kimptoc"
        should.exist result.achievements
        result.achievements.achievementsCompleted.length.should.equal result.achievements.achievementsCompletedTimestamp.length
        result.achievements.criteria.length.should.equal result.achievements.criteriaCreated.length
        result.achievements.criteria.length.should.equal result.achievements.criteriaQuantity.length
        result.achievements.criteria.length.should.equal result.achievements.criteriaTimestamp.length
        done()

    it "invalid  member armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get "member", "eu", "Darkspear", "Kimptocaaa", (result) ->
        should.exist result
        should.exist result.error
        should.exist result.name
        done()

    it "get all char achievements static", (done) ->
      this.timeout(15000)
      wow = new wf.WowLookup()
      wow.get_static "characterAchievements", "eu", (results) ->
        should.exist results
        results.length.should.equal 11 # char achievement categories ...
        # validate that achievement ids are unique
        achievements = checkAchievements(results)
        achievment_length = Object.keys(achievements).length
        achievment_length.should.be.above(2200)

        wow.get_static "characterAchievements", "us", (results2) ->
          should.exist results2
          results2.length.should.equal 11 # char achievement categories ...
          achievements = checkAchievements(results2)
          Object.keys(achievements).length.should.equal achievment_length
          done()

    it "get all guild achievements static", (done) ->
      wow = new wf.WowLookup()
      wow.get_static "guildAchievements", "eu", (results) ->
        should.exist results
        results.length.should.equal 7 # guild achievement categories ...
        achievements = checkAchievements(results)
        achievment_length = Object.keys(achievements).length
        achievment_length.should.be.above(250)
        done()