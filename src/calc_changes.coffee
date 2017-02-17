global.wf ||= {}

jsdiff = require "jsondiffpatch"

wf.calc_changes = (old_obj, new_obj) ->
  if old_obj?
    try
      whats_changed =
        overview : "UPDATE"
        changes : jsdiff.diff(old_obj, new_obj)
    catch e
      wf.error "OLD:#{old_obj}"
      wf.error "NEW:#{new_obj}"
      wf.error "jsdiff.diff:#{e}"
      whats_changed =
        overview : "UPDATE"
        changes : {}
  else
    whats_changed =
      overview : "NEW"

  return whats_changed

wf.makeCopy = (obj) ->
    cloned_obj = JSON.parse(JSON.stringify(obj), jsdiff.dateReviver);

wf.restore = (whats_changed, new_obj) ->
  old_obj = wf.makeCopy(new_obj)
  if whats_changed?.overview == "UPDATE" and whats_changed?.changes?
    try
      jsdiff.unpatch(old_obj, whats_changed?.changes)
    catch e
      wf.error "OLD:#{JSON.stringify(old_obj).length}/CHANGES:#{JSON.stringify(whats_changed?.changes).length}/jsdiff.unpatch:#{e}"

  return old_obj
