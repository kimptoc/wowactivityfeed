TODO
- reduce logging on prod ( ie info and above) - see whats wrong...

- uploads via node-cron
  https://github.com/ncb000gt/node-cron/

- only one callback from armory load - when all received and saved... - re-run tests
- diff handling of changes for members, achievements and other array based things
- some members not being found, but listed in history...

- switch to mongolab db on appfog
- log to console on prod, as that seems only thing available...


LATER
- use momentjs or similar to show age of update, eg 10 days ago, maybe actual time...
- rss, send correct content-type
- highlight members with updates, maybe list of most recent updates on front page
- when you click on view from loaded, it registers item... dont
- should(not)exist dont give stack trace... alternative test?
- if not found, put on a lastModified, so that its not re-done
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
