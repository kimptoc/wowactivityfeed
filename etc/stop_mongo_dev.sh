#!/bin/zsh

echo "Stopping MongoDB in DEV"

echo "Already running mongo* processes :"
ps -A | grep mongo
echo

killall mongod
echo

sleep 1

echo "Now running mongo* processes :"
ps -A | grep mongo
echo
