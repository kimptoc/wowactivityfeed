global.wf ||= {}

moment = require 'moment'

require('./init_logger')

class wf.FeedItemFormatter

  get: (key, item) ->
    if item?.whats_changed?.changes?[key]?.length == 1 # new items have a one element array
      item?.whats_changed?.changes?[key][0]
    else # its an update
      item?.whats_changed?.changes?[key][1]

  process: (item) ->
    results = []
    change_title = "#{item?.name}:"
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
    if change_description == ""
      change_description = "Something about #{item?.name} has changed, not quite sure what, its a mystery..."
    if item?.type == "member" and item.armory?.thumbnail?
      change_description = "#{@char_link(item)} #{change_description}"
    dateMoment = moment(item?.lastModified)
    result = 
      title: change_title
      description: change_description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}?ts=#{item?.lastModified}"
      date: item?.lastModified 
      date_formatted: "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"
      author: item?.name
      guid: "#{item?.lastModified}-#{change_title}"
    results.push result
    if item?.armory?.feed?
      wf.debug "there is a feed, so add that info - items:#{item.armory.feed.length}"
      for feed_item in item.armory.feed
        results.push @format_feed_item(feed_item, item)
    else
      wf.debug "no feed for char:#{item?.name}"
    if item?.armory?.news?
      wf.debug "there is news, so add that info - items:#{item.armory.news.length}"
      for news_item in item.armory.news
        results.push @format_news_item(news_item, item)
    else
      wf.debug "no news for char:#{item?.name}"
    return results

  item_link: (itemId) ->
    "<a href='http://www.wowhead.com/item=#{itemId}'>item</a>"

  achievement_link: (achievement) ->
    "<a href='http://www.wowhead.com/achievement=#{achievement.id}' alt='#{achievement.title}' title='#{achievement.title}'><img src='http://us.media.blizzard.com/wow/icons/56/#{achievement.icon}.jpg' align='left' style='border:solid yellow 1px;'></a>"

  char_link: (p) ->
    "<a href='http://#{p.region}.battle.net/wow/en/character/#{p.realm}/#{p.name}/simple' alt='#{p.name}' title='#{p.name}'><img src='http://#{p.region}.battle.net/static-render/#{p.region}/#{p.armory.thumbnail}' align='left' style='border:solid black 1px;'></a>"

  format_news_item: (news_item, item) ->
    dateMoment = moment(news_item.timestamp)
    change_title = "#{item?.name}:#{news_item.type}"
    description = "#{item?.name}:#{news_item.type}:character: #{news_item.character}, achievement:#{news_item.achievement?.description}"

    if news_item.type == "playerAchievement" or news_item.type == "guildAchievement"
      mentionGuild = ""
      mentionGuild = "guild " if news_item.type == "guildAchievement"
      change_title = "#{item.name} - #{news_item.character} gained the #{mentionGuild}achievement '#{news_item.achievement.title}'"
      description = "#{@achievement_link(news_item.achievement)}: #{news_item.achievement.description}"
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
      change_title = "#{news_item.character} bought some gear! Item id:#{news_item.itemId}"
      description = "#{@item_link(news_item.itemId)} *** Must find a way to get item names..."
      thingId = news_item.itemId

    else if news_item.type == "itemLoot"
      change_title = "#{news_item.character} got some loot! Item id:#{news_item.itemId}"
      description = "#{@item_link(news_item.itemId)} *** Must find a way to get item names..."
      thingId = news_item.itemId

    else if news_item.type == "itemCraft"
      change_title = "#{news_item.character} made an item! Item id:#{news_item.itemId}"
      description = "#{@item_link(news_item.itemId)} *** Must find a way to get item names..."
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
      date_formatted: "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"
      author: item?.name
      guid: "#{news_item.timestamp}-#{change_title}"
    return result

  format_feed_item: (feed_item, item) ->
    dateMoment = moment(feed_item.timestamp)

    change_title = "#{item?.name}:#{feed_item.achievement?.title}"
    description = "#{item?.name}:TYPE:#{feed_item.type}:#{feed_item.achievement?.description}"
    if feed_item.type == "ACHIEVEMENT"
      change_title = "#{item?.name} gained the achievement '#{feed_item.achievement.title}'"
      description = "#{@char_link(item)} - #{@achievement_link(feed_item.achievement)}: #{feed_item.achievement.description}"
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
      description = "#{@char_link(item)} - Step:#{feed_item.criteria.description} for #{feed_item.achievement?.description}"
      thingId = feed_item.criteria.id

    else if feed_item.type == "BOSSKILL"
      change_title = "#{item?.name} - '#{feed_item.criteria.description}'"
      description = "#{@char_link(item)} - Did:#{feed_item.criteria.description} for '#{feed_item.achievement.title}' - #{feed_item.achievement?.description}"
      thingId = feed_item.criteria.id

    else if feed_item.type == "LOOT"
      change_title = "#{item?.name} - got some loot! Item id:#{feed_item.itemId}"
      description = "#{@char_link(item)} - #{@item_link(feed_item.itemId)} *** Must find a way to get item names..."
      thingId = feed_item.itemId

    else
      description += " #{JSON.stringify(feed_item)}"

    result = 
      title: change_title
      description: description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}?ts=#{item?.lastModified}&id=#{thingId}"
      date: feed_item.timestamp
      date_formatted: "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"
      author: item?.name
      guid: "#{feed_item.timestamp}-#{change_title}"
    return result