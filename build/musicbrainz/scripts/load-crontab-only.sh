#!/bin/bash

set -e -u

MUSICBRAINZ_VALKEY_SERVER="${MUSICBRAINZ_VALKEY_SERVER:-${MUSICBRAINZ_REDIS_SERVER:-valkey}}"

dockerize \
  -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s \
  -wait "tcp://${MUSICBRAINZ_VALKEY_SERVER}:6379" -timeout 60s \
  true

if [ -f /crons.conf -a -s /crons.conf ]
then
  crontab /crons.conf
  cron -f &
fi

sleep infinity
