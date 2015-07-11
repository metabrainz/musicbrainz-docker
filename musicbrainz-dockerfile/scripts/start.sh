#!/bin/sh

env | grep '^DB_' | sed 's/^/export /' > /exports.txt
cron -f &
redis-server --daemonize yes
plackup -Ilib -r
