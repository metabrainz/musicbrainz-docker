#!/bin/bash
sleep 2m

HAS_SCRIPTS=$(curl 'http://localhost:5000/' | grep '/static/build/common' 2> /dev/null)

if [[ -n $HAS_SCRIPTS ]]; then
  exit 0
fi

exit 1
