#!/bin/bash

psql -U $DB_ENV_POSTGRES_USER -h db -c "DROP DATABASE musicbrainz_db;" && /createdb.sh -fetch
