global.wf ||= {}

startup_time = new Date().getTime()

moment = require "moment"

require './init_logger'

# this an in memory cache of the latest guild/char details
class wf.WoWStats

  armory_calls: (wow, callback)->
    info = 
      startup_time: moment(startup_time).format('H:mm:ss ddd')
      memory_usage: process.memoryUsage()
      node_uptime: process.uptime()
      armory_load:
        armory_load_running: wow.get_job_running_lock()
        number_running: wow.get_loader_queue()?.running() 
        number_queued: wow.get_loader_queue()?.length()
      item_loader_queue:
        number_running: wow.get_item_loader_queue()?.running()
        number_queued: wow.get_item_loader_queue()?.length()
    wow.get_store().dbstats wow.get_collections(), (stats) ->
      info.db = stats      
      start_of_day = moment().startOf('day').valueOf()
      yesterday = moment().startOf('day').subtract(days:1).valueOf()
      twohours_ago = moment().subtract(hours:2).valueOf()
      wow.get_store().aggregate wow.get_calls_collection(), 
        [
          { $project: 
            type: 1
            start_time: 1
            error: 1
            errors:{$cmp: ["$had_error", false]}
            not_modifieds:{$cmp: ["$not_modified", false]}
            date_category:{$cond:[$gte:["$start_time", twohours_ago],"last-2hours", $cond:[$gte:["$start_time", start_of_day],"today",$cond:[$gte:["$start_time", yesterday],"yesterday", "before-yesterday"]]]}
          },
          { $group : 
            # _id: "$type"
            # _id:{ error:"$error", type:"$type"}
            _id:{ date_category:"$date_category", type:"$type", error:"$error"}
            totalByType:{ $sum:1 }
            earliest: {$min: "$start_time"}
            latest: {$max: "$start_time"}
            errors: {$sum: "$errors"} 
            not_modified: {$sum :"$not_modifieds"}
          }
        ], 
        {}, 
        (results) ->
          if results?
            results2 = {}
            for type_stat in results
              type_stat.earliest = moment(type_stat.earliest).format("H:mm:ss ddd")
              type_stat.latest = moment(type_stat.latest).format("H:mm:ss ddd")
              results2[type_stat._id.date_category] ?= {}
              if type_stat._id.error?
                key = type_stat._id.type + "/" + type_stat._id.error + "-" + type_stat.earliest + " - " + type_stat.latest
                total = type_stat.errors
                results2[type_stat._id.date_category][key] = total
              else
                key = type_stat._id.type + "-" + type_stat.earliest + " - " + type_stat.latest
                total = type_stat.totalByType
                results2[type_stat._id.date_category][key] = total
                key = type_stat._id.type + "/" + "not-modified" + "-" + type_stat.earliest + " - " + type_stat.latest
                total = type_stat.not_modified
                results2[type_stat._id.date_category][key] = total
            # info.aggregate = results
            info.aggregate_calls = results2
          callback?(info)

