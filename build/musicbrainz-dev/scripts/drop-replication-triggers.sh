#!/bin/bash

set -e

cd /musicbrainz-server

exec admin/psql MAINTENANCE -- -f admin/sql/DropAllReplicationTriggers2.sql
