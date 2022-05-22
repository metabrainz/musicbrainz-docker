#!/bin/bash

set -e -u

dockerize -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s sleep 0

while true
do
    # Sleep first to make sure everything is up before starting replication
    sleep 5m
    /musicbrainz-server/admin/replication/LoadReplicationChanges
done
