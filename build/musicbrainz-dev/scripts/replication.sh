#!/bin/bash

set -e

dockerize -wait tcp://db:5432 -timeout 60s sleep 0
exec /musicbrainz-server/admin/cron/mirror.sh
