global.wf ||= {}

jsdiff = require "jsondiffpatch"

wf.calc_changes = (old_obj, new_obj) ->
  if old_obj?
    changes = 
      overview : "UPDATE"
      changes : jsdiff.diff(old_obj, new_obj)
  else
    changes = 
      overview : "NEW"

  return changes