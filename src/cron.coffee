global.wf ||= {}

_ = require('underscore')
cronJob = require('cron').CronJob
moment = require "moment"

require "./tweet"

wf.armory_load_requested = false

wf.tweeter = new wf.Tweet()

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


# PR stats

push_info = (msg) ->
  now = new Date()
  info = 
    title: "WoW Activity @ #{moment(new Date()).format("H:mm D MMM")}"
    description: msg
    date: now
    guid: now.getTime()
    url: "#{wf.SITE_URL}?ts=#{now.getTime()}"
  wf.info_queue.unshift info
  wf.info_queue = _.first(wf.info_queue,wf.INFO_HISTORY_LIMIT)
  wf.tweeter.update "#{info.title} - #{info.description} #{info.url}"


# count of guilds/members registered
wf.counts1job = create_cron '00 00 3,12,15,21,23 * * *', -> 
# wf.counts1job = create_cron '*/10 * * * * *', -> 
  wf.info "cronjob tick...6 hourly, guild/member counts"
  if wf.wow?
    wf.wow.get_store().count wf.wow.get_registered_collection(), {type:'guild'}, (num_guilds) ->
      wf.wow.get_store().count wf.wow.get_registered_collection(), {type:'member'}, (num_chars) ->
        push_info("Currently tracking #{num_guilds} guilds and #{num_chars} toons.")

# how to use waf
wf.counts3job = create_cron '00 40 2,8,14,22 * * *', -> 
# wf.counts3job = create_cron '*/10 * * * * *', -> 
  wf.info "cronjob tick...6 hourly, how to"
  push_info("How to use guild/character RSS feed - https://wafbeta.uservoice.com/.")



# count of calls yesterday
wf.counts2job = create_cron '00 25 02 * * *', -> 
# wf.counts2job = create_cron '*/10 * * * * *', -> 
  wf.info "cronjob tick...daily guild/member calls"
  if wf.wow?
    start_of_day = moment().startOf('day').valueOf()
    yesterday = moment().startOf('day').subtract(days:1).valueOf()
    wf.wow.get_store().count wf.wow.get_calls_collection(), {type:'guild', start_time:{$gte:yesterday, $lt:start_of_day}}, (num_guilds) ->
      wf.wow.get_store().count wf.wow.get_calls_collection(), {type:'member', start_time:{$gte:yesterday, $lt:start_of_day}}, (num_chars) ->
        push_info("Yesterday, we did #{num_guilds} guild and #{num_chars} toon lookups at the armory.")






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

