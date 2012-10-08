TODO
- calculate diffs between char snapshots - store with latest image
- store diffs ready for rss somewhere, one collection of all changes... filterable by char/guild/etc ?
- rss feed showing level changes for a character

- webpage showing history for char, including details of each snapshot (or first 5...)

- switch to mongolab db on appfog

- in armory load, union registered/loaded items and query armory for them
- or just drive from registered... what about guild members, register them? or do extra loads?

- uploads via node-cron
  https://github.com/ncb000gt/node-cron/

- load data from file option/cli ??

LATER
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

node_modules/.bin/nodemon js/app.js


ON OSX

start mongo - sudo port load mongodb
and maybe sudo rm /opt/local/var/db/mongodb/mongod.lock
run tests - bash ./node_modules/.bin/mocha js/*Spec.js
run app - node node_modules/nodemon/nodemon js/app.js
compile coffee - same as above



LINKS

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
