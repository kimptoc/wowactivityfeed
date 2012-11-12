global.wf ||= {}

moment = require 'moment'

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

  format_date: (dt) ->
    dateMoment = moment(dt)
    "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"    

  process: (item, callback) ->
    wf.debug "format.process:#{item?.name}/#{item?.lastModified}/armory?:#{item?.armory?}"
    item_ids = @get_items(item)
    wf.debug "got items, #{item_ids.length}"
    wf.wow.load_items item_ids, (items) =>
      wf.debug "format.process - load_items"
      results = []
      update_obj = @format_item(item, items)
      results.push update_obj if update_obj?
      if item?.armory?.feed?
        for feed_item in item.armory.feed
          update_obj = @format_feed_item(feed_item, item, items)
          results.push update_obj if update_obj?
      if item?.armory?.news?
        for news_item in item.armory.news
          update_obj = @format_news_item(news_item, item, items)
          results.push update_obj if update_obj?
      callback?(results)

  achievement_link: (achievement) ->
    "<a href='http://www.wowhead.com/achievement=#{achievement.id}' alt='#{achievement.title}' title='#{achievement.title}'><img src='http://us.media.blizzard.com/wow/icons/56/#{achievement.icon}.jpg' align='right' style='border:solid yellow 1px;'></a>"

  char_link: (p) =>
    alt_text = @get_formal_name(p)
    alt_text = "#{alt_text} (level #{p.armory.level})" if p.armory?.level?
    "<a href='http://#{p.region}.battle.net/wow/en/character/#{escape(p.realm)}/#{escape(p.name)}/simple' alt='#{alt_text}' title='#{alt_text}'><img src='http://#{p.region}.battle.net/static-render/#{p.region}/#{p.armory.thumbnail}' align='left' style='border:solid black 1px;' class='char_image'></a>"

  get_formal_name: (p) ->
    # wf.debug "titles - get name #{JSON.stringify(p.armory?.titles)}"
    alt_text = "#{p?.name}"
    if p?.armory?.titles?
      # wf.debug "titles - found"
      for t in p.armory.titles
        # wf.debug "titles - this one? #{JSON.stringify(t)}"
        if t.selected?
          # wf.debug "titles - yes!"
          alt_text = t.name.replace /%s/, p.name
    return alt_text

  char_name: (p) =>
    alt_text = @get_formal_name(p)
    alt_text = "#{alt_text} (level #{p.armory.level})" if p.armory?.level?
    "<a href='http://#{p.region}.battle.net/wow/en/character/#{escape(p.realm)}/#{escape(p.name)}/simple' alt='#{alt_text}' title='#{alt_text}'>#{p.name}</a>"

  item_link: (item_id, items) ->
    #todo - handle not found, img link, wowhead link/hover...
    a_text = "<img src='http://us.media.blizzard.com/wow/icons/56/#{items?[item_id]?.icon}.jpg' align='right' style='border:solid yellow 1px;' title='#{@item_name(item_id, items)}' alt='#{@item_name(item_id, items)}'>"
    a_text = "Unknown..." unless items?[item_id]
    return "<a href='http://www.wowhead.com/item=#{item_id}'>#{a_text}</a>"

  item_name: (item_id, items) ->
    #todo - handle not found, img link, wowhead link/hover...
    name = items?[item_id]?.name
    name ||= "Unknown...."

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

  format_item: (item, items) ->
    change_title = " #{@get_formal_name(item)} "
    change_title = "#{change_title} - " if item?.type == "guild"
    change_title = "#{change_title} (#{item.armory.guild.name}) " if item?.armory?.guild?.name?
    change_description = ""
    if item? and item.whats_changed?
      if item.whats_changed.overview == "NEW"
        change_description = " And as if by magic, #{item.name} appeared!"
      else
        if item.whats_changed.changes.level?
          change_title = " #{@get_formal_name(item)} - level #{@get('level',item)}! "
          change_description += "Now at level #{@get('level',item)}! "
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
        if item.whats_changed.changes.reputation_map? and ! (item.whats_changed.changes.reputation_map instanceof Array)
          rep_change = ""
          for own name, values of item.whats_changed.changes.reputation_map
            rep_change += ", " if rep_change.length >0
            rep_change += "#{name}:#{@get_new_one(values.value)}"
          change_description += "Rep change(s): #{rep_change}. "
        if item.whats_changed.changes.members_map?
          member_title = ""
          member_desc = ""
          for own name, member_info of item.whats_changed.changes.members_map
            if member_info instanceof Array
              if member_info.length == 1
                member_title += ", " if member_title.length >0
                member_title += "#{member_info[0].character.name} joined"
                member_desc += ", " if member_desc.length >0
                member_desc += "#{member_info[0].character.name} has joined"
              else if member_info.length == 3
                member_title += ", " if member_title.length >0
                member_title += "#{member_info[0].character.name} left "
                member_desc += ", " if member_desc.length >0
                member_desc += "#{member_info[0].character.name} has left"
          change_title += "member change(s): #{member_title} " if member_title.length >0
          change_description += "Guild membership has changed: #{member_desc} " if member_desc.length >0
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
          change_title += "New mount(s): #{mounts_title} " if mounts_title.length >0
          change_description += "Gained some mount(s): #{mounts_desc} " if mounts_desc.length >0
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
          change_title += "New pet(s): #{pets_title} " if pets_title.length >0
          change_description += "Gained some pet(s): #{pets_desc} " if pets_desc.length >0
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
          change_title += "New title(s): #{titles_title} " if titles_title.length >0
          change_description += "Gained some title(s): #{titles_desc} " if titles_desc.length >0
        if item.whats_changed.changes.professions_map?
          professions_desc = ""
          for own name, prof_info of item.whats_changed.changes.professions_map
            if prof_info instanceof Array
              if prof_info.length == 1
                professions_desc += ", " if professions_desc.length >0
                professions_desc += "Took up #{name}"
              else if prof_info.length == 3
                professions_desc += ", " if professions_desc.length >0
                professions_desc += "Gave up #{name}"
            else
              if prof_info.rank?
                professions_desc += ", " if professions_desc.length >0
                professions_desc += "#{name} is now rank #{@get_new_one(prof_info.rank)}"
          change_description += "Profession(s): #{professions_desc} " if professions_desc.length >0

    # if we dont identify a change above, then assume none
    if change_description == ""
      wf.debug "No change found, so not generating a feed item"
      return null
    if item?.type == "member" and item.armory?.thumbnail?
      change_description = "#{@char_link(item)} #{@char_name(item)} #{change_description}"
    else if item?.type == "guild"
      change_description = "#{@char_name(item)} #{change_description}"
    result = 
      title: change_title
      description: change_description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{escape(item?.region)}/#{escape(item?.realm)}/#{escape(item?.name)}?ts=#{item?.lastModified}"
      date: item?.lastModified 
      date_formatted: @format_date(item?.lastModified)
      author: item?.name
      guid: "#{item?.lastModified}-#{change_title}"
    return result

  format_news_item: (news_item, item, items) ->
    change_title = "#{item?.name}:#{news_item.type}"
    description = "#{item?.name}:#{news_item.type}:character: #{news_item.character}, achievement:#{news_item.achievement?.description}"

    if news_item.type == "playerAchievement"
      return null # ignore these, assume covered by the player news feed

    if news_item.type == "guildAchievement"
      mentionGuild = ""
      mentionGuild = "guild " if news_item.type == "guildAchievement"
      change_title = "#{item.name} - #{news_item.character} gained the #{mentionGuild}achievement '#{news_item.achievement.title}'"
      description = "#{news_item.character} achieved #{news_item.achievement.title}: #{news_item.achievement.description} #{@achievement_link(news_item.achievement)}"
      thingId = news_item.achievement.id
      description = @add_criteria description, news_item.achievement.criteria
      description += " (#{news_item.achievement.points}pts)"

    else if news_item.type == "itemPurchase"
      change_title = "#{item.name} - #{news_item.character} bought #{@item_name(news_item.itemId, items)}"
      description = "#{news_item.character} bought #{@item_name(news_item.itemId, items)} #{@item_link(news_item.itemId, items)}"
      thingId = news_item.itemId

    else if news_item.type == "itemLoot"
      change_title = "#{item.name} - #{news_item.character} got some loot - #{@item_name(news_item.itemId, items)}"
      description = "#{news_item.character} got #{@item_name(news_item.itemId, items)} #{@item_link(news_item.itemId, items)}"
      thingId = news_item.itemId

    else if news_item.type == "itemCraft"
      change_title = "#{item.name} - #{news_item.character} made #{@item_name(news_item.itemId, items)}"
      description = "#{news_item.character} made #{@item_name(news_item.itemId, items)} #{@item_link(news_item.itemId, items)}"
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
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{escape(item?.region)}/#{escape(item?.realm)}/#{escape(item?.name)}?ts=#{news_item.timestamp}&id=#{thingId}"
      date: news_item.timestamp
      date_formatted: @format_date(news_item.timestamp)
      author: item?.name
      guid: "#{news_item.timestamp}-#{change_title}"
    return result

  format_feed_item: (feed_item, item, items) ->

    change_title = "#{@get_formal_name(item)}:#{feed_item.achievement?.title}"
    description = "#{item?.name}:TYPE:#{feed_item.type}:#{feed_item.achievement?.description}"
    if feed_item.type == "ACHIEVEMENT"
      change_title = "#{@get_formal_name(item)} gained the achievement '#{feed_item.achievement.title}'"
      description = "#{@char_link(item)} #{@char_name(item)} - #{@achievement_link(feed_item.achievement)} #{feed_item.achievement.title}: #{feed_item.achievement.description}"
      thingId = feed_item.achievement.id
      description = @add_criteria description, feed_item.achievement.criteria
      description += " (#{feed_item.achievement.points}pts)"

    else if feed_item.type == "CRITERIA"
      change_title = "#{@get_formal_name(item)} progressed towards achievement '#{feed_item.achievement.title}'"
      achievement_description = "#{feed_item.achievement?.description} Progressing towards achievement #{feed_item.achievement.title}"
      achievement_description = feed_item.achievement?.title if achievement_description.indexOf(feed_item.criteria.description) >= 0
      description = "#{@char_link(item)} #{@char_name(item)} - Step:'#{feed_item.criteria.description}' for '#{achievement_description}'"
      thingId = feed_item.criteria.id

    else if feed_item.type == "BOSSKILL"
      change_title = "#{@get_formal_name(item)} - '#{feed_item.criteria.description}'"
      description = "#{@char_link(item)} #{@char_name(item)} Did:'#{feed_item.criteria.description}' for '#{feed_item.achievement.title}' - #{feed_item.achievement?.description}"
      thingId = feed_item.criteria.id

    else if feed_item.type == "LOOT"
      change_title = "#{@get_formal_name(item)} - got some loot - #{@item_name(feed_item.itemId, items)}!"
      description = "#{@char_link(item)} #{@char_name(item)} now has #{@item_name(feed_item.itemId, items)}! #{@item_link(feed_item.itemId, items)}"
      thingId = feed_item.itemId

    else
      description += " #{JSON.stringify(feed_item)}"

    result = 
      title: change_title
      description: description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{escape(item?.region)}/#{escape(item?.realm)}/#{escape(item?.name)}?ts=#{feed_item.timestamp}&id=#{thingId}"
      date: feed_item.timestamp
      date_formatted: @format_date(feed_item.timestamp)
      author: item?.name
      guid: "#{feed_item.timestamp}-#{change_title}"
    return result