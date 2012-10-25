TODO

- do all in memory?  only persist registered/latest item from armory? limit history to n'entries...

- home page - show all (?) registered and last 20 (?) changes across all. page background of faded (random) warcraft poster
-- and number of armory calls made



- twitter feed to facebook - just showing a link... twitterfeed config or use another way in?
- fb to twitter, ok? using Twitter -> fb link working better, get text, no images (and twitterfeed to twitter)

- track feed/view usage, for last few days
-- use this to purge unused data

- save log messages to db in capped collection
- fix tests, wowSpec failing too much, refactor wow.coffee
- cache latest info in memory


BUGS
-

maybe....
- kimptopanda showing achievements that they dont have...revealed all in winterspring, check in-game


PENDING BEING TESTED
- armory job seems to lockup sometimes... added a timeout, see if it helps...
- rss/guid is rubbish / waiting on google reader/twitterfeed - see if they handle the new id better
-

LATER
- perhaps provide facebook/twitter integration/authentication so we get full control of posts... 
- numbers for last hour
- number of actual/real results (is it calls less errors and non-mod?)
- time of most real update
- mongo db version
- save count of calls per load, with date saved

- on guild web page, sort members by descending rank?
- show guild name, if there is one on title/descript of feed
- performance, load/feed/all pages seem slow  - indexes? docs large, only select specific fields?
- option to run for one guild only, no ability to register more people, load guilds/members from config file
- mention trademarks, all are blizzards
- caching? only rebuild feed once a min or so...
- licence for code?
- redirect load/data pages to other pages - stats/registered
- search? could try all realms... or at least select region/realm and enter name - can confirm/select char...
- thanks page - for all tools used :)
- pet battle related feed, levels, achievements
- show item image in feed (need item info, cache in memory?)
- show guild name on char feed entries, if in a guild
- options include/exclude guildies on guild feed
- limit history shown on webpage...
- update registered entry with time of last good update, last update and error, if error, count of updates
- if criteria name matches description, only show 1. eg 100 mounts for 100 mounts...
- ability to have a single feed for several chars (non guilded, eg all my toons)
- get item names, is there an API call or just build list from all the gear on chars... or just link to wowhead (http://blizzard.github.com/api-wow-docs/#item-api)
- make 30 limit on history a param
- display category (eg Kalimdor)/ group names (eg Exploration) in achievement descriptions
- do a guild achievements map - maybe
- whats in the changes for achievements map - useful or just use feeds/news?
- run app at tagadab, also try heroku - any more stable...?
- put savedTime onto db 
- normalise names, eg query this 
--- http://localhost:3000/view/member/us/kaelthas/Fe%C3%A5therz
-- and get this
--- http://localhost:3000/view/member/us/Kael'thas/Fe%C3%A5therz
- when registering differentiate first register with registered but not loaded
- switch to mongolab/hq db on appfog
- page to enter region/realm/type/name and get feed page... maybe...
- chrome extension to give feed url for a specific battle net page, when on it
- limits... how to restrict use?? needed?
- make localisable, ie public lang strings in sep file(s)
- stats post armory load, number loaded, number changed, number not changed, number with errors??
- use momentjs or similar to show age of update, eg 10 days ago, maybe actual time...
- rss, send correct content-type
- highlight members with updates, maybe list of most recent updates on front page
- when you click on view from loaded, it registers item... dont
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
