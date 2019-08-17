#!/bin/bash

set -e -u

sleep 2m

if curl --retry 20 --retry-delay 20 'http://localhost:5000/' \
  | grep -q '/static/build/styles/common'
then
  echo 'Local website has locally built scripts'
  exit 0
fi

exit 1
