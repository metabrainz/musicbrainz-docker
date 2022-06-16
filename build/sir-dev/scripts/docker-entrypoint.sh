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
  -wait tcp://db:5432 -timeout 60s \
  -wait tcp://mq:5672 -timeout 60s \
  -wait tcp://search:8983 -timeout 60s \
  sleep 0

exec "$@"
