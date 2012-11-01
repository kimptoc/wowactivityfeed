global.wf ||= {}

moment = require 'moment'

require('./init_logger')
require('./wow')

class wf.FeedItemFormatter

  get_items: (item) ->
    # work out all items in armory update that we are interested in - mainly in news/feeds hashes
    item_ids = []
    if item?.armory?.feed?
      for feed_item in item.armory.feed
        item_ids.push feed_item.itemId if feed_item?.itemId?
    if item?.armory?.news?
      for news_item in item.armory.news
        item_ids.push news_item.itemId if news_item?.itemId?
    return item_ids

  get: (key, item) ->
    @get_new_one item?.whats_changed?.changes?[key]

  get_new_one: (diffs) ->
    if diffs?
      if diffs.length == 1 # new items have a one element array
        diffs[0]
      else
        diffs[1]
    else
      "???"

  format_date: (dt) ->
    dateMoment = moment(dt)
    "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"    

  process: (item, callback) ->
    wf.debug "format.process"
    item_ids = @get_items(item)
    wf.debug "got items, #{item_ids.length}"
    wf.wow.load_items item_ids, (items) =>
      wf.debug "format.process - load_items"
      results = []
      results.push @format_item(item, items)
      if item?.armory?.feed?
        for feed_item in item.armory.feed
          results.push @format_feed_item(feed_item, item, items)
      if item?.armory?.news?
        for news_item in item.armory.news
          results.push @format_news_item(news_item, item, items)
      callback?(results)

  achievement_link: (achievement) ->
    "<a href='http://www.wowhead.com/achievement=#{achievement.id}' alt='#{achievement.title}' title='#{achievement.title}'><img src='http://us.media.blizzard.com/wow/icons/56/#{achievement.icon}.jpg' align='right' style='border:solid yellow 1px;'></a>"

  char_link: (p) ->
    "<a href='http://#{p.region}.battle.net/wow/en/character/#{p.realm}/#{p.name}/simple' alt='#{p.name}' title='#{p.name}'><img src='http://#{p.region}.battle.net/static-render/#{p.region}/#{p.armory.thumbnail}' align='left' style='border:solid black 1px;' class='char_image'></a>"

  char_name: (p) ->
    "<a href='http://#{p.region}.battle.net/wow/en/character/#{p.realm}/#{p.name}/simple' alt='#{p.name}' title='#{p.name}'>#{p.name}</a>"

  item_link: (item_id, items) ->
    #todo - handle not found, img link, wowhead link/hover...
    a_text = "<img src='http://us.media.blizzard.com/wow/icons/56/#{items?[item_id]?.icon}.jpg' align='right' style='border:solid yellow 1px;' title='#{@item_name(item_id, items)}' alt='#{@item_name(item_id, items)}'>"
    a_text = "Unknown..." unless items?[item_id]
    return "<a href='http://www.wowhead.com/item=#{item_id}'>#{a_text}</a>"

  item_name: (item_id, items) ->
    #todo - handle not found, img link, wowhead link/hover...
    name = items?[item_id]?.name
    name ||= "Unknown...."

  format_item: (item, items) ->
    change_title = "#{item?.name}:"
    change_title = "Guild:#{change_title}" if item.type == "guild"
    change_title = "#{item.armory.guild.name}/#{change_title}" if item?.armory?.guild?.name?
    change_description = ""
    if item? and item.whats_changed?
      if item.whats_changed.overview == "NEW"
        change_description = "And as if by magic, #{item.name} appeared!"
      else
        if item.whats_changed.changes.level?
          change_title = "#{item?.name} - level #{@get('level',item)}!"
          change_description += "#{item.name} is now level #{@get('level',item)}! "
        if item.whats_changed.changes.achievementPoints?
          change_description += "Yay, more achievement points - now at #{@get('achievementPoints',item)}. "
        if item.whats_changed.changes.items?
          # wf.debug "items change...#{JSON.stringify(item.whats_changed.changes.items)}"
          gear_change = ""
          for own name, gear of item.whats_changed.changes.items
            # wf.debug "items change...#{name}"
            if ! /averageItemLevel/.test(name) and gear.name?
              # wf.debug "items change:#{name}: #{@get_new_one(gear.name)} "
              gear_change += ", " if gear_change.length >0
              gear_change += "#{name}: #{@get_new_one(gear.name)}"
          if gear_change.length > 0
            change_description += "Gear change: #{gear_change}. "
        if item.whats_changed.changes.reputation_map?
          rep_change = ""
          for own name, values of item.whats_changed.changes.reputation_map
            rep_change += ", " if rep_change.length >0
            rep_change += "#{name}:#{@get_new_one(values.value)}"
          change_description += "Rep change(s): #{rep_change}. "

    if change_description == ""
      change_description = "Something about #{item?.name} has changed, not quite sure what, its a mystery..."
    if item?.type == "member" and item.armory?.thumbnail?
      change_description = "#{@char_link(item)} #{change_description}"
    result = 
      title: change_title
      description: change_description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}?ts=#{item?.lastModified}"
      date: item?.lastModified 
      date_formatted: @format_date(item?.lastModified)
      author: item?.name
      guid: "#{item?.lastModified}-#{change_title}"
    return result

  format_news_item: (news_item, item, items) ->
    change_title = "#{item?.name}:#{news_item.type}"
    description = "#{item?.name}:#{news_item.type}:character: #{news_item.character}, achievement:#{news_item.achievement?.description}"

    if news_item.type == "playerAchievement" or news_item.type == "guildAchievement"
      mentionGuild = ""
      mentionGuild = "guild " if news_item.type == "guildAchievement"
      change_title = "#{item.name} - #{news_item.character} gained the #{mentionGuild}achievement '#{news_item.achievement.title}'"
      description = "#{@achievement_link(news_item.achievement)} Achieved #{news_item.achievement.title}: #{news_item.achievement.description}"
      thingId = news_item.achievement.id
      if news_item.achievement.criteria and news_item.achievement.criteria.length >0
        description += " ["
        done_first = false
        for crit in news_item.achievement.criteria
          description += "," if done_first
          description += " #{crit.description}"
          done_first = true
          thingId += "-#{crit.id}"
        description += "]"
      description += " (#{news_item.achievement.points}pts)"

    else if news_item.type == "itemPurchase"
      change_title = "#{news_item.character} bought #{@item_name(news_item.itemId, items)}"
      description = "#{news_item.character} bought a #{@item_name(news_item.itemId, items)} #{@item_link(news_item.itemId, items)}"
      thingId = news_item.itemId

    else if news_item.type == "itemLoot"
      change_title = "#{news_item.character} got some loot - #{@item_name(news_item.itemId, items)}"
      description = "#{news_item.character} got a #{@item_name(news_item.itemId, items)} #{@item_link(news_item.itemId, items)}"
      thingId = news_item.itemId

    else if news_item.type == "itemCraft"
      change_title = "#{news_item.character} made #{@item_name(news_item.itemId, items)}"
      description = "#{news_item.character} made a #{@item_name(news_item.itemId, items)} #{@item_link(news_item.itemId, items)}"
      thingId = news_item.itemId

    else if news_item.type == "guildLevel"
      change_title = "#{item.name} is now level #{news_item.levelUp}!"
      description = "Guild #{item.name} is now at guild level #{news_item.levelUp}!"
      thingId = news_item.itemId

    else
      description += " #{JSON.stringify(news_item)}"

    result = 
      title: change_title
      description: description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}?ts=#{item?.lastModified}&id=#{thingId}"
      date: news_item.timestamp
      date_formatted: @format_date(news_item.timestamp)
      author: item?.name
      guid: "#{news_item.timestamp}-#{change_title}"
    return result

  format_feed_item: (feed_item, item, items) ->

    change_title = "#{item?.name}:#{feed_item.achievement?.title}"
    description = "#{item?.name}:TYPE:#{feed_item.type}:#{feed_item.achievement?.description}"
    if feed_item.type == "ACHIEVEMENT"
      change_title = "#{item?.name} gained the achievement '#{feed_item.achievement.title}'"
      description = "#{@char_link(item)} #{@char_name(item)} - #{@achievement_link(feed_item.achievement)} #{feed_item.achievement.title}: #{feed_item.achievement.description}"
      thingId = feed_item.achievement.id
      if feed_item.achievement.criteria and feed_item.achievement.criteria.length >0
        description += " ["
        done_first = false
        for crit in feed_item.achievement.criteria
          description += "," if done_first
          description += " #{crit.description}"
          done_first = true
          thingId += "-#{crit.id}"
        description += "]"
      description += " (#{feed_item.achievement.points}pts)"

    else if feed_item.type == "CRITERIA"
      change_title = "#{item?.name} progressed towards achievement '#{feed_item.achievement.title}'"
      achievement_description = "#{feed_item.achievement?.description} Progressing towards achievement #{feed_item.achievement.title}"
      achievement_description = feed_item.achievement?.title if achievement_description.indexOf(feed_item.criteria.description) >= 0
      description = "#{@char_link(item)} #{@char_name(item)} - Step:#{feed_item.criteria.description} for #{achievement_description}"
      thingId = feed_item.criteria.id

    else if feed_item.type == "BOSSKILL"
      change_title = "#{item?.name} - '#{feed_item.criteria.description}'"
      description = "#{@char_link(item)} #{@char_name(item)} Did:#{feed_item.criteria.description} for '#{feed_item.achievement.title}' - #{feed_item.achievement?.description}"
      thingId = feed_item.criteria.id

    else if feed_item.type == "LOOT"
      change_title = "#{item?.name} - got some loot - #{@item_name(feed_item.itemId, items)}!"
      description = "#{@char_link(item)} #{@char_name(item)} now has a #{@item_name(feed_item.itemId, items)}! #{@item_link(feed_item.itemId, items)}"
      thingId = feed_item.itemId

    else
      description += " #{JSON.stringify(feed_item)}"

    result = 
      title: change_title
      description: description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}?ts=#{item?.lastModified}&id=#{thingId}"
      date: feed_item.timestamp
      date_formatted: @format_date(feed_item.timestamp)
      author: item?.name
      guid: "#{feed_item.timestamp}-#{change_title}"
    return result