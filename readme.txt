TODO

- track calls to website - where are they coming from (ip, referring site, browser, ...)
-- is google crawling the site? triggering items to reload... getting googlebot calls - how to ignore (robots file... guess from req params?)

- getting times in the future, esp. from US updates... timezone? maybe times are UTC?

- search/find my char/guild?
- search? could try all realms... or at least select region/realm and enter name - can confirm/select char...

- mention copyright/trademarks, all are blizzards


- twitter feed to facebook - just showing a link... twitterfeed config or use another way in?
- fb to twitter, ok? using Twitter -> fb link working better, get text, no images (and twitterfeed to twitter)

- fix tests, wowSpec failing too much, refactor wow.coffee


BUGS
-

maybe....
- kimptopanda showing achievements that they dont have...revealed all in winterspring, check in-game


PENDING BEING TESTED
- do all in memory?  only persist registered/latest item from armory? limit history to n'entries...
- armory job seems to lockup sometimes... added a timeout, see if it helps...
- rss/guid is rubbish / waiting on google reader/twitterfeed - see if they handle the new id better
-

LATER
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
- numbers for last hour
- number of actual/real results (is it calls less errors and non-mod?)
- time of most real update
- mongo db version
- save count of calls per load, with date saved

- on guild web page, sort members by descending rank?
- show guild name, if there is one on title/descript of feed
- performance, load/feed/all pages seem slow  - indexes? docs large, only select specific fields?
- option to run for one guild only, no ability to register more people, load guilds/members from config file
- caching? only rebuild feed once a min or so...
- licence for code?
- redirect load/data pages to other pages - stats/registered
- thanks page - for all tools used :)
- pet battle related feed, levels, achievements
- show item image in feed (need item info, cache in memory?)
- show guild name on char feed entries, if in a guild
- options include/exclude guildies on guild feed
- update registered entry with time of last good update, last update and error, if error, count of updates
- if criteria name matches description, only show 1. eg 100 mounts for 100 mounts...
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

NOTES

AppFog notes:
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


ON OSX

start mongo - sudo port load mongodb
and maybe sudo rm /opt/local/var/db/mongodb/mongod.lock
run tests - bash ./node_modules/.bin/mocha js/*Spec.js
or node ./node_modules/mocha/bin/mocha 
run app - 
node node_modules/nodemon/nodemon app.js
compile coffee - same as above

dex:
dex -w -f /opt/local/var/log/mongodb/mongodb.log mongodb://localhost

LINKS

perf tool - http://www.nodetime.com

wowhead tooltips - http://www.wowhead.com/tooltips#related-xml-feeds
date format via moment - http://momentjs.com/docs/

jade - view templates - https://github.com/visionmedia/jade#readme

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
