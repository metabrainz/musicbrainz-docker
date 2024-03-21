#!/bin/bash

set -e -u

if ! grep -q -s \
  "//${MUSICBRAINZ_WEB_SERVER_HOST}:${MUSICBRAINZ_WEB_SERVER_PORT}" \
  /musicbrainz-server/root/static/build/runtime.js.map
then
  /musicbrainz-server/script/compile_resources.sh
fi

dockerize -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s -wait "tcp://${MUSICBRAINZ_RABBITMQ_SERVER}:5672" -timeout 60s -wait "tcp://${MUSICBRAINZ_REDIS_SERVER}:6379" -timeout 60s start_mb_renderer.pl

if [ -f /crons.conf -a -s /crons.conf ]
then
  crontab /crons.conf
  cron -f &
fi

start_server --port=5000 -- plackup -I lib -s Starlet -E deployment --max-workers ${MUSICBRAINZ_SERVER_PROCESSES} --pid fcgi.pid
