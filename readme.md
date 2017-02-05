# WoW Activity Feed

[![Build Status via Travis CI](https://travis-ci.org/kimptoc/wowactivityfeed.png?branch=master)](https://travis-ci.org/kimptoc/wowactivityfeed)

LIVE SITE: http://wowactivity.kimptoc.net/

If you want the site/feed filler text in your language (not English) - you can help here: https://webtranslateit.com/en/projects/6337-Wow-activity-/project_locales

WoW Activity Chrome Extension - https://chrome.google.com/webstore/detail/wow-activity-lookup/njapjedhnpfpbfdeaaigolgoeeichfaj?hl=en


Update things
- node, currently 0.10.37, aim for 6.9.5 - LIVE
- coffeescript was 1.6.2 aim for 1.12.3 - LIVE
- forever 0.10.8 -> 0.15.3 - LIVE
- modules
-- log4js 0.6.21 ->  1.1.0  - LIVE
-- jade -> pug
-- underscore 1.7.0 ->  1.8.3
-- request 2.48.0 -> 2.79.0 - LIVE
-- twit 1.1.18 ->  2.2.5 - LIVE
-- moment 2.1.0 -> 2.17.1 - LIVE
-- nodetime - ??
-- express - 4.10.4 -> 4.14.1 (done manually due to shrinkwrap issue)//LIVE
-- express-csv - ok
-- jsondiffpatch 0.1.20 -> 0.2.4 - LIVE
-- async 0.9.0 -> 2.1.4 - LIVE
-- nodemon 1.2.1 - broken, needs new node? reinstall seemed to fix it. updated to 1.11.0 ok.
- mongodb and its lib, 2.4.14


seems to be crashing more now... locally too - which is useful!

npm WARN deprecated nodetime@0.8.17: Nodetime shut down on August 31, 2015. See AppDynamics Node.js Agent http://appdynamics.com/nodejs
npm WARN deprecated jade@1.11.0: Jade has been renamed to pug, please install the latest version of pug instead of jade


node-gyp fails to install on server, also on osx/laptop - part of coffee-script

sprinkle/node install - probably wrong version now, should be 6.9.5

npm shrinkwrap fails - https://github.com/npm/npm/issues/11493

don't use shrinkwrap as it doesnt work - use explicit versions in package.json


Docker-ise!
- docker-compose up mongolab code web
- logs held on host system.
- install sysstat and
  replace_text 'ENABLED="false"', 'ENABLED="true"', '/etc/default/sysstat'
- apache front end to app, like on prod
- try on docker VM
- twitter working? YUP
- how to ensure tidy images/containers --rm?
- test1/mongo- DONE, can connect/data persists
- test2/node, with npm - DONE
- PROD, mongo (continue from prev session), node, source, npm packages, run app
- DEV/cli-dev - DONE
- DEV/unit tests, mongo (empty/ok, diff db), node, npm packages, coffee compile, mocha run tests/watch code (mount source for quick re-run)  run tests
- DEV/run app: mongo (continue from prev session), node, npm  packages, (mount source for quick re-run)  run app

TODO
- run it locally, env settings issue? El Capitan issue?
- log when it cycles through all chars - perhaps use dummy char marker to identify this

- make it work with docker for ease of re-deployment, assuming can docker enable virtual linux hosts - http://www.kontena.io/
or DEIS - http://deis.io/get-deis/?utm_source=javascriptweekly&utm_medium=email

- getting times in the future, esp. from US updates... timezone? maybe times are UTC, esp in summer time?

MongoDB
To have launchd start mongodb at login:
  ln -sfv /usr/local/opt/mongodb/*.plist ~/Library/LaunchAgents
Then to load mongodb now:
  launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist
Or, if you don't want/need launchctl, you can just run:
  mongod --config /usr/local/etc/mongod.conf

Using old mongo/node
MongoDB shell version: 2.4.12
$ node -v / v0.10.40

Using NGINX...
https://www.nginx.com/blog/5-performance-tips-for-node-js-applications/?utm_source=nodeweekly&utm_medium=email

deploy via passenger - https://www.digitalocean.com/community/tutorials/how-to-deploy-a-rails-app-with-passenger-and-apache-on-ubuntu-14-04
set env vars via mod_env http://httpd.apache.org/docs/2.4/mod/mod_env.html
require all granted error - http://stackoverflow.com/questions/21265191/apache-authtype-not-set-500-error

Machine learning
- suggest kit to get, based off what other toons are getting (of similar level/type/focus)
- spot anomalies
- activity over time, busy/quiet periods, whats hot this week


## TODO

jsondiff giving intermittent erros, not sure what its affecting - ERROR: jsdiff.unpatch:Error: reverse failed -

enable gzip on requests to armory/battle.net - not working - maybe now - http://us.battle.net/en/forum/topic/15538504599

do cross realm guilds work, ie does it get realm from member list or assume same as guild
are we handling multi-realm guilds?


realm reloading
- review changes made - any o/s issues?
- cater for removed realms
- currently deletes all and then loads whats good
- maybe do it per region, load region, if seems ok, delete existing and save

continuous char loads
- does search/new member/guild work ok?
- intermittent crashes? did a fix, but could be due to no data returned, leading to requeue failing. Maybe go back to db to do requeues
eg on drain, although only started when went to having 2 threads...
- how to handle not found chars, drop from queue until next restart (but then most probably due to guild membership) - have a 'failed' list
- how does current server trigger restart?  via log rotation
- seems to be crashing intra day - but at least restarting ok
- indicate how long a pass through is taking, perhaps on stats page, but how - dummy entry?

update related npm packages to latest

review/reduce tweets produced

use new API endpoints!!!
- for in page links - not possible, as need apikey - do it on server and display on page
- for lookups

- not compressing responses, handled via apache??
- no chinese/sea region
- australian realms - anything to do to support them?  http://wow.joystiq.com/2014/10/23/blizzard-announces-locally-hosted-australian-realms/


Analytics - http://www.javaworld.com/article/2858307/data-storage/mongodb-gets-its-first-native-analytics-tool.html#tk.rss_javaappdev


## SPLIT INTO SEP SERVICES
- eg using sourced https://github.com/mateodelnorte/sourced for event sourcing
using Meteor oplog view on mongo
Servicebus/eg via rabbitmq

see https://github.com/electronifie for tips


## NEW BATTLE NET API ISSUES
- last modified does not work - API issue

DONE - reforked armory
remove use of forked armory, reasons for it:
- gzip support, now in request
- new item context (probably need to refork)
- use https
- new api (refork)
- pass options onwards to request (gzip, proxy...)
- better handle json parse errors (eg when using proxy)
- handle auth properly
- header date?
- encodeURI of path




dupe errors
ogs/server.log.1:[2014-06-12 17:09:57.913] [ERROR] [default] - { [MongoError: insertDocument :: caused by :: 11000 E11000 duplicate key error index: wowfeed.armory_history.$name_1_realm_1_region_1_type_1_lastModified_1_locale_1  dup key: { : "taured", : "les sentinelles", : "eu", : "member", : null, : "fr_FR" }]


Show times on website in user timezone, not always GMT

Review error logging -

Problem with unicode and app signature, maybe...

This is direct:
http://us.battle.net/api/wow/character/goldrinn/c%C3%AAix

This is the runscope version:
https://www.runscope.com/public/6e1ab5f0-19d5-4e9a-aedd-e4e83c020985/32d191d0-9cea-41df-a2bb-623ffd2928f0

I get a nicely formatted json error:

  "reason": "Invalid application signature."


feed item formatting - use templates/keyed on certain fields, code then becomes a loop over the templates.


Use https://github.com/pazguille/shuffle-array/issues/2 for picking home page selection (and sort them)

Promote Google group - https://groups.google.com/forum/?fromgroups#!forum/wow-activity-feed
- link on site & on twitter

Performance... multiple API scraper servers?
Very Busy when doing armory calls
Perhaps run several processes on same box, eg per region, at different times (so node for webapp, node for scrape and mongo)

oops - taking non-standard locales:
 locales/favicon.ico.json
 locales/robots.txt.json
Need to better handle '/' path
-- http://expressjs.com/api.html#app.VERB


slugify realm names (as blizz does...) eg Ревущий фьорд should become ревущии-фьорд - would then need to normalised registered names again...

maybe guild/char names too

Try https://github.com/pid/speakingurl




blizzard - more capacity or run sep sites?



- hide most of large guilds, with a more link to see them (just hidden on page)
- link on individual guild/member page to see all history


- would be good to make item lookup wait for armory fetch of info... but hopefully not common... as should be loaded via char fetch process
- link realms so can switch to appropriate locale name, eg via realm id

- getting items not found - maybe looking for something which is not an item...


- link from guild page/ member to their own page

- when a search fails, provide link to armory using given details, to help find char


- language in RSS - needed? remove or maybe use locale?

https://github.com/mashpie/i18n-node


Code coverage
- configure istanbul - https://github.com/gotwarlost/istanbul

Put in replica set connections...
- liquid1 keeps crashing due to index issues, raised with ISP
- mongodump crashes/raised on google group :(
- OpenVZ?
- when node steps down, app not handling it - thought it did locally, but not using replset due to above issues...



Maybe... Tune wow api calls, only check for updates if they have had a recent update...
Eg if no changes for days, then only check daily.
Or check all first pass of the day.
Second+ passes, only check those that had a change today...


Better tests!

async 0.2 - what to do to make it work...
- https://github.com/caolan/async/issues/276

Getting errors in logs, eg about LEAF signature?

Search issue - guild La XXVe Armée, eu realm Chants éternels - currently not finding it...

Auto reconnect to mongo?

Perhaps have a url returning num registered (0 and if db problem) - for ease of checking site health...
 - trigger restart if 0 on that url (hourly check)

Use standard char /. Guild? - Nameplates...  Is there a free service doing this still?

ERROR

[2013-03-13 21:19:44.640] [ERROR] [default] - [Error: no open connections]
Error: no open connections
    at Db._executeInsertCommand (/home/kimptoc/public_html/wowactivityfeed/node_modules/mongodb/lib/mongodb/db.js:1789:27)
    at insertAll (/home/kimptoc/public_html/wowactivityfeed/node_modules/mongodb/lib/mongodb/collection.js:320:13)
    at Collection.insert (/home/kimptoc/public_html/wowactivityfeed/node_modules/mongodb/lib/mongodb/collection.js:92:3)
    at wf.StoreMongo.StoreMongo.insert (/home/kimptoc/public_html/wowactivityfeed/js/store_mongo.js:92:21)
    at wf.StoreMongo.StoreMongo.with_collection (/home/kimptoc/public_html/wowactivityfeed/js/store_mongo.js:317:51)
    at Db.collection (/home/kimptoc/public_html/wowactivityfeed/node_modules/mongodb/lib/mongodb/db.js:478:44)
    at wf.StoreMongo.StoreMongo.with_collection (/home/kimptoc/public_html/wowactivityfeed/js/store_mongo.js:312:28)
    at StoreMongo.wf.StoreMongo.StoreMongo.with_connection (/home/kimptoc/public_html/wowactivityfeed/js/store_mongo.js:327:16)
    at StoreMongo.wf.StoreMongo.StoreMongo.with_collection (/home/kimptoc/public_html/wowactivityfeed/js/store_mongo.js:311:19)
    at StoreMongo.wf.StoreMongo.StoreMongo.insert (/home/kimptoc/public_html/wowactivityfeed/js/store_mongo.js:91:19)

[2013-03-13 21:19:43.628] [ERROR] [default] - [Error: connection closed]
Error: connection closed
    at Server.connect.connectionPool.on.server._serverState (/home/kimptoc/public_html/wowactivityfeed/node_modules/mongodb/lib/mongodb/connection/server.js:611:45)
    at EventEmitter.emit (events.js:126:20)
    at connection.on._self._poolState (/home/kimptoc/public_html/wowactivityfeed/node_modules/mongodb/lib/mongodb/connection/connection_pool.js:139:15)
    at EventEmitter.emit (events.js:99:17)
    at Socket.closeHandler (/home/kimptoc/public_html/wowactivityfeed/node_modules/mongodb/lib/mongodb/connection/connection.js:481:12)
    at Socket.EventEmitter.emit (events.js:96:17)
    at Socket._destroy.destroyed (net.js:358:10)
    at process.startup.processNextTick.process._tickCallback (node.js:244:9)


Intermittent error: - might be related to async 0.2 issue
/Users/kimptoc/Dropbox/dev/wowfeed.osx/node_modules/mongodb/lib/mongodb/connection/server.js:529
        throw err;
              ^
Error: Callback was already called.
    at /Users/kimptoc/Dropbox/dev/wowfeed.osx/node_modules/async/lib/async.js:22:31
    at WoWLoader.wf.WoWLoader.WoWLoader.ensure_registered_correct (/Users/kimptoc/Dropbox/dev/wowfeed.osx/js/wow_loader.js:95:49)
    at WoWLoader.ensure_registered_correct (/Users/kimptoc/Dropbox/dev/wowfeed.osx/js/wow_loader.js:54:62)
    at /Users/kimptoc/Dropbox/dev/wowfeed.osx/js/wow_loader.js:370:28
    at WoWLoader.wf.WoWLoader.WoWLoader.store_update (/Users/kimptoc/Dropbox/dev/wowfeed.osx/js/wow_loader.js:203:11)
    at WoWLoader.store_update (/Users/kimptoc/Dropbox/dev/wowfeed.osx/js/wow_loader.js:51:49)
    at /Users/kimptoc/Dropbox/dev/wowfeed.osx/js/wow_loader.js:369:26
    at /Users/kimptoc/Dropbox/dev/wowfeed.osx/js/call_logger.js:33:55
    at /Users/kimptoc/Dropbox/dev/wowfeed.osx/js/store_mongo.js:97:59
    at null.<anonymous> (/Users/kimptoc/Dropbox/dev/wowfeed.osx/node_modules/mongodb/lib/mongodb/collection.js:337:9)



setup new box:
- configure driver to connect to replicaset, so that change of primary is handling automatically or just make others hidden!
- print node/mongo version on debug page
- check for 0 registered - alert if so


https://github.com/mongodb/node-mongodb-native/blob/master/docs/replicaset.md
http://docs.mongodb.org/manual/tutorial/force-member-to-be-primary/


info feed
= num members/guilds being checked (6 hourly)
= number guild/member calls per day (daily)
= link to how to use (every 6 hourly)
- biggest guild (+number of members, by region)
- highest rep char (by region)
- highest level guild (by region)
- most popular realm by chars, by guilds, by region
- PR/lure people in - click here to find your toon...

- D4D designs sketch/wireframe
http://www.fonts2u.com/caribbean-regular.font

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
- if new character, use date of oldest feed item - so the magic bit is way back in feed! works for one char, but guild needs to look at all members... not possible now
--Backups!
--Review logging – make “not found” info...
---Feed messages??
--Realms etc – less frequent/more robust!
- faq - how to use rss, with twitter, with fb, with google reader (etc), with guildlaunch.com
- Lose copyright bit
- Only do classes daily, ERROR: Problem finding classes for region:eu error:Daily limit exceeded : {}
- handle quotes in item names - http://wafbeta.kimptoc.net//view/member/eu/Stormrage/Slynm?ts=1355350538000&id=18203
- Disable search btn while search is ongoing
- put generic char link on search, not the timespace specific link
- if get "not found" for character/guild, dont add to registered collection
- allow search by name only (no realm/region) - but only look at what we have cached?  Any use?
- Handle timeout on search/json call...
- when get errors on realms/classes/races, could leave data invalid- be more careful
- ERROR: Problem finding realms for region:tw error:ETIMEDOUT : {"code":"ETIMEDOUT"} -
- ERROR: Problem finding classes for region:eu error:ETIMEDOUT : {"code":"ETIMEDOUT"} -
- ERROR: Problem finding races for region:eu error:ETIMEDOUT : {"code":"ETIMEDOUT"} -

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

download 2.* version of mongo
under projecr dir, ensure these dirs exist
var/lib/mongodb
var/log/mongodb

then run mongo like this - assuming 2.6.12 in downloads dir
~/Downloads/mongodb-osx-x86_64-2.6.12/bin/mongod --config etc/mongodb-dev.conf

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

http://blizzard.github.io/api-wow-docs/
