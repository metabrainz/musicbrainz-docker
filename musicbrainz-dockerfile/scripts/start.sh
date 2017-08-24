#!/bin/sh

eval $( perl -Mlocal::lib )

cron -f &
nginx
/start_mb_renderer.pl
start_server --port=55901 -- plackup -I lib -s Starlet -E deployment --nproc 10 --pid fcgi.pid
