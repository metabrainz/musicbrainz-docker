#!/bin/sh

set -e

# liblocal-lib-perl < 2.000019 generates commands using unset variable
eval "$(perl -Mlocal::lib)"

set -u

if ! grep -q -s \
  "//${MUSICBRAINZ_WEB_SERVER_HOST}:${MUSICBRAINZ_WEB_SERVER_PORT}" \
  /musicbrainz-server/root/static/build/runtime.js.map
then
  /musicbrainz-server/script/compile_resources.sh
fi

dockerize -wait tcp://db:5432 -timeout 60s -wait tcp://mq:5672 -timeout 60s -wait tcp://redis:6379 -timeout 60s start_mb_renderer.pl

if [ -f /crons.conf -a -s /crons.conf ]
then
  crontab /crons.conf
  cron -f &
fi

start_server --port=5000 -- plackup -I lib -s Starlet -E deployment --nproc 10 --pid fcgi.pid
