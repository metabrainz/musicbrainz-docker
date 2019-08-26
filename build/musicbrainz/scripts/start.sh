#!/bin/sh

eval $( perl -Mlocal::lib )

if ! grep -q -s \
  "//${MUSICBRAINZ_WEB_SERVER_HOST}:${MUSICBRAINZ_WEB_SERVER_PORT}" \
  /musicbrainz-server/root/static/build/runtime.js.map
then
  /musicbrainz-server/script/compile_resources.sh
fi

if [ -f /crons.conf -a -s /crons.conf ]
then
  crontab /crons.conf
  cron -f &
fi

/start_mb_renderer.pl
start_server --port=5000 -- plackup -I lib -s Starlet -E deployment --nproc 10 --pid fcgi.pid
