#!/bin/bash

set -e -u

export MUSICBRAINZ_DB_SCHEMA_SEQUENCE=27

dockerize -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s ./upgrade.sh
