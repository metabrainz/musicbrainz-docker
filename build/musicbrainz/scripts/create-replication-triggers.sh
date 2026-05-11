#!/bin/bash

set -e

cd /musicbrainz-server

dockerize -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s sleep 0

exec carton exec -- admin/psql MAINTENANCE -- -f admin/sql/CreateAllReplicationTriggers2.sql
