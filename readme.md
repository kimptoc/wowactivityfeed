# WoW Activity Feed

## TODO

- D4D designs sketch/wireframe
http://www.fonts2u.com/caribbean-regular.font

- make enter key do a search too
- exotic char issues - eg Tänks or Terenas
- format results
- integrate search into home page

example guild/member same name/realm
http://localhost:4000/json/lookup/eu/Wrathbringer/Tony

handle quotes in item names - http://wafbeta.kimptoc.net//view/member/eu/Stormrage/Slynm?ts=1355350538000&id=18203



not handling exotic chars, eg this gives error
http://localhost:4000/view/member/us/Kael%27thas/Fe%E5therz?ts=1357347891000&id=7093

menu?  http://jpanelmenu.com/

## BUGS
maybe....
- kimptopanda showing achievements that they dont have...revealed all in winterspring, check in-game
- double check feed updates vs battle.net - showing correct item?
- existing items showing as new, why? if guild/member being accessed then it should be kept current

## FIXED MAYBE PENDING BEING TESTED
- performance? seems ok after restart, removed collection caching... - GC issue or VM issue?
- do all in memory?  only persist registered/latest item from armory? limit history to n'entries...
- details a char's titles changes?
- some criteria cases come up blank?

## LATER
- search, scrape all comm sites / wowsearch.coffee - did it, but is it legit??? and how to handle hundreds of results?
- show timestamp in msg body
- http://wafbeta.kimptoc.net//view/member/eu/Nemesis/Spinlady?ts=1355917814000
- Crusader Spinlady (Ðeus lo vult) New title(s): ', Master of the Ways'
 
- get duplicate key on item id - could be parallel timing thing
-   err: 'E11000 duplicate key error index: wowfeed.armory_items.$item_id_1  dup key: { : 83801 }',
- consider grunt-reduce for express asset pipeline - http://dailyjs.com/2012/12/10/extender-gridy-reduce/
- put 1 month expiry on items - so they get refreshed, if used, removed if not
- change realms load to do upsert - if one region is down, then we lose all their realms :(
- on guild page, show recent joiners/leavers
- guild logo - is there one? - maybe http://us.battle.net/wow/en/forum/topic/6571627473
- use last-Modified on responses, base of underlying data max last modified
- limiting textsize needed for news feed items too, eg when lots of criteria for an achievement
- if no registed items, armory load hangs - hamdle this case

- for guild level changes, link to wowhead info on new level ??? and rely on official feed items for these


- char/lastModified - feed items have later dates... means what?

- question marks for reps - format change?
http://wafbeta.kimptoc.net//view/member/us/Wildhammer/Harrydotta?ts=1354168144000
vs this
http://wafbeta.kimptoc.net//view/member/us/Wildhammer/Darketernall?ts=1354166678000

- Make feed formatting dynamic... eg like map_message
- char++ tooltips -  https://github.com/darkspotinthecorner/DarkTip
- item colours/api tips - http://us.battle.net/wow/en/forum/topic/6521202864
- show notfound image when char images not found - home page/loaded page
- stats, summarise loaded data - popular items/achievements, average level/rep?
- only use elipsis when tight for space, eg on boxes on webpage
- personalise, use image/char name
- criteria for same date - merge?
- show delta on rep change (eg Cartel: 2100 (+100))
- kimptonar not updating - is there a bug in guild update tracking?
- stats/trends, popular items/achievements etc
- some direct update links failing, eg:
  - http://wafbeta.kimptoc.net/view/member/cn/%u8FBE%u65AF%u96F7%u739B/%u6653%u8428?ts=1352829579000&utm_source=twitterfeed&utm_medium=twitter
- mention copyright/trademarks, all are blizzards
- licence for code?
- not found/404 handling?

- do a "live" load of the char ?

- search/find my char/guild?
- search? could try all realms... or at least select region/realm and enter name - can confirm/select char...

- just a space between parts of the text for manual feed changes, maybe use comma/full stop - re-work that class with more generic functions


- twitter feed to facebook - just showing a link... twitterfeed config or use another way in?
- fb to twitter, not working? using Twitter -> fb link working better, get text, no images (will twitter stop that...) (and twitterfeed to twitter)
- or could be RSS related, does Atom/rel-alt links help?
- options - hootsuite, twitterfeed, twitter -> fb, fb -> twitter
- DIY/ twitter - http://stackoverflow.com/questions/6377844/node-js-twitter-client
- DIY/fb - https://developers.facebook.com/docs/reference/javascript/

- fix tests, wowSpec failing too much, refactor wow.coffee

- need a logo! :)
- feed/add more url/alt rel links, eg images for items/achievements etc
- on stats page/df -h, uptime etc output? http://nodejs.org/api/all.html#all_child_process_exec_command_options_callback
- put in image links for changed items on my custom feed bit (get items, display them - multiple...)
- feed items refer to latest char info, eg level, even though at time of feed item, it might have been different - could we link feed item to relevant/best char info we have? Or just give up on historic info option... or just leave
- Kwiks for home page update slideshow? http://devsmash.com/projects/kwicks/examples/slideshow
- stats - show min/max accessed/archived dates and count nulls - number of error today (ideally through agg framework)
- feed/track hunter pets, no levels, is it worth tracking names/type?
- feed/track talents/glyphs changes
- feed/track pvp/battleground changes, number won/lost?
- feed/track progression/raids changes?
- getting times in the future, esp. from US updates... timezone? maybe times are UTC?
- track calls to website - where are they coming from (ip, referring site, browser, ...)
- cache class/race static for display (eg mage/orc ...)
- about page, http://www.sitepoint.com/css3-starwars-scrolling-text/?utm_source=hackernewsletter&utm_medium=email ...
- install notes/how to setup this site
- make a fb page to promote this site, eg http://www.staynalive.com/2012/02/how-to-replace-your-rss-feed.html / http://ogp.me/
- cache latest info in memory
- home page ,page background of faded (random) warcraft poster
  - whats site for, rss
  - and number of armory calls made today, last modified, load running
