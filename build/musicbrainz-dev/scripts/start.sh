#!/bin/bash

set -e -u

cd /musicbrainz-server

update-perl.sh

update-javascript.sh

start_mb_renderer.pl
start_server --port=5000 -- plackup -I lib -s Starlet -E deployment --max-workers ${MUSICBRAINZ_SERVER_PROCESSES} --pid -r fcgi.pid
