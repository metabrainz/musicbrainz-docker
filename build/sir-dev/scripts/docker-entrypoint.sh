#!/bin/bash

set -e -u

mkdir -p .cache venv-musicbrainz-docker

pip install \
  --cache-dir /code/.cache \
  --disable-pip-version-check \
  --user \
  -r requirements.txt \
  -r requirements_dev.txt

dockerize \
  -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s \
  -wait "tcp://${MUSICBRAINZ_RABBITMQ_SERVER}:5672" -timeout 60s \
  -wait tcp://search:8983 -timeout 60s \
  sleep 0

exec "$@"
