#!/bin/bash

set -e -u

if [ $# -ne 0 ]; then
  echo "$0: too many arguments"
  echo "Usage: $0"
  exit 1
fi

MB_DOCKER_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)
LOCAL_SQL_FILE=sir-dockerfile/amqp-extension.sql
REMOTE_SQL_FILE=/tmp/CreateExtensionAMQP.sql

cd "$MB_DOCKER_ROOT"

if ! docker-compose ps indexer | grep -qw 'Up'; then
  echo "$0: cannot install: 'indexer' is not a running docker-compose service"
  exit 1
fi

if [ -e "$LOCAL_SQL_FILE" ]; then
  echo "$0: cannot install: File '$LOCAL_SQL_FILE' exists"
fi

if docker-compose exec db test -e "$REMOTE_SQL_FILE"; then
  echo "$0: cannot install: File '$REMOTE_SQL_FILE' exists in 'db' docker-compose service"
fi

echo "Installing indexer AMQP extension into PostgreSQL ..."

docker-compose exec indexer python -m sir extension

docker cp musicbrainz-docker_indexer_1:/code/sql/CreateExtension.sql "$LOCAL_SQL_FILE"
docker cp "$LOCAL_SQL_FILE" musicbrainz-docker_db_1:"$REMOTE_SQL_FILE"

docker-compose exec db psql -U musicbrainz -d musicbrainz_db -f "$REMOTE_SQL_FILE"

docker-compose exec db rm -f "$REMOTE_SQL_FILE"
rm -f "$LOCAL_SQL_FILE"

echo "Done."
