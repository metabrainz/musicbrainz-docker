#!/bin/bash

set -e -u

dockerize \
  -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s \
  -wait "tcp://${MUSICBRAINZ_REDIS_SERVER}:6379" -timeout 60s \
  true

if [ -f /crons.conf -a -s /crons.conf ]
then
  crontab /crons.conf
  cron -f &
fi

sleep infinity
