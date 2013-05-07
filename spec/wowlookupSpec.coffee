should = require 'should'
require "./commonSpec"

require "./init_logger"
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
      wow.get {type:"guild", region:"eu", realm:"Darkspear", name:"Mean Girls"}, 0, (result) ->
        should.exist result
        should.not.exist result.error
        result.name.should.equal "Mean Girls"
        should.not.exist result.error
        done()

    it "invalid guild armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get {type:"guild", region:"eu", realm:"Darkspear", name:"Mean Girlsaaa"}, 0, (result) ->
        should.exist result
        should.exist result.error
        should.exist result.name
        done()

    it "valid member armory lookup basic", (done) ->
      wow = new wf.WowLookup()
      wow.get {type:"member", region:"eu", realm:"Darkspear", name:"Kimptoc"}, 0, (result) ->
        should.exist result
        should.not.exist result.error
        should.exist result.locale
        result.name.should.equal "Kimptoc"
        should.exist result.achievements
        result.achievements.achievementsCompleted.length.should.equal result.achievements.achievementsCompletedTimestamp.length
        result.achievements.criteria.length.should.equal result.achievements.criteriaCreated.length
        result.achievements.criteria.length.should.equal result.achievements.criteriaQuantity.length
        result.achievements.criteria.length.should.equal result.achievements.criteriaTimestamp.length
        done()

    it "valid french member armory lookup basic", (done) ->
      wow = new wf.WowLookup()
      wow.get {type:"member", region:"eu", realm:"Argent Dawn", name:"Grobmuk", locale:"fr_FR"}, 0, (result) ->
        should.exist result
        should.not.exist result.error
        should.exist result.locale
        result.name.should.equal "Grobmuk"
        result.locale.should.equal "fr_FR"
        done()

    it "invalid  member armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get {type:"member", region:"eu", realm:"Darkspear", name:"Kimptocaaa"}, 0, (result) ->
        should.exist result
        should.exist result.error
        should.exist result.name
        done()

    it "valid member armory lookup, no mods", (done) ->
      wow = new wf.WowLookup()
      wow.get {type:"member", region:"eu", realm:"Darkspear", name:"Kimptoc"}, 0, (result) ->
        should.exist result
        should.not.exist result.error
        result.name.should.equal "Kimptoc"
        should.exist result.achievements
        wow.get {type:"member", region:"eu", realm:"Darkspear", name:"Kimptoc"}, result.lastModified, (result) ->
          should.strictEqual(undefined, result)
          done()

    it "valid member armory lookup, default null lastMod", (done) ->
      wow = new wf.WowLookup()
      wow.get {type:"member", region:"eu", realm:"Darkspear", name:"Kimptoc"}, undefined, (result) ->
        should.exist result
        should.not.exist result.error
        result.name.should.equal "Kimptoc"
        should.exist result.achievements
        done()

    it "get item info", (done) ->
      wow = new wf.WowLookup()
      wow.get_item 87417, null, (info) ->
        info.id.should.equal 87417
        done()

    it "get all realms", (done) ->
      wow = new wf.WowLookup()
      wow.get_realms "eu",(realms) ->
        should.exist realms
        should.exist realms[0].region
        realms.length.should.be.above(10)
        realms_by_region_and_slug = {}
        for realm in realms
          realms_by_region_and_slug[realm.region] ?= {}
          region = realms_by_region_and_slug[realm.region] 
          existing = region[realm.slug]
          should.not.exist existing
          region[realm.slug] = true
        done()

    it "get all races", (done) ->
      wow = new wf.WowLookup()
      wow.get_races null, (races) ->
        should.exist races
        races.length.should.be.above(7)
        done()

    it "get all classes", (done) ->
      wow = new wf.WowLookup()
      wow.get_classes null, (classes) ->
        should.exist classes
        classes.length.should.be.above(7)
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