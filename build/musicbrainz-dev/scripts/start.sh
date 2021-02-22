#!/bin/bash

set -e -u

cd /musicbrainz-server

update-perl.sh

yarn

dockerize -wait tcp://db:5432 -timeout 60s -wait tcp://mq:5672 -timeout 60s -wait tcp://redis:6379 -timeout 60s ./script/compile_resources.sh

start_mb_renderer.pl
start_server --port=5000 -- plackup -I lib -s Starlet -E deployment --nproc ${MUSICBRAINZ_SERVER_PROCESSES} --pid fcgi.pid
