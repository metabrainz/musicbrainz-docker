#!/bin/bash

set -e -u

while true
do
    # Sleep first to make sure everything is up before starting replication
    sleep 5m
    /musicbrainz-server/admin/replication/LoadReplicationChanges
done
