#!/bin/sh
sleep 8
kill -9 $1
#USAGE: set killwatch [open "|/tmp/killdelay.sh [pid]"];exec kill -9 [pid $killwatch]
