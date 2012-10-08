global.wf ||= {}

jsdiff = require "jsondiffpatch"

wf.calc_changes = (old_obj, new_obj) ->
  if old_obj?
    delete old_obj["_id"]
    delete old_obj["whats_changed"]
    changes = 
      overview : "UPDATE"
      changes : jsdiff.diff(old_obj, new_obj)
  else
    changes = 
      overview : "NEW"

  return changes