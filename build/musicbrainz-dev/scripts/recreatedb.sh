#!/bin/bash

eval "$(perl -Mlocal::lib="${MUSICBRAINZ_PERL_LOCAL_LIB}")"

psql postgres -U musicbrainz -h db -c "DROP DATABASE musicbrainz_db;"; createdb.sh "$@"
