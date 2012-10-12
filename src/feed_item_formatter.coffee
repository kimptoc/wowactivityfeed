global.wf ||= {}

require('./init_logger')

class wf.FeedItemFormatter

  process: (item) ->
    change_description = ""
    if item? and item.whats_changed?
      if item.whats_changed.overview == "NEW"
        change_description = "And as if by magic, #{item.name} appeared!"
      else
        if item.whats_changed.changes.level?
          change_description += "#{item.name} is now level #{item.level}! "
        if item.whats_changed.changes.achievementPoints?
          change_description += "Yay, more achievement points - now at #{item.achievementPoints}. "
    if change_description == ""
      change_description = "Something about #{item?.name} has changed, not quite sure what, its a mystery..."
    result = 
      title: "#{item?.name}:"
      description: change_description
      url: "#{wf.SITE_URL}/view/#{item?.type}/#{item?.region}/#{item?.realm}/#{item?.name}"
      date: item?.lastModified 
    return result
