global.wf ||= {}

jsdiff = require "jsondiffpatch"

wf.calc_changes = (old_obj, new_obj) ->
  if old_obj?
    whats_changed = 
      overview : "UPDATE"
      changes : jsdiff.diff(old_obj, new_obj)
  else
    whats_changed = 
      overview : "NEW"

  return whats_changed

makeCopy = (obj) ->
    cloned_obj = JSON.parse(JSON.stringify(obj), jsdiff.dateReviver);

wf.restore = (whats_changed, new_obj) ->
  old_obj = makeCopy(new_obj)
  if whats_changed?.overview == "UPDATE"
    jsdiff.unpatch(old_obj, whats_changed?.changes)
  return old_obj
