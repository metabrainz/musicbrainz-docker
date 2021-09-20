#!/bin/bash

set -e -u

cd /musicbrainz-server

yarn

dockerize -wait tcp://db:5432 -timeout 60s -wait tcp://mq:5672 -timeout 60s -wait tcp://redis:6379 -timeout 60s

./script/compile_resources.sh --watch client server tests &> /compile_resources.log &
