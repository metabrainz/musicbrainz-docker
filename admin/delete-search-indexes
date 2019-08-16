#!/bin/bash

set -e -u

SCRIPT_NAME=$(basename "$0")
HELP=$(cat <<EOH
Usage: $SCRIPT_NAME all
   or: $SCRIPT_NAME CORE...

For each of MusicBrainz Solr cores/collections,
delete all indexed documents from Solr server.

Note: docker-compose service 'search' must be up
EOH
)

MB_DOCKER_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)

cd "$MB_DOCKER_ROOT"

# Parse arguments

if [ $# -eq 0 ]
then
  echo >&2 "$SCRIPT_NAME: missing argument"
  echo >&2 "Try '$SCRIPT_NAME --help' for usage."
  exit 64
fi

declare -A all_cores=(
  [annotation]=1 [area]=1 [artist]=1 [cdstub]=1 [editor]=1 [event]=1
  [instrument]=1 [label]=1 [place]=1 [recording]=1 [release]=1
  [release_group]=1 [series]=1 [tag]=1 [url]=1 [work]=1
)

declare -a cores

if [ $# -eq 1 -a \( "$1" = '-h' -o "$1" = '--help' \) ]
then
  echo "$HELP"
  exit
elif [ $# -eq 1 -a "$1" = 'all' ]
then
  cores=( ${!all_cores[@]} )
else
  cores=()
  while [ $# -gt 0 ]
  do
    if [ -z "${all_cores[$1]-}" ]
    then
      echo >&2 "$SCRIPT_NAME: unrecognized core '$1'"
      echo >&2 "Try '$SCRIPT_NAME --help' for usage."
      exit 64
    else
      cores+=( $1 )
      shift
    fi
  done
fi

# Check that required docker-compose services are up

service_containers="$(docker-compose ps search 2>/dev/null)"
if ! echo "$service_containers" | grep -qw 'Up'
then
  echo >&2 "$SCRIPT_NAME: cannot delete indexed documents: " \
           "the docker-compose service 'search' is not up"
  echo >&2 "Try 'docker-compose up -d' from '$MB_DOCKER_ROOT'"
  exit 69
fi

# For each collection/core, delete all indexed documents

for core in "${cores[@]}"
do
  echo -n "Posting deletion query for '$core'... "
  docker-compose exec search post -c "${core/$'\r'/}" \
    -d '<delete><query>*:*</query></delete>' >/dev/null
  echo "Done"
done

# vi: set et sts=2 sw=2 ts=2 :
