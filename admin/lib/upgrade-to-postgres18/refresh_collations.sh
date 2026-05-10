#!/bin/bash

# Refreshes the collation versions for all databases.

DATABASES=$(
    psql \
        -U musicbrainz \
        -d template1 \
        -c 'SELECT quote_ident(datname) FROM pg_database WHERE datallowconn' \
        -Atq
)

for database in $DATABASES; do
    OUTPUT="$(psql -U musicbrainz -d "$database" -c "ALTER DATABASE $database REFRESH COLLATION VERSION;" 2>&1)" \
        || { printf '%s\n' "$OUTPUT" >&2; exit 1; }
done
