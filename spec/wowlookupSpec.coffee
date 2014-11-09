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
      this.timeout(5000)
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
      this.timeout(6000)
      wow = new wf.WowLookup()
      wow.get {type:"member", region:"eu", realm:"silvermoon", name:"redsamurai", locale:"fr_FR"}, 0, (result) ->
        should.exist result
        should.not.exist result.error
        should.exist result.locale
        result.name.should.equal "Redsamurai"
        result.locale.should.equal "fr_FR"
        done()

    it "invalid  member armory lookup", (done) ->
      wow = new wf.WowLookup()
      wow.get {type:"member", region:"eu", realm:"Darkspear", name:"Kimptocaaa"}, 0, (result) ->
        should.exist result
        should.exist result.error
        should.exist result.name
        done()

# This does not work with the new API yet
    # it "valid member armory lookup, no mods", (done) ->
    #   this.timeout(5000)
    #   wow = new wf.WowLookup()
    #   wow.get {type:"member", region:"eu", realm:"Darkspear", name:"Kimptoc"}, 0, (result) ->
    #     should.exist result
    #     should.not.exist result.error
    #     result.name.should.equal "Kimptoc"
    #     should.exist result.achievements
    #     wow.get {type:"member", region:"eu", realm:"Darkspear", name:"Kimptoc"}, result.lastModified, (result2) ->
    #       should.strictEqual(undefined, result2)
    #       done()

    it "valid member armory lookup, default null lastMod", (done) ->
      wow = new wf.WowLookup()
      wow.get {type:"member", region:"eu", realm:"Darkspear", name:"Kimptoc"}, undefined, (result) ->
        should.exist result
        should.not.exist result.error
        result.name.should.equal "Kimptoc"
        should.exist result.achievements
        done()

    it "get item info/1", (done) ->
      wow = new wf.WowLookup()
      wow.get_item 87417, "en_GB" , "eu", null, (info) ->
        info.id.should.equal 87417
        info.locale.should.equal "en_GB"
        info.region.should.equal "eu"
        info.name.should.equal "Staff of Broken Hopes"
        done()

    it "get item info/2", (done) ->
      wow = new wf.WowLookup()
      wow.get_item 87417, "pt_MX" , "us", null, (info) ->
        console.log JSON.stringify(info)
        info.id.should.equal 87417
        info.locale.should.equal "pt_MX"
        info.region.should.equal "us"
        info.name.should.equal "Cajado das Esperanças Despedaçadas"
        done()

    it "get item info/3 with context", (done) ->
      wow = new wf.WowLookup()
      wow.get_item 112826, "en_US" , "us", "raid-finder", (info) ->
        info.id.should.equal 112826
        info.locale.should.equal "en_US"
        info.region.should.equal "us"
        info.name.should.equal "Ominous Mogu Greatboots"
        done()

    it "get item info/3 needs context", (done) ->
      wow = new wf.WowLookup()
      wow.get_item 112826, "en_US" , "us", null, (info) ->
        info.id.should.equal 112826
        info.locale.should.equal "en_US"
        info.region.should.equal "us"
        should.not.exist info.name
        done()

    it "get all realms", (done) ->
      wow = new wf.WowLookup()
      wow.get_realms "eu", "en_GB", (realms) ->
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

    it "get all realms", (done) ->
      wow = new wf.WowLookup()
      wow.get_realms "eu", "ru_RU", (realms) ->
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

#    it "get all races", (done) ->
#      wow = new wf.WowLookup()
#      wow.get_races null, (races) ->
#        should.exist races
#        races.length.should.be.above(7)
#        done()
#
#    it "get all classes", (done) ->
#      wow = new wf.WowLookup()
#      wow.get_classes null, (classes) ->
#        should.exist classes
#        classes.length.should.be.above(7)
#        done()

#    it "get all char achievements static", (done) ->
#      this.timeout(15000)
#      wow = new wf.WowLookup()
#      wow.get_static "characterAchievements", "eu", (results) ->
#        should.exist results
#        results.length.should.equal 11 # char achievement categories ...
#        # validate that achievement ids are unique
#        achievements = checkAchievements(results)
#        achievement_length = Object.keys(achievements).length
#        achievement_length.should.be.above(2200)
#
#        wow.get_static "characterAchievements", "us", (results2) ->
#          should.exist results2
#          results2.length.should.equal 11 # char achievement categories ...
#          achievements = checkAchievements(results2)
#          Object.keys(achievements).length.should.equal achievement_length
#          done()
#
#    it "get all guild achievements static", (done) ->
#      wow = new wf.WowLookup()
#      wow.get_static "guildAchievements", "eu", (results) ->
#        should.exist results
#        results.length.should.equal 7 # guild achievement categories ...
#        achievements = checkAchievements(results)
#        achievment_length = Object.keys(achievements).length
#        achievment_length.should.be.above(250)
#        done()
