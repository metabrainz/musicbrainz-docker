#!/bin/sh

eval $( perl -Mlocal::lib )

cron -f &
/start_mb_renderer.pl
start_server --port=5000 -- plackup -I lib -s Starlet -E deployment --nproc 10 --pid fcgi.pid
