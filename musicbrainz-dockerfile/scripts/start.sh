#!/bin/sh

eval $( perl -Mlocal::lib )

env | grep '^DB_' | sed 's/^/export /' > /exports.txt

cron -f &
redis-server --daemonize yes
nginx
/start_mb_renderer.pl
start_server --port=55901 -- plackup -I lib -s Starlet -E deployment --nproc 10 --pid fcgi.pid
