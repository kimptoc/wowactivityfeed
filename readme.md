# WoW Activity Feed

## TODO

- feed validation failing due to space in url, need to correctly encode them
- http://feedvalidator.org/check.cgi?url=http%3A%2F%2Fwafbeta.kimptoc.net%2Ffeed%2Fguild%2Feu%2FDarkspear%2FMean%2520Girls.rss

- mention copyright/trademarks, all are blizzards


- do a "live" load of the char ?

- search/find my char/guild?
- search? could try all realms... or at least select region/realm and enter name - can confirm/select char...

- just a space between parts of the manual feed changes, maybe use comma/full stop - re-work that class with more generc functions


- twitter feed to facebook - just showing a link... twitterfeed config or use another way in?
- fb to twitter, not working? using Twitter -> fb link working better, get text, no images (will twitter stop that...) (and twitterfeed to twitter)
- or could be RSS related, does Atom/rel-alt links help?

- fix tests, wowSpec failing too much, refactor wow.coffee

## BUGS
maybe....
- kimptopanda showing achievements that they dont have...revealed all in winterspring, check in-game
- double check feed updates vs battle.net - showing correct item?

## FIXED MAYBE PENDING BEING TESTED
- performance? seems ok after restart, removed collection caching... - GC issue or VM issue?
- do all in memory?  only persist registered/latest item from armory? limit history to n'entries...
- armory job seems to lockup sometimes... added a timeout, see if it helps...
- rss/guid is rubbish / waiting on google reader/twitterfeed - see if they handle the new id better
- titles changes?
- some criteria cases come up blank?

## LATER
- feed complains about uri/iri issues when validating - unicode in url
- feed/more url/alt links
- on stats page/uptime output? http://nodejs.org/api/all.html#all_child_process_exec_command_options_callback
- put in image links for changed items on my custom feed bit (get items, display them - multiple...)
- feed items refer to latest char info, eg level, even though at time of feed item, it might have been different - could we link feed item to relevant/best char info we have? Or just give up on historic info option... or just leave
- Kwiks for home page update slideshow? http://devsmash.com/projects/kwicks/examples/slideshow
- stats - show min/max accessed/archived dates and count nulls - number of error today (ideally through agg framework)
- feed/track hunter pets, no levels, is it worth tracking names/type?
- feed/track talents/glyphs changes
- feed/track pvp/battleground changes, number won/lost?
- feed/track progression/raids changes?
- BUG view not found item gives err (if hist present, but no armory)
- not deleting old history... maybe strip code, rely on TTL stuff
- getting times in the future, esp. from US updates... timezone? maybe times are UTC?
- track calls to website - where are they coming from (ip, referring site, browser, ...)
- BUG make home/loaded pages work when no history present - maybe???
- cache class/race static for display (eg mage/orc ...)
- hiding player achievements!
- about page, http://www.sitepoint.com/css3-starwars-scrolling-text/?utm_source=hackernewsletter&utm_medium=email ...
- guild feed has char achievements, so show or ignore... probably will get dupes...
- on guild feed, rely on member feed for their updates
- on member feed, only show guild changes, if not being used on the guild feed...
- install notes/make this a markdown doc
- armory_history - make disappear after a time, TTL, 1 month?
- make a fb page to promote this site, eg http://www.staynalive.com/2012/02/how-to-replace-your-rss-feed.html / http://ogp.me/
- review masonry/isotope usage - is it best option?
- save log messages to db in capped collection
- cache latest info in memory
- home page ,page background of faded (random) warcraft poster
-- whats site for, rss
-- and number of armory calls made today, last modified, load running
- Ttl on history Coll - 1 week?
- home page/last viewed? popular?
- home page/use lib to pack in update boxes
- use alternate rss lib that provides other link types...
- stats/numbers for last hour
- stats/oldest/newest registered updated date
- stats/number of actual/real results (is it calls less errors and non-mod?)
- stats/time of most real update
- stats/mongo db version
- stats/save count of calls per load, with date saved
- on guild web page, sort members by descending rank?
- show guild name, if there is one on title/descript of feed
- performance, load/feed/all pages seem slow  - indexes? docs large, only select specific fields?
- option to run for one guild only, no ability to register more people, load guilds/members from config file
- caching? only rebuild feed once a min or so...
- licence for code?
- redirect load/data pages to other pages - stats/registered
- thanks page - for all tools used :)
- pet battle related feed, levels, achievements
- show guild name on char feed entries, if in a guild
- options include/exclude guildies on guild feed
- update registered entry with time of last good update, last update and error, if error, count of updates
- get item names, is there an API call or just build list from all the gear on chars... or just link to wowhead (http://blizzard.github.com/api-wow-docs/#item-api)
- make 30 limit on history a param
- display category (eg Kalimdor)/ group names (eg Exploration) in achievement descriptions
- chrome extension to give feed url for a specific battle net page, when on it
- limits... how to restrict use?? needed?
- make localisable, ie public lang strings in sep file(s)
- rss, send correct content-type??
- highlight members with updates, maybe list of most recent updates on front page
- should(not)exist dont give stack trace... alternative test?
- put armory link in info - for errors and good entries
- track realm status changes: eg
  "http://us.battle.net/api/wow/realm/status?realms=Medivh,Blackrock"
- count number of api calls per day, page to view them
- store dateSaved on member/guild updates
- update registered entry with date/time of last change (ie when an update had a diff)
- track armory import requests, date/time/requesting ip
- feed for guild
- feed for char/guild achievements
- feed for items?
- feed for profession levels?

## NOTES

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
coffee --compile --watch --output js/ src/ spec/

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
