#!/bin/bash

set -e -o pipefail -u

sleep 2m

echo -n 'Test local website has locally built style sheet... '
if curl -sS --retry 20 --retry-delay 20 'http://localhost:5000/' \
  | grep -q '/static/build/common-[0-9a-f]*.css'
then
  echo OK
  exit 0 # EX_OK
else
  echo FAIL
  echo "'curl|grep' exited with status '$?'"
  echo "Content of 'http://localhost:5000/':"
  curl -sS --retry 20 --retry-delay 20 'http://localhost:5000/'
  exit 80 # EX_CSSNOTFOUND
fi
