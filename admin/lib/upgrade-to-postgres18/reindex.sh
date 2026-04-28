#!/bin/bash

# Reindexes all databases and refreshes the collation versions.

DATABASES=$(
    psql \
        -U musicbrainz \
        -d template1 \
        -c 'SELECT datname FROM pg_database WHERE datallowconn' \
        -Atq
)

for database in $DATABASES; do
    echo "$(date) : Reindexing database ${database}..."

    OUTPUT="$(psql -U musicbrainz -d "$database" -c "REINDEX DATABASE $database;" 2>&1)" \
        || { printf '%s\n' "$OUTPUT" >&2; exit 1; }

    OUTPUT="$(psql -U musicbrainz -d "$database" -c "ALTER DATABASE $database REFRESH COLLATION VERSION;" 2>&1)" \
        || { printf '%s\n' "$OUTPUT" >&2; exit 1; }

    if [[ "$database" == 'musicbrainz_db' ]]; then
        OUTPUT="$(psql -U musicbrainz -d "$database" -c 'ALTER COLLATION musicbrainz.musicbrainz REFRESH VERSION;' 2>&1)" \
            || { printf '%s\n' "$OUTPUT" >&2; exit 1; }
    fi
done
