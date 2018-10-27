#!/bin/bash
eval $( perl -Mlocal::lib )

FETCH_DUMPS=$1

psql postgres -U musicbrainz -h db -c "DROP DATABASE musicbrainz_db;"; /createdb.sh $FETCH_DUMPS
