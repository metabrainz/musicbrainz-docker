#!/bin/bash

eval "$(perl -Mlocal::lib="${MUSICBRAINZ_PERL_LOCAL_LIB}")"

export POSTGRES_USER=${POSTGRES_USER:-musicbrainz}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-musicbrainz}

/bin/bash /musicbrainz-server/admin/cron/slave.sh
