#!/bin/bash

set -e

cd /musicbrainz-server

exec admin/psql MAINTENANCE -- -f admin/sql/CreateAllReplicationTriggers2.sql
