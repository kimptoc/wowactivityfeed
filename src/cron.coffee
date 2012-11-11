global.wf ||= {}

cronJob = require('cron').CronJob

wf.armory_load_requested = false

wf.hourlyjob = new cronJob '00 */90 */1 * * *', (-> 
  wf.info "cronjob tick...hourly load"
  wf.armory_load_requested = true
  ),
  null, 
  true, #/* Start the job right now */,
  null #/* Time zone of this job. */

wf.loadjob = new cronJob '*/10 * * * * *', (-> 
  wf.debug "cronjob tick...check if armory load requested"
  if wf.armory_load_requested
    wf.armory_load_requested = false
    wf.info "time for armory_load..."
    wf.wow.armory_load()
  ),
  null, 
  true, #/* Start the job right now */,
  null #/* Time zone of this job. */

# wf.staticjob = new cronJob '00 00 00 * * *', (-> 
#   wf.debug "cronjob tick...load armory static"
#   wf.wow.static_load()
#   ),
#   null, 
#   true, #/* Start the job right now */,
#   null #/* Time zone of this job. */

