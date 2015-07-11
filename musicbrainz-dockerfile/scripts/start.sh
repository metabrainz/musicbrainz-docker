#!/bin/sh

env | grep '^DB_' | sed 's/^/export /' > /exports.txt
cron -f &
redis-server --daemonize yes
nginx
plackup -Ilib -s FCGI -E deployment --port 55901 --nproc 10 --pid fcgi.pid --keep-stderr=1
