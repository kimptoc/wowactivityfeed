# WoW Activity Feed

[![Build Status via Travis CI](https://travis-ci.org/kimptoc/wowactivityfeed.png?branch=master)](https://travis-ci.org/kimptoc/wowactivityfeed)

LIVE SITE: http://wowactivity.kimptoc.net/

If you want the site/feed filler text in your language (not English) - you can help here: https://webtranslateit.com/en/projects/6337-Wow-activity-/project_locales

WoW Activity Chrome Extension - https://chrome.google.com/webstore/detail/wow-activity-lookup/njapjedhnpfpbfdeaaigolgoeeichfaj?hl=en

Parts:
- query wow api, save diff
- queue of items to query, able to push things into front of queue (for new website queries)
- lookup character for website/rss feed
- rss front end
- web front end

see github issues for items to do/enhancements

crashing when run locally/bad data in db?

Still crashing/try node 7.5.0 - any more stable?
- seems to be ... but node v7 not supported on ubuntu 12.04
- need to update server...
- tried more memory, but not helping

try guessing object size to bypass json diff issue or use other diff engines



save json object whens diff fails, see if can reproduce in small test


## TODO


## LATER

## NOTES



- test RSS feed
  -  http://feedvalidator.org/check.cgi?url=http%3A%2F%2Fwafbeta.kimptoc.net%2Ffeed%2Fguild%2Feu%2FDarkspear%2FMean%2520Girls.rss
  -  http://validator.w3.org/appc/


#### history
- 1 week TTL for main/latest char entry, done, accessed_at
- 1 day TTL for history items, done, archived_at
- refresh everytime its viewed via get_history, done
- so if not viewed or becomes history, it gets deleted
- if char updates regularly, it will have lot of history...for 1 day


- run on ubuntu for forever via npm forever
   forever start -l logs/forever.log -o logs/out.log -e logs/err.log app.js


one window to compile
coffee --compile --watch --output js/ src/ spec/ src_common
coffee --compile --watch --output public/js-cs src_client src_common

another To run tests (at least on my win7 box)

mocha -t 3000 js/*Spec.js

and another to run express under nodemon, so its restarted when code changes

node_modules/.bin/nodemon app.js


## ON OSX

download 3.* version of mongo
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
