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
    change_description = ""
    if item? and item.whats_changed?
      if item.whats_changed.overview == "NEW"
        change_description = "And as if by magic, #{item.name} appeared!"
      else
        if item.whats_changed.changes.level?
          change_description += "#{item.name} is now level #{@get('level',item)}! "
        if item.whats_changed.changes.achievementPoints?
          change_description += "Yay, more achievement points - now at #{@get('achievementPoints',item)}. "
    if change_description == ""
      change_description = "Something about #{item?.name} has changed, not quite sure what, its a mystery..."
    dateMoment = moment(item?.lastModified)
    result = 
      title: "#{item?.name}:"
      description: change_description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}"
      date: item?.lastModified 
      date_formatted: "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"
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

  format_news_item: (news_item, item) ->
    dateMoment = moment(news_item.timestamp)
    title = "#{item?.name}:#{news_item.type}"
    description = "#{item?.name}:#{news_item.type}:character: #{news_item.character}, achievement:#{news_item.achievement?.description}"

    if news_item.type == "playerAchievement"
      title = "#{item.name} - #{news_item.character} gained the achievement '#{news_item.achievement.title}'"
      description = "#{news_item.achievement.description}"
      if news_item.achievement.criteria and news_item.achievement.criteria.length >0
        description += " ["
        done_first = false
        for crit in news_item.achievement.criteria
          description += "," if done_first
          description += " #{crit.description}"
          done_first = true
        description += "]"
      description += " (#{news_item.achievement.points}pts)"

    result = 
      title: title
      description: description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}"
      date: news_item.timestamp
      date_formatted: "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"
    return result

  format_feed_item: (feed_item, item) ->
    dateMoment = moment(feed_item.timestamp)

    title = "#{item?.name}:#{feed_item.achievement?.title}"
    description = "#{item?.name}:#{feed_item.type}:#{feed_item.achievement?.description}"
    if feed_item.type == "ACHIEVEMENT"
      title = "#{item?.name} gained the achievement '#{feed_item.achievement.title}'"
      description = "#{feed_item.achievement?.description}"
      if feed_item.achievement.criteria and feed_item.achievement.criteria.length >0
        description += " ["
        done_first = false
        for crit in feed_item.achievement.criteria
          description += "," if done_first
          description += " #{crit.description}"
          done_first = true
        description += "]"
      description += " (#{feed_item.achievement.points}pts)"

    if feed_item.type == "CRITERIA"
      title = "#{item?.name} progressed towards achievement '#{feed_item.achievement.title}'"
      description = "Step:#{feed_item.criteria.description} for #{feed_item.achievement?.description}"

    result = 
      title: title
      description: description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}"
      date: feed_item.timestamp
      date_formatted: "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"
    return result