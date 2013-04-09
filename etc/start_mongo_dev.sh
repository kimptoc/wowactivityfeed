#!/bin/zsh

echo "Starting MongoDB in DEV"

echo "Already running mongo* processes (this is fyi, should be none probably):"
ps -A | grep mongo
echo

export DBDIR=~/tmp/mongo_waf/
mkdir $DBDIR
mkdir $DBDIR/rs1
mkdir $DBDIR/rs2
mkdir $DBDIR/rs3

mongod --journal --fork --logpath $DBDIR/rs1.log --smallfiles --oplogSize 50 --port 27001 --dbpath $DBDIR/rs1 --noscripting --replSet rs --auth --keyFile /Users/kimptoc/Dropbox/dev/wowfeed.osx/etc/repl_set_secret.txt
mongod --journal --fork --logpath $DBDIR/rs2.log --smallfiles --oplogSize 50 --port 27002 --dbpath $DBDIR/rs2 --noscripting --replSet rs --auth --keyFile /Users/kimptoc/Dropbox/dev/wowfeed.osx/etc/repl_set_secret.txt
mongod --journal --fork --logpath $DBDIR/rs3.log --smallfiles --oplogSize 50 --port 27003 --dbpath $DBDIR/rs3 --noscripting --replSet rs --auth --keyFile /Users/kimptoc/Dropbox/dev/wowfeed.osx/etc/repl_set_secret.txt

# give them time to start. note this might not be enough time!
sleep 1

ps -A | grep mongo
echo

echo "mongo shell -> mongo --port 27001"
echo "mongo repl set -> rs.initiate( { _id : \"rs\", members : [ { _id : 0, host : \"localhost:27001\" } ] } )"
echo "add user/1 -> use admin"
echo "add user/2 -> db.addUser('user','pass')"
echo "add user/1 -> use wowfeed"
echo "add user/2 -> db.addUser('user','pass')"
echo "login/1 -> use admin"
echo "login/2 -> db.auth('user','pass')"
# echo "add repl set member -> rs.add('localhost:27002')" # or whatever your hostname is
# echo "add repl set member -> rs.add('Chris-Kimptons-MacBook-Air-2011.local:27002')" # or whatever your hostname is
# echo "add repl set member -> rs.add( { \"host\": \"Chris-Kimptons-MacBook-Air-2011.local:27002\", \"priority\": 0 } )" # or whatever your hostname is
echo "add repl set member -> rs.add( { _id: 1, host: \"localhost:27002\" } )" # or whatever your hostname is
echo "repl set status -> rs.status()"
echo "dump running db -> mongodump --port 27001 -u user -p pass"
