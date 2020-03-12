#!/bin/bash

set -e

# liblocal-lib-perl < 2.000019 generates commands using unset variable
eval "$(perl -Mlocal::lib)"

set -u

HELP="Usage: $0 INDEXER_SQL_DIR <create|drop>"

if [ $# -ne 2 ]; then
  echo "$0: wrong number of arguments"
  echo "$HELP"
  exit 1
fi

INDEXER_SQL_DIR="$1"

cd /musicbrainz-server

case "$2" in
  create)
    admin/psql < "$INDEXER_SQL_DIR/CreateFunctions.sql"
    admin/psql < "$INDEXER_SQL_DIR/CreateTriggers.sql"
    admin/GenerateSQLScripts.pl "$INDEXER_SQL_DIR/"
    ;;
  drop  )
    admin/psql < "$INDEXER_SQL_DIR/DropTriggers.sql"
    admin/psql < "$INDEXER_SQL_DIR/DropFunctions.sql"
    rm -frv "$INDEXER_SQL_DIR"
    ;;
  *    )
    echo "$0: unrecognized command '$2'"
    echo "$HELP"
    exit 1
    ;;
esac
