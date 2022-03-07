#!/bin/bash

set -e -u

if ! [[ -x /code/venv-musicbrainz-docker/bin/python2 ]]
then
  (
    unset PYTHONPATH
    virtualenv \
      --python=python2 \
      --system-site-packages \
      --verbose \
      /code/venv-musicbrainz-docker
  )
fi

mkdir -p .cache

pip install \
  --cache-dir /code/.cache \
  --disable-pip-version-check \
  --prefix /code/venv-musicbrainz-docker \
  -r requirements.txt \
  -r requirements_dev.txt

dockerize \
  -wait tcp://db:5432 -timeout 60s \
  -wait tcp://mq:5672 -timeout 60s \
  -wait tcp://search:8983 -timeout 60s \
  sleep 0

exec "$@"
