TODO
- load data from file option/cli
- get latest/current
- calculate diffs between char snapshots - store with latest image
- webpage showing history for char, including details of each snapshot (or first 5...)
- store diffs ready for rss somewhere, one collection of all changes... filterable by char/guild/etc ?
- diff db for tests versus web (-test/-dev)
- rss feed showing level changes for a character

LATER
- count number of api calls per day, page to view them
- store dateSaved on member/guild updates
- update registered entry with date/time of last change (ie when an update had a diff)
- track armory import requests, date/time/requesting ip
- feed for guild
- feed for char/guild achievements
- feed for items?
- feed for profession levels?

NOTES

member or char?
one window to compile
coffee --compile --watch --output js/ src/ spec/

another To run tests (at least on my win7 box)

mocha -t 3000 js/*Spec.js

and another to run express under nodemon, so its restarted when code changes

node_modules/.bin/nodemon js/app.js


ON OSX

start mongo - sudo port load mongodb
run tests - bash ./node_modules/.bin/mocha js/*Spec.js
run app - node node_modules/nodemon/nodemon js/app.js
compile coffee - same as above



LINKS

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
