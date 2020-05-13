#!/bin/sh

set -e -u

# Work around for writing to logs with set-config.sh which is not PID 1
# From https://github.com/moby/moby/issues/6880#issuecomment-270723812
LOG_PIPE=/tmp/logpipe
if [ ! -e $LOG_PIPE ]; then
  mkfifo -m 600 $LOG_PIPE
  cat <> $LOG_PIPE 1>&2 &
fi

LOCK_FILE=/set-config.once
if [ ! -e $LOCK_FILE ]; then
  touch $LOCK_FILE
  /set-config.sh &>$LOG_PIPE &
fi

if [ $# -eq 0 ]; then
  exec docker-entrypoint.sh rabbitmq-server
else
  exec docker-entrypoint.sh $@
fi
