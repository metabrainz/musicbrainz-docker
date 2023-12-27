#!/bin/bash

set -e -u

cd /musicbrainz-server

yarn

dockerize -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s -wait "tcp://${MUSICBRAINZ_RABBITMQ_SERVER}:5672" -timeout 60s -wait "tcp://${MUSICBRAINZ_REDIS_SERVER}:6379" -timeout 60s

./script/compile_resources.sh --watch client server tests &> /compile_resources.log &