- home page/last viewed? popular?
- stats/oldest/newest registered updated date
- stats/number of actual/real results (is it calls less errors and non-mod?)
- stats/mongo db version
- on guild web page, sort members by descending rank?
- show guild name, if there is one on title/descript of feed
- performance, load/feed/all pages seem slow  - indexes? docs large, only select specific fields?
- option to run for one guild only, no ability to register more people, load guilds/members from config file
- caching? only rebuild feed once a min or so...
- redirect load/data pages to other pages - stats/registered
- thanks page - for all tools used :)
- pet battle related feed, levels, achievements
- show guild name on char feed entries, if in a guild
- options include/exclude guildies on guild feed
- make 30 limit on history a param
- display category (eg Kalimdor)/ group names (eg Exploration) in achievement descriptions
- chrome extension to give feed url for a specific battle net page, when on it
- limits... how to restrict use?? needed?
- make localisable, ie public lang strings in sep file(s)
- highlight members with updates, maybe list of most recent updates on front page
- put armory link in info - for errors and good entries
- track realm status changes: eg
  "http://us.battle.net/api/wow/realm/status?realms=Medivh,Blackrock"
- track armory import requests, date/time/requesting ip
- feed for items?
- feed for profession levels?

## NOTES


Nodefly - any use?
http://apm.nodefly.com/#dashboard

- test feed 
  -  http://feedvalidator.org/check.cgi?url=http%3A%2F%2Fwafbeta.kimptoc.net%2Ffeed%2Fguild%2Feu%2FDarkspear%2FMean%2520Girls.rss
  -  http://validator.w3.org/appc/


#### history 
- 1 week TTL for main/latest char entry, done, accessed_at
- 1 day TTL for history items, done, archived_at
- refresh everytime its viewed via get_history, done
- so if not viewed or becomes history, it gets deleted
- if char updates regularly, it will have lot of history...for 1 day


#### AppFog cheatsheet:
    rvm use 1.8.7-p358@af-tool
    rvm use ruby-1.9.2-p320@af-tool
    af update waf1
    af logs waf1
    af crashlogs waf1
    af env-add waf1 NODE_ENV=production

- run on ubuntu for forever via npm forever
   forever start -l logs/forever.log -o logs/out.log -e logs/err.log app.js

- to update npm-shrinkwrap.json, delete it and recreate it
  npm shrinkwrap

- uploads via node-cron
  https://github.com/ncb000gt/node-cron/

diff using jsondiffpatch / https://github.com/benjamine/JsonDiffPatch
eg
jsdiff = require("jsondiffpatch")
a = {}
b = {}
jsdiff.diff(a,b)

- http://www.mongodb.org/display/DOCS/Admin+UIs
- mongo db browser/osx - http://mongohub.todayclose.com/download
- for test guild/members - http://www.guildox.com/go/g.asp

member or char?
one window to compile
coffee --compile --watch --output js/ src/ spec/ src_common
coffee --compile --watch --output public/js-cs src_client src_common

another To run tests (at least on my win7 box)

mocha -t 3000 js/*Spec.js

and another to run express under nodemon, so its restarted when code changes

node_modules/.bin/nodemon app.js


## ON OSX

start mongo - sudo port load mongodb
and maybe sudo rm /opt/local/var/db/mongodb/mongod.lock
run tests - bash ./node_modules/.bin/mocha js/*Spec.js
or node ./node_modules/mocha/bin/mocha 
run app - 
node node_modules/nodemon/nodemon app.js
compile coffee - same as above

dex:
dex -w -f /opt/local/var/log/mongodb/mongodb.log mongodb://localhost

## APACHE BENCH

ab -n 10 -c 3 http://wafbeta.kimptoc.net/feed/guild/eu/Darkspear/Mean%20Girls.rss

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       28   35   5.4     39      44
Processing:   555 1794 1410.6   1063    3848
Waiting:      452 1700 1404.0    994    3743
Total:        599 1829 1412.5   1091    3887

## LINKS

hosting:
- http://www.lowendbox.com/
- 

Unofficial WoW fansite kit - http://us.battle.net/wow/en/forum/topic/7006895011

10gen/MMS - https://mms.10gen.com/

perf tool - http://www.nodetime.com

wowhead tooltips - http://www.wowhead.com/tooltips#related-xml-feeds
date format via moment - http://momentjs.com/docs/

jade - view templates - https://github.com/visionmedia/jade#readme
underscore - http://underscorejs.org/

sinon - mocks for testing - http://sinonjs.org/docs/#mocks
mocha - for testing - http://visionmedia.github.com/mocha/
should - for testing - https://github.com/visionmedia/should.js

html2jade tool - https://github.com/donpark/html2jade

heroku deploy
http://shapeshed.com/creating-a-basic-site-with-node-and-express/

nodejitsu handbook
https://github.com/nodejitsu/handbook
http://cheatsheet.nodejitsu.com/
http://docs.nodejitsu.com/
http://docs.nodejitsu.com/articles/file-system/how-to-store-local-config-data

cloud9/azure
http://www.windowsazure.com/en-us/develop/nodejs/tutorials/deploying-with-cloud9/

appfrog/mongodb
http://docs.appfog.com/frameworks/node
