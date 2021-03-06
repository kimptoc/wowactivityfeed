#!/bin/bash

date

mkdir -p ~/.forever/logs
mkdir logs

ps -leaf | grep node
forever stopall
sleep 2
forever list
ps -leaf | grep node

rm -f logs/*
rm -f /home/kimptoc/.forever/logs/*

coffee --compile --output js/ src/ spec/ src_common
coffee --compile --output public/js-cs src_client src_common

export NODE_ENV=production
export SITE_URL=${SITE_URL:-http://wowactivity.kimptoc.net}
export PORT=3000

rm restart_stats.json

forever start -c "node --max-old-space-size=2048" -a -l logs/forever.log -o logs/out.log -e logs/err.log app.js
#nohup node app.js 2>&1 >logs/node.log &
forever list
ps -leaf | grep node

date
