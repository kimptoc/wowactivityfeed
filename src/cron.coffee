global.wf ||= {}

_ = require('underscore')
cronJob = require('cron').CronJob
moment = require "moment"


wf.armory_load_requested = false

create_cron = (cron_schedule, cron_task) ->
  try 
    new_cron_job = new cronJob cron_schedule, cron_task,
      null, 
      true, #/* Start the job right now */,
      null #/* Time zone of this job. */
  catch e
    wf.error e


wf.hourlyjob = create_cron '00 00 * * * *', -> 
  wf.info "cronjob tick...hourly, on the hour load"
  wf.armory_load_requested = true

wf.info_queue = []


push_info = (msg) ->
  now = new Date()
  wf.info_queue.unshift 
    title: "WoW Activity Info @ #{moment(new Date()).format("H:mm D MMM")}"
    description: msg
    date: now
    guid: now.getTime()
    url: "#{wf.SITE_URL}?ts=#{now.getTime()}"
  wf.info_queue = _.first(wf.info_queue,wf.INFO_HISTORY_LIMIT)


# count of guilds/members registered
wf.counts1job = create_cron '00 10 3,10,15,21,23 * * *', -> 
# wf.counts1job = create_cron '*/10 * * * * *', -> 
  wf.info "cronjob tick...6 hourly, guild/member counts"
  if wf.wow?
    wf.wow.get_store().count wf.wow.get_registered_collection(), {type:'guild'}, (num_guilds) ->
      wf.wow.get_store().count wf.wow.get_registered_collection(), {type:'member'}, (num_chars) ->
        push_info("There are currently #{num_guilds} guilds and #{num_chars} members registered.")

# how to use waf
wf.counts3job = create_cron '00 40 2,8,14,20 * * *', -> 
# wf.counts3job = create_cron '*/10 * * * * *', -> 
  wf.info "cronjob tick...6 hourly, how to"
  push_info("Want to know how to use your guild/character feed on your site - see the <a href='https://wafbeta.uservoice.com/'>help</a>.")



# count of calls yesterday
# wf.counts2job = create_cron '*/10 * * * * *', -> 
wf.counts2job = create_cron '00 25 02 * * *', -> 
  wf.info "cronjob tick...daily guild/member calls"
  if wf.wow?
    start_of_day = moment().startOf('day').valueOf()
    yesterday = moment().startOf('day').subtract(days:1).valueOf()
    wf.wow.get_store().count wf.wow.get_calls_collection(), {type:'guild', start_time:{$gte:yesterday, $lt:start_of_day}}, (num_guilds) ->
      wf.wow.get_store().count wf.wow.get_calls_collection(), {type:'member', start_time:{$gte:yesterday, $lt:start_of_day}}, (num_chars) ->
        push_info("Yesterday, there were #{num_guilds} guild and #{num_chars} member armory lookups.")




# wf.hourlyjob = create_cron '00 00 0-21/3 * * *', (-> 
#   wf.info "cronjob tick...3 hourly, on the hour load"
#   wf.armory_load_requested = true
#   )

# wf.hourlyjob = create_cron '00 30 1-22/3 * * *', (-> 
#   wf.info "cronjob tick...3 hourly, on the half hour load"
#   wf.armory_load_requested = true
#   )

wf.loadjob = create_cron '*/10 * * * * *', -> 
  wf.debug "cronjob tick...check if armory load requested (running now? #{wf.wow.get_job_running_lock()})"
  if wf.armory_load_requested
    wf.armory_load_requested = false
    wf.info "time for armory_load..."
    wf.wow_loader.armory_load()

wf.loadjob = create_cron '00 47 * * * *', -> 
  wf.info "Reloading realms"
  # wf.wow.realms_loader ->
  wf.wow_loader.static_loader ->
    wf.info "Static load complete"

# wf.staticjob = new cronJob '00 00 00 * * *', (-> 
#   wf.debug "cronjob tick...load armory static"
#   wf.wow.static_load()
#   ),
#   null, 
#   true, #/* Start the job right now */,
#   null #/* Time zone of this job. */

