#!/bin/sh
CREATE_DB=$1
if [ $CREATE_DB == true ]; then
  /createdb.sh
fi
cron -f &
redis-server --daemonize yes
plackup -Ilib -r
