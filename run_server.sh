#!/bin/bash

coffee --compile --output js/ src/ spec/

export NODE_ENV=production
export SITE_URL=http://wafbeta.kimptoc.net/

nohup node app.js 2>&1 >logs/node.log &
