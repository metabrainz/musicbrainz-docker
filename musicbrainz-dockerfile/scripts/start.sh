#!/bin/sh
redis-server --daemonize yes
plackup -Ilib -r
