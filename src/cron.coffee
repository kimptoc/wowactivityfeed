global.wf ||= {}

cronJob = require('cron').CronJob

wf.armory_load_requested = false

create_cron = (cron_schedule, cron_task) ->
  try 
    new_cron_job = new cronJob cron_schedule, cron_task,
      null, 
      true, #/* Start the job right now */,
      null #/* Time zone of this job. */
  catch e
    wf.error e


wf.hourlyjob = create_cron '00 00 0-21/3 * * *', (-> 
  wf.info "cronjob tick...hourly load"
  wf.armory_load_requested = true
  )

wf.hourlyjob = create_cron '00 30 1-22/3 * * *', (-> 
  wf.info "cronjob tick...hourly load"
  wf.armory_load_requested = true
  )

wf.loadjob = create_cron '*/10 * * * * *', (-> 
  wf.debug "cronjob tick...check if armory load requested"
  if wf.armory_load_requested
    wf.armory_load_requested = false
    wf.info "time for armory_load..."
    wf.wow.armory_load()
  )

wf.loadjob = create_cron '00 42 * * * *', (-> 
  wf.info "Reloading realms"
  wf.wow.realms_loader ->
    wf.info "Realm reload complete"
  )

# wf.staticjob = new cronJob '00 00 00 * * *', (-> 
#   wf.debug "cronjob tick...load armory static"
#   wf.wow.static_load()
#   ),
#   null, 
#   true, #/* Start the job right now */,
#   null #/* Time zone of this job. */

