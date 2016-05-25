#!/bin/sh

env | grep '^DB_' | sed 's/^/export /' > /exports.txt

./script/compile_resources.sh

cron -f &
redis-server --daemonize yes
nginx
start_server --port=55901 -- plackup -I lib -s Starlet -E deployment --nproc 10 --pid fcgi.pid
