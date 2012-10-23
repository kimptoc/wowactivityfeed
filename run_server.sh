#!/bin/bash

coffee --compile --output js/ src/ spec/

export NODE_ENV=production
export SITE_URL=http://wafbeta.kimptoc.net/

forever start -a -l logs/forever.log -o logs/out.log -e logs/err.log app.js
#nohup node app.js 2>&1 >logs/node.log &
