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
        result = 
          title: "#{item?.name}:#{feed_item.achievement?.description}"
          description: "#{item?.name}:#{feed_item.type}:#{feed_item.achievement?.description}"
          url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}"
          date: feed_item.timestamp
          date_formatted: "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"
        results.push result
    else
      wf.debug "no feed for char:#{item?.name}"
    if item?.armory?.news?
      wf.debug "there is news, so add that info - items:#{item.armory.news.length}"
      for news_item in item.armory.news
        result = 
          title: "#{item?.name}:#{news_item.type}"
          description: "#{item?.name}:#{news_item.type}:#{news_item.character}:#{news_item.achievement?.description}"
          url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}"
          date: news_item.timestamp
          date_formatted: "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"
        results.push result
    else
      wf.debug "no news for char:#{item?.name}"
    return results
