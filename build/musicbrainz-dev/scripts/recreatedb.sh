#!/bin/bash

set -e

dockerize -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s sleep 0
psql postgres -U musicbrainz -h "${MUSICBRAINZ_POSTGRES_SERVER}" -c "DROP DATABASE IF EXISTS musicbrainz_db;"; createdb.sh "$@"
