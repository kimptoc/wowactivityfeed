#!/bin/bash

date

ps -leaf | grep node
#forever stopall
killall /usr/bin/nodejs
sleep 2
#forever list
ps -leaf | grep node

coffee --compile --output js/ src/ spec/ src_common
coffee --compile --output public/js-cs src_client src_common

export NODE_ENV=production
export SITE_URL=http://wowactivity.kimptoc.net/
export PORT=3000

forever start -a -l logs/forever.log -o logs/out.log -e logs/err.log app.js
#nohup node app.js 2>&1 >logs/node.log &
#forever list
ps -leaf | grep node

date
