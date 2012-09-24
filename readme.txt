NOTES

one window to compile
$ coffee --compile --watch --output js/ src/ spec/

another To run tests (at least on my win7 box)

$ node node_modules/jasmine-node/bin/jasmine-node js/

to run express under nodemon, so its restarted when code changes

$ node_modules/.bin/nodemon js/app.js