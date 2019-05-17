#!/bin/bash

set -e -u

HELP=$(cat <<EOH
Usage: $0 <clean|install|uninstall>

Commands:
  clean       Remove temporary install scripts and uninstall scripts
  install     Create database triggers and add uninstall scripts
  uninstall   Drop database triggers and remove uninstall scripts
EOH
)

if [ $# -ne 1 ]; then
  echo "$0: wrong number of arguments"
  echo "$HELP"
  exit 1
fi

MB_DOCKER_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)
LOCAL_TRIGGERS_DIR=$(dirname "${BASH_SOURCE[0]}")/sql
REMOTE_TRIGGERS_DIR=/tmp/indexer-sql

cd "$MB_DOCKER_ROOT"

case "$1" in
  clean     )
    if ! docker-compose ps musicbrainz | grep -qw 'Up'; then
      echo "$0: cannot clean: 'musicbrainz' is not a running docker-compose service"
      exit 1
    fi

    echo "Cleaning indexer triggers install/uninstall scripts up ..."

    docker-compose exec musicbrainz rm -frv "$REMOTE_TRIGGERS_DIR"
    rm -frv "$LOCAL_TRIGGERS_DIR"
    ;;
  install   )
    if ! docker-compose ps indexer | grep -qw 'Up'; then
      echo "$0: cannot install: 'indexer' is not a running docker-compose service"
      exit 1
    fi

    if [ -e "$LOCAL_TRIGGERS_DIR" ]; then
      echo "$0: cannot install: File '$LOCAL_TRIGGERS_DIR' exists"
      exit 1
    fi

    if docker-compose exec musicbrainz test -e "$REMOTE_TRIGGERS_DIR"; then
      echo "$0: cannot install: File '$REMOTE_TRIGGERS_DIR' exists in 'musicbrainz' docker-compose service"
      exit 1
    fi

    echo "Installing indexer triggers ..."

    docker-compose exec indexer python -m sir triggers

    docker cp musicbrainz-docker_indexer_1:/code/sql "$LOCAL_TRIGGERS_DIR"
    docker cp "$LOCAL_TRIGGERS_DIR" musicbrainz-docker_musicbrainz_1:"$REMOTE_TRIGGERS_DIR"

    docker-compose exec musicbrainz /indexer-triggers.sh "$REMOTE_TRIGGERS_DIR" create

    rm -fr "$LOCAL_TRIGGERS_DIR"
    ;;
  uninstall )
    if ! docker-compose ps musicbrainz | grep -qw 'Up'; then
      echo "$0: Error: 'musicbrainz' is not a running docker-compose service"
      exit 1
    fi

    if docker-compose exec musicbrainz test ! -e "$REMOTE_TRIGGERS_DIR"; then
      echo "$0: Error: File '$REMOTE_TRIGGERS_DIR' does not exist"
    fi

    echo "Uninstalling indexer triggers ..."

    docker-compose exec musicbrainz /indexer-triggers.sh "$REMOTE_TRIGGERS_DIR" drop

    docker-compose exec musicbrainz rm -fr "$REMOTE_TRIGGERS_DIR"
    ;;
  *         )
    echo "$0: unrecognized command '$1'"
    echo "$HELP"
    exit 1
    ;;
esac

echo "Done."
