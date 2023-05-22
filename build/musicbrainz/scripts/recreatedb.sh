#!/bin/bash

set -e

dockerize -wait tcp://db:5432 -timeout 60s sleep 0
psql postgres -U musicbrainz -h db -c "DROP DATABASE IF EXISTS musicbrainz_db;"; createdb.sh "$@"
