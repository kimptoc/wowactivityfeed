TODO
- rss feed showing level changes for a character
- ensure uniqueness of registered entries
- store char/guild histories - snapshot with datetime

LATER
- feed for guild
- feed for char/guild achievements
- feed for items?
- feed for profession levels?

NOTES

one window to compile
coffee --compile --watch --output js/ src/ spec/

another To run tests (at least on my win7 box)

node node_modules/jasmine-node/bin/jasmine-node --verbose  --forceexit js/

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