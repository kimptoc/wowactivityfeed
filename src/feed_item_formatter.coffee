global.wf ||= {}

i18n = require('i18n')

require('./init_logger')
require('./wow')

# RELIES ON FIELDS BEING SELECTED IN wow.coffee - SO IF NOT SHOWING CHECK THERE

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

  process: (item, callback) ->
    locale = wf.set_locale(item?.locale, item?.armory?.realm, item?.armory?.region)
    wf.debug "format.process:#{item?.name}/#{item?.lastModified}/armory?:#{item?.armory?}/locale:#{item?.locale}-#{i18n.getLocale()}"
    item_ids = @get_items(item)
    wf.debug "got items, want #{item_ids.length}"
    wf.wow.load_items {item_ids,locale,region:item?.region}, (items) =>
      locale = wf.set_locale(item?.locale, item?.armory?.realm, item?.armory?.region)
      wf.debug "format.process - load_items, found:#{items.length}"
      results = []
      earliest_time = null
      if item?.armory?.feed?
        for feed_item in item.armory.feed
          update_obj = @format_feed_item(feed_item, item, items)
          earliest_time = update_obj.date if update_obj? and (!earliest_time? or earliest_time > update_obj.date)
          results.push update_obj if update_obj?
      if item?.armory?.news?
        for news_item in item.armory.news
          update_obj = @format_news_item(news_item, item, items)
          earliest_time = update_obj.date if update_obj? and (!earliest_time? or earliest_time > update_obj.date)
          results.push update_obj if update_obj?
      update_obj = @format_item(item, items, earliest_time)
      results.push update_obj if update_obj?
      callback?(results)

  achievement_link: (achievement) ->
    "<a href=\"http://www.wowhead.com/achievement=#{achievement.id}\" alt=\"#{achievement.title}\" title=\"#{achievement.title}\" rel='domain=#{i18n.getLocale()}'><img src=\"http://us.media.blizzard.com/wow/icons/56/#{achievement.icon}.jpg\" align='right' style='border:solid yellow 1px;'></a>"

  armory_link: (p) =>
    "http://#{p.region}.battle.net/wow/en/#{@wow_type(p.type)}/#{encodeURIComponent(p.realm)}/#{encodeURIComponent(p.name)}/"

  wow_type: (type) =>
    wow_type = type
    wow_type = 'character' if type == 'member'
    return wow_type

  armory_api_link: (p) =>
    "http://#{p.region}.battle.net/api/wow/#{@wow_type(p.type)}/#{encodeURIComponent(p.realm)}/#{encodeURIComponent(p.name)}?fields=achievements,guild,feed,hunterPets,professions,progression,pvp,quests,reputation,stats,talents,titles,items,pets,petSlots,mounts&locale=#{p.locale}"

  char_link: (p) =>
    alt_text = @get_formal_name(p)
    alt_text = "#{alt_text} (level #{p.armory.level})" if p.armory?.level?
    "<a href=\""+@armory_link(p)+"\" alt=\"#{alt_text}\" title=\"#{alt_text}\"><img src=\"http://#{p.region}.battle.net/static-render/#{p.region}/#{p.armory.thumbnail}\" align='left' style='border:solid black 1px;' class='char_image'></a>"

  get_formal_name: (p) ->
    # wf.debug "titles - get name #{JSON.stringify(p.armory?.titles)}"
    alt_text = "#{p?.armory?.name}"
    if p?.armory?.titles?
      # wf.debug "titles - found"
      for t in p.armory.titles
        # wf.debug "titles - this one? #{JSON.stringify(t)}"
        if t.selected?
          # wf.debug "titles - yes!"
          alt_text = t.name.replace /%s/, p.armory.name
    return alt_text

  char_name: (p) =>
    alt_text = @get_formal_name(p)
    alt_text = "#{alt_text} (level #{p.armory.level})" if p.armory?.level?
    "<a href=\""+@armory_link(p)+"\" alt='#{alt_text}' title='#{alt_text}'>#{p.armory.name}</a>"

  get_item: (items, item_id, locale, region) ->
#    wf.debug "Cache lookup:#{item_id}/#{locale}/#{region}"
    for item in items
#      wf.debug "Cache lookup vs:#{item.item_id}/#{item.locale}/#{item.region}"
      return item if item.item_id == item_id and item.locale == locale and item.region == region
