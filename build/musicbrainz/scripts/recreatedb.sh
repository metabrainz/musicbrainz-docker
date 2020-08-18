#!/bin/bash

psql postgres -U musicbrainz -h db -c "DROP DATABASE musicbrainz_db;"; createdb.sh "$@"
