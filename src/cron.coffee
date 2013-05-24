global.wf ||= {}

_ = require('underscore')
cronJob = require('cron').CronJob
moment = require "moment"
request = require 'request'
parseString = require('xml2js').parseString;

require "./tweet"

wf.armory_load_requested = false

wf.tweeter = new wf.Tweet()

create_cron = (cron_schedule, cron_task) ->
  try 
    new cronJob cron_schedule, cron_task,
      null, 
      true, #/* Start the job right now */,
      null #/* Time zone of this job. */
  catch e
    wf.error e


#create_cron '00 00,30 * * * *', ->
create_cron '00 00 * * * *', ->
  wf.info "cronjob tick... twice an hour armory char/guild update checks"
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
create_cron '00 00 3,12,15,21,23 * * *', ->
  wf.info "cronjob tick...6 hourly, guild/member counts"
  if wf.wow?
    wf.wow.get_store().count wf.wow.get_registered_collection(), {type:'guild'}, (num_guilds) ->
      wf.wow.get_store().count wf.wow.get_registered_collection(), {type:'member'}, (num_chars) ->
        if num_chars? and num_chars > 0 and num_guilds? and num_guilds > 0
          push_info("Currently tracking #{num_guilds} guilds and #{num_chars} toons.")
        else
          push_info("Uh-oh - something has gone horribly wrong... there may be trouble ahead - call @kimptoc urgently!")


# how to use waf
create_cron '00 40 2,8,14,22 * * *', ->
  wf.info "cronjob tick...6 hourly, how to"
  push_info("How to use guild/character RSS feed - https://wafbeta.uservoice.com/.")

# waf language conversion
create_cron '00 15 4,9,13,21 * * *', ->
  wf.info "cronjob tick...6 hourly, locales"
  push_info "Help convert WoW Activity to your language - http://bit.ly/waflang // @webtranslateit"


# how to use waf
create_cron '00 35 00 * * *', ->
# wf.counts4job = create_cron '00 10 17 * * *', -> 
  wf.info "cronjob tick...daily build status"
  request 'https://api.travis-ci.org/repos/kimptoc/wowactivityfeed.xml', (err1,resp1,body) ->
    parseString body, (err2,resp2) ->
      build_status = resp2.Projects.Project[0]["$"]
      push_info("TravisCI Status:#{build_status.lastBuildStatus}, build:#{build_status.lastBuildLabel} at #{build_status.lastBuildTime.substring(0,19)}")


  # r({'uri':}, function(e, r, b) { x(b, function(e,r){ console.log(JSON.stringify(r.Projects.Project[0]["$"])); })  })



# count of calls yesterday
create_cron '00 25 02 * * *', ->
  wf.info "cronjob tick...daily guild/member calls"
  if wf.wow?
    start_of_day = moment().startOf('day').valueOf()
    yesterday = moment().startOf('day').subtract(days:1).valueOf()
    wf.wow.get_store().count wf.wow.get_calls_collection(), {type:'guild', start_time:{$gte:yesterday, $lt:start_of_day}}, (num_guilds) ->
      wf.wow.get_store().count wf.wow.get_calls_collection(), {type:'member', start_time:{$gte:yesterday, $lt:start_of_day}}, (num_chars) ->
        if num_chars? and num_chars > 0 and num_guilds? and num_guilds > 0
          push_info("Yesterday, we did #{num_guilds} guild and #{num_chars} toon lookups at the armory.")
        else
          push_info("Uh-oh - something has gone horribly wrong... there may be trouble ahead - call @kimptoc urgently!")





create_cron '*/4 * * * * *', ->
  wf.debug "cronjob tick...check if armory load requested (running now? #{wf.wow.get_job_running_lock()})"
  if wf.armory_load_requested
    wf.armory_load_requested = false
    wf.info "time for armory_load..."
    wf.wow_loader.armory_load()

create_cron '00 47 * * * *', ->
  wf.info "Reloading realms"
  wf.wow_loader.static_loader ->
    wf.info "Static load complete"

# wf.staticjob = new cronJob '00 00 00 * * *', (-> 
#   wf.debug "cronjob tick...load armory static"
#   wf.wow.static_load()
#   ),
#   null, 
#   true, #/* Start the job right now */,
#   null #/* Time zone of this job. */

