#!/bin/bash

psql -U $DB_ENV_POSTGRES_USER -h $MUSICBRAINZDOCKER_POSTGRESQL_1_PORT_5432_TCP_ADDR -c "DROP DATABASE musicbrainz_db;" && /createdb.sh -fetch