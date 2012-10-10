global.wf ||= {}

class wf.FeedItemFormatter

  process: (item) ->
    change_description = "Something about #{item.name} has changed, not quite sure what, its a mystery..."
    if item.whats_changed.overview == "NEW"
      change_description = "And as if by magic, #{item.name} appeared!"
    else
      if item.whats_changed.level?
        change_description = "#{item.name} is now level #{item.level}!"
    result = 
      title: "#{item.name}:"
      description: change_description
      url: "#{wf.SITE_URL}/view/#{item.type}/#{item.region}/#{item.realm}/#{item.name}"
      date: item.lastModified 
    return result