#    wf.debug "Cache lookup - not found!"
    return null

  item_link: (item_id, items, region) ->
    #todo - handle not found, img link, wowhead link/hover...
    a_text = "<img src='http://us.media.blizzard.com/wow/icons/56/#{@get_item(items,item_id,i18n.getLocale(),region)?.icon}.jpg' align='right' style='border:solid yellow 1px;' title='#{@item_name(item_id, items, region)}' alt='#{@item_name(item_id, items, region)}'>"
    a_text = i18n.__("Unknown...") unless @get_item(items,item_id,i18n.getLocale(),region)
    return "<a href='http://www.wowhead.com/item=#{item_id}' rel='domain=#{i18n.getLocale()}'>#{a_text}</a>"

  item_name: (item_id, items, region) ->
    #todo - handle not found, img link, wowhead link/hover...
    return @get_item(items,item_id,i18n.getLocale(),region)?.name or i18n.__("Unknown....")

  waf_url: (item, feed_timestamp, thingId) ->
    the_url = "#{wf.SITE_URL}/view/#{item?.type}/#{encodeURIComponent(item?.region)}/#{encodeURIComponent(item?.realm)}/#{encodeURIComponent(item?.name)}/#{encodeURIComponent(item?.locale)}"
    the_url = the_url + "?ts=#{feed_timestamp}&id=#{thingId}" if feed_timestamp? or thingId?
    return the_url

  waf_rss_url: (item) ->
    "#{wf.SITE_URL}/feed/#{item?.type}/#{encodeURIComponent(item?.region)}/#{encodeURIComponent(item?.realm)}/#{encodeURIComponent(item?.name)}/#{encodeURIComponent(item?.locale)}.rss"

  add_criteria: (description, criteria) ->
    if criteria? and criteria.length >0
      criteria_description = ""
      done_first = false
      for crit in criteria
        if crit.description.length >0
          criteria_description += ", " if done_first
          criteria_description += "#{crit.description}"
          done_first = true
      # wf.debug "criteria_description=#{criteria_description}."
      description = "#{description} [#{criteria_description}]" if criteria_description.length >0
    return description

  format_item: (item, items, earliest_time) ->
    change_title = " #{@get_formal_name(item)} "
    change_title = "#{change_title} - " if item?.type == "guild"
    change_title = "#{change_title} (#{item.armory.guild.name}) " if item?.armory?.guild?.name?
    change_description = ""
    change_date = item?.lastModified
    if item? and item.whats_changed?
      if item.whats_changed.overview == "NEW"
        change_description = i18n.__("And as if by magic, %s appeared!",item?.armory?.name)
        change_date = earliest_time if earliest_time?
      else
        if item.whats_changed.changes.level?
          change_title = i18n.__(" %s - level %s! ",@get_formal_name(item),@get('level',item))
          change_description += i18n.__("Now at level %s! ",@get('level',item))
        if item.whats_changed.changes.achievementPoints?
          change_description += i18n.__("Yay, more achievement points - now at %s. ",@get('achievementPoints',item))
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
            change_description += i18n.__("Gear change: %s. ",gear_change)
        if item.whats_changed.changes.reputation_map? and ! (item.whats_changed.changes.reputation_map instanceof Array)
          rep_change = ""
          for own name, values of item.whats_changed.changes.reputation_map
            if values instanceof Array
              if values.length == 1
                rep_change += ", " if rep_change.length >0
                rep_change += i18n.__("%s(new):%s",name,values[0].value)
            else
              rep_change += ", " if rep_change.length >0
              wf.debug "#{item.name}:Checking rep #{name}, values #{JSON.stringify(values.value)}"
              rep_change += "#{name}:#{@get_new_one(values.value)}"
          change_description += i18n.__("Rep change(s): %s. ",rep_change)
        if item.whats_changed.changes.members_map?
          member_title = ""
          member_desc = ""
          for own name, member_info of item.whats_changed.changes.members_map
            if member_info instanceof Array
              if member_info.length == 1
                member_desc += ", " if member_desc.length >0
                member_desc += i18n.__("%s has joined",member_info[0].character.name)
              else if member_info.length == 3
                member_desc += ", " if member_desc.length >0
                member_desc += i18n.__("%s has left",member_info[0].character.name)
          change_title += i18n.__("Guild membership changed! ") if member_desc.length >0
          change_description += i18n.__("Guild membership has changed: %s. ",member_desc) if member_desc.length >0
        if item.whats_changed.changes.mounts_collected_map?
          mounts_title = ""
          mounts_desc = ""
          for own name, mount_info of item.whats_changed.changes.mounts_collected_map
            if mount_info instanceof Array
              if mount_info.length == 1
                mounts_title += ", " if mounts_title.length >0
                mounts_title += "#{mount_info[0].name}"
                mounts_desc += ", " if mounts_desc.length >0
                mounts_desc += "#{mount_info[0].name}"
          change_title += i18n.__("New mount(s): %s ",mounts_title) if mounts_title.length >0
          change_description += i18n.__("Gained some mount(s): %s. ",mounts_desc) if mounts_desc.length >0
        if item.whats_changed.changes.pets_collected_map?
          pets_title = ""
          pets_desc = ""
          for own name, pet_info of item.whats_changed.changes.pets_collected_map
            if pet_info instanceof Array
              if pet_info.length == 1
                pets_title += ", " if pets_title.length >0
                pets_title += "#{pet_info[0].name}"
                pets_desc += ", " if pets_desc.length >0
                pets_desc += "#{pet_info[0].name}"
          change_title += i18n.__("New pet(s):%s ",pets_title) if pets_title.length >0
          change_description += i18n.__("Gained some pet(s): %s. ",pets_desc) if pets_desc.length >0
        if item.whats_changed.changes.titles_map?
          titles_title = ""
          titles_desc = ""
          for own name, title_info of item.whats_changed.changes.titles_map
            if title_info instanceof Array
              if title_info.length == 1
                titles_title += ", " if titles_title.length >0
                titles_title += "'#{name}'"
                titles_desc += ", " if titles_desc.length >0
                titles_desc += "'#{name}'"
          change_title += i18n.__("New title(s):%s ",titles_title) if titles_title.length >0
          change_description += i18n.__("Gained some title(s): %s. ",titles_desc) if titles_desc.length >0
        if item.whats_changed.changes.professions_map?
          professions_desc = ""
          for own name, prof_info of item.whats_changed.changes.professions_map
            if prof_info instanceof Array
              if prof_info.length == 1
                professions_desc += ", " if professions_desc.length >0
                professions_desc += i18n.__("Took up %s",name)
              else if prof_info.length == 3
                professions_desc += ", " if professions_desc.length >0
                professions_desc += i18n.__("Gave up %s",name)
            else
              if prof_info.rank?
                professions_desc += ", " if professions_desc.length >0
                professions_desc += i18n.__("%s is now rank %s",name,@get_new_one(prof_info.rank))
          change_description += i18n.__("Profession(s): %s. ",professions_desc) if professions_desc.length >0

    # if we dont identify a change above, then assume none
    if change_description == ""
      wf.debug "No change found, so not generating a feed item"
      return null
    max_title_length = 75
    max_description_length = 300
    if change_title.length > max_title_length
      change_title = change_title.substring(0,max_title_length)+"..."
    if change_description.length > max_description_length
      change_description = change_description.substring(0,max_description_length)+"..."
    if item?.type == "member" and item.armory?.thumbnail?
      change_description = "#{@char_link(item)} #{@char_name(item)}: #{change_description}"
    else if item?.type == "guild"
      change_description = "#{@char_name(item)}: #{change_description}"
    result = 
      title: change_title
      description: change_description
      wow_type: @wow_type(item?.type)
      url: @waf_url(item, item?.lastModified,null)
      waf_url: @waf_url(item)
      waf_rss_url: @waf_rss_url(item)
      armory_link: @armory_link(item)
      armory_api_link: @armory_api_link(item)
      date: change_date
      date_formatted: wf.format_date(change_date)
      author: item?.armory?.name
      guild: item?.armory?.guild?.name
      guid: "#{change_date}-#{change_title}"
    return result

  format_news_item: (news_item, item, items) ->
    change_title = "#{item?.armory.name}:#{news_item.type}"
    description = "#{item?.armory.name}:#{news_item.type}:#{i18n.__('character')}: #{news_item.character}, i18n.__('achievement')}:#{news_item.achievement?.description}"

    if news_item.type == "playerAchievement"
      return null # ignore these, assume covered by the player news feed

    if news_item.type == "guildAchievement"
      mentionGuild = ""
      mentionGuild = i18n.__("guild ") if news_item.type == "guildAchievement"
      change_title = i18n.__("%s - %s gained the %s achievement '%s'",
        item.armory.name,news_item.character,mentionGuild,news_item.achievement.title)
      description = "#{news_item.character} #{i18n.__('achieved')} #{news_item.achievement.title}: #{news_item.achievement.description} #{@achievement_link(news_item.achievement)}"
      thingId = news_item.achievement.id
      description = @add_criteria description, news_item.achievement.criteria
      description += i18n.__(" (%s pts)",news_item.achievement.points)

    else if news_item.type == "itemPurchase"
      change_title = i18n.__("%s - %s bought %s",item.armory.name,news_item.character,@item_name(news_item.itemId, items, item?.region))
      description = i18n.__("%s bought %s %s",news_item.character,@item_name(news_item.itemId, items, item?.region),@item_link(news_item.itemId, items, item?.region))
      thingId = news_item.itemId

    else if news_item.type == "itemLoot"
      change_title = i18n.__("%s - %s got some loot - %s",item.armory.name,news_item.character,@item_name(news_item.itemId, items, item?.region))
      description = i18n.__("%s got %s %s",news_item.character,@item_name(news_item.itemId, items, item?.region),@item_link(news_item.itemId, items, item?.region))
      thingId = news_item.itemId

    else if news_item.type == "itemCraft"
      change_title = i18n.__("%s - %s made %s",item.armory.name,news_item.character,@item_name(news_item.itemId, items, item?.region))
      description = i18n.__("%s made %s %s",news_item.character,@item_name(news_item.itemId, items, item?.region),@item_link(news_item.itemId, items, item?.region))
      thingId = news_item.itemId

    else if news_item.type == "guildLevel"
      change_title = i18n.__("%s is now level %s!",item.armory.name,news_item.levelUp)
      description = i18n.__("Guild %s is now at guild level %s!",item.armory.name,news_item.levelUp)
      thingId = news_item.itemId

    else
      description += " #{JSON.stringify(news_item)}"

    result = 
      title: change_title
      description: description
      wow_type: @wow_type(item?.type)
      url: @waf_url(item, news_item.timestamp,thingId)
      waf_url: @waf_url(item)
      waf_rss_url: @waf_rss_url(item)
      armory_link: @armory_link(item)
      armory_api_link: @armory_api_link(item)
      date: news_item.timestamp
      date_formatted: wf.format_date(news_item.timestamp)
      author: item?.armory.name
      guild: item?.armory?.guild?.name
      guid: "#{news_item.timestamp}-#{change_title}"
    return result

  format_feed_item: (feed_item, item, items) ->

    change_title = "#{@get_formal_name(item)}:#{feed_item.achievement?.title}"
    description = i18n.__("%s:TYPE:%s:%s",item?.armory.name,feed_item.type,feed_item.achievement?.description)
    if feed_item.type == "ACHIEVEMENT"
      change_title = i18n.__("%s gained the achievement '%s'",@get_formal_name(item),feed_item.achievement.title)
      description = "#{@char_link(item)} #{@char_name(item)} - #{@achievement_link(feed_item.achievement)} #{feed_item.achievement.title}: #{feed_item.achievement.description}"
      thingId = feed_item.achievement.id
      description = @add_criteria description, feed_item.achievement.criteria
      description += i18n.__(" (%s pts)",feed_item.achievement.points)

    else if feed_item.type == "CRITERIA"
      change_title = i18n.__("%s progressed towards achievement '%s'",@get_formal_name(item),feed_item.achievement.title)
      achievement_description = i18n.__("%s Progressing towards achievement %s",feed_item.achievement?.description,feed_item.achievement.title)
      achievement_description = feed_item.achievement?.title if achievement_description.indexOf(feed_item.criteria.description) >= 0
      description = i18n.__("%s %s - Step:'%s' for '%s'",@char_link(item),@char_name(item),feed_item.criteria.description,achievement_description)
      thingId = feed_item.criteria.id

    else if feed_item.type == "BOSSKILL"
      change_title = "#{@get_formal_name(item)} - '#{feed_item.criteria.description}'"
      description = i18n.__("%s %s Did:'%s' for '%s' - %s",@char_link(item),@char_name(item),feed_item.criteria.description,feed_item.achievement.title,feed_item.achievement?.description)
      thingId = feed_item.criteria.id

    else if feed_item.type == "LOOT"
      change_title = i18n.__("%s - got some loot - %s!",@get_formal_name(item),@item_name(feed_item.itemId, items, item?.region))
      description = i18n.__("%s %s now has %s! %s",@char_link(item),@char_name(item),@item_name(feed_item.itemId, items, item?.region),@item_link(feed_item.itemId, items, item?.region))
      thingId = feed_item.itemId

    else
      description += " #{JSON.stringify(feed_item)}"
      wf.error "Unrecognised type:#{feed_item.type}:#{description}"

    result = 
      title: change_title
      description: description
      wow_type: @wow_type(item?.type)
      url: @waf_url(item, feed_item.timestamp,thingId)
      waf_url: @waf_url(item)
      waf_rss_url: @waf_rss_url(item)
      armory_link: @armory_link(item)
      armory_api_link: @armory_api_link(item)
      date: feed_item.timestamp
      date_formatted: wf.format_date(feed_item.timestamp)
      author: item?.armory.name
      guild: item?.armory?.guild?.name
      guid: "#{feed_item.timestamp}-#{change_title}"

    return result