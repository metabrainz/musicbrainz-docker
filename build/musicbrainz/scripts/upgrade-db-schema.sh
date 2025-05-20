#!/bin/bash

set -e -u

export MUSICBRAINZ_DB_SCHEMA_SEQUENCE=29

dockerize -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s carton exec -- ./upgrade.sh
