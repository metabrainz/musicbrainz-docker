#!/bin/bash
eval $( /usr/bin/perl -Mlocal::lib )
export POSTGRES_USER=${POSTGRES_USER:-musicbrainz}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-musicbrainz}

/bin/bash /musicbrainz-server/admin/cron/slave.sh
