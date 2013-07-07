global.wf ||= {}

# wf.timing = (obj, fn) ->
#   wf.info "timing:#{obj}, #{fn}"
#   obj["#{fn}_timingorig_"] = obj[fn]
#   obj[fn] = (args...) ->
#     args_in = ""
#     # for arg in args
#       # args_in = "#{JSON.stringify(arg)}," unless typeof arg is 'function'
#     args_in += "#{JSON.stringify(args[0])},"
#     args_in += "#{JSON.stringify(args[1])},"
#     args_in += "#{JSON.stringify(args[2])},"
#     start_time = new Date().getTime()
#     obj["#{fn}_timingorig_"].apply(obj, args)
#     elapsed = new Date().getTime() - start_time
#     wf.debug "Elapsed time:#{elapsed}ms:#{fn}(#{args_in}):"

wf.timings = {}

wf.timing_on = (name) ->
  wf.timings[name] = new Date().getTime()

wf.timing_off = (name) ->
  start = wf.timings[name]
  if start?
    elapsed = new Date().getTime() - start
    wf.debug "Elapsed time:#{elapsed}ms:#{name}"
    wf.timing new Error("Elapsed time:#{elapsed}ms:#{name}") if elapsed > 3000
  else
    wf.warn "No timing info found for #{name}, timings:#{JSON.stringify(wf.timings)}"