TODO
- store char/guild histories from armory - snapshot with datetime
- diff db for tests versus web (-test/-dev)
- query back to webpage
- rss feed showing level changes for a character

LATER
- update registered entry with date/time of last change (ie when an update had a diff)
- feed for guild
- feed for char/guild achievements
- feed for items?
- feed for profession levels?

NOTES

member or char?
one window to compile
coffee --compile --watch --output js/ src/ spec/

another To run tests (at least on my win7 box)

mocha js/*Spec.js

and another to run express under nodemon, so its restarted when code changes

node_modules/.bin/nodemon js/app.js




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