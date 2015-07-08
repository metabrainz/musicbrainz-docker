#!/bin/sh

cron -f &
redis-server --daemonize yes
plackup -Ilib -r
