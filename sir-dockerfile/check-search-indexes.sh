#!/bin/bash

set -e -u

SCRIPT_NAME=$(basename "$0")
HELP=$(cat <<EOH
Usage: $SCRIPT_NAME all
   or: $SCRIPT_NAME CORE...

For each of MusicBrainz Solr cores/collections,
compare the count of existing documents in PostgreSQL,
with the count of indexed documents in Solr.

Note: docker-compose services 'db' and 'indexer' must be up
EOH
)

MB_DOCKER_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)

cd "$MB_DOCKER_ROOT"

# Build PostgreSQL queries to count existing documents by core

declare -A queries

queries['annotation']="$(cat <<EOSQL
SELECT SUM(annotation_count) FROM (
          SELECT COUNT(DISTINCT area)
          annotation_count FROM area_annotation          AS one
    UNION SELECT COUNT(DISTINCT artist)
          annotation_count FROM artist_annotation
    UNION SELECT COUNT(DISTINCT event)
          annotation_count FROM event_annotation
    UNION SELECT COUNT(DISTINCT instrument)
          annotation_count FROM instrument_annotation
    UNION SELECT COUNT(DISTINCT label)
          annotation_count FROM label_annotation
    UNION SELECT COUNT(DISTINCT place)
          annotation_count FROM place_annotation
    UNION SELECT COUNT(DISTINCT recording)
          annotation_count FROM recording_annotation
    UNION SELECT COUNT(DISTINCT release)
          annotation_count FROM release_annotation
    UNION SELECT COUNT(DISTINCT release_group)
          annotation_count FROM release_group_annotation
    UNION SELECT COUNT(DISTINCT series)
          annotation_count FROM series_annotation
    UNION SELECT COUNT(DISTINCT work)
          annotation_count FROM work_annotation
) AS total
EOSQL
)"

queries['cdstub']="SELECT COUNT(id) FROM release_raw"

for table in area artist editor event instrument label place \
  recording release release_group series tag url work
do
  queries["${table//_/-}"]="SELECT COUNT(id) FROM $table"
done

# Parse arguments

if [ $# -eq 0 ]
then
  echo >&2 "$SCRIPT_NAME: missing argument"
  echo >&2 "Try '$SCRIPT_NAME --help' for usage."
  exit 64
fi

declare -a cores

if [ $# -eq 1 -a \( "$1" = '-h' -o "$1" = '--help' \) ]
then
  echo "$HELP"
  exit
elif [ $# -eq 1 -a "$1" = 'all' ]
then
  cores=( ${!queries[@]} )
else
  cores=()
  while [ $# -gt 0 ]
  do
    if [ -z "${queries[$1]-}" ]
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

service_containers="$(docker-compose ps db 2>/dev/null)"
if ! echo "$service_containers" | grep -qw 'Up'
then
  echo >&2 "$SCRIPT_NAME: cannot count existing documents: " \
           "the docker-compose service 'db' is not up"
  echo >&2 "Try 'docker-compose up -d' from '$MB_DOCKER_ROOT'"
  exit 69
fi

service_containers="$(docker-compose ps indexer 2>/dev/null)"
if ! echo "$service_containers" | grep -qw 'Up'
then
  echo >&2 "$SCRIPT_NAME: cannot count indexed documents: " \
           "the docker-compose service 'indexer' is not up"
  echo >&2 "Try 'docker-compose up -d' from '$MB_DOCKER_ROOT'"
  exit 69
fi

# Count existing documents by core in PostgreSQL

declare -A counts

POSTGRES_USER=musicbrainz
POSTGRES_DATABASE=musicbrainz_db
for core in "${cores[@]}"
do
  counts["$core"]=$(docker-compose exec db \
    psql -U $POSTGRES_USER -d $POSTGRES_DATABASE \
         -c "COPY(${queries[$core]}) TO STDOUT" | tr -d '\r')
done

# Sort cores by ascending number of documents

declare -a ascending_cores=( $(
  for core in "${!counts[@]}"
  do
    echo $core ${counts["$core"]}
  done | sort -n -k2 | sed 's/ .*$//'
) )

# Count indexed documents by core in Solr

declare -A indexed_docs

while read line
do
  core=${line% *}
  docs=${line#* }
  indexed_docs["$core"]="${docs/$'\r'/}"
done < <(docker-compose exec indexer bash -c "
wget -q -O - http://search:8983/v2/cores | python2 -c '
import sys, json;
json_status = json.load(sys.stdin)[\"status\"];
for core in json_status:
    print core, json_status[core][\"index\"][\"numDocs\"]
'" | sort -n -k2)

# Compare number of indexed docs with number of existing docs, by core

for core in "${ascending_cores[@]}"
do
  if [ ${counts[$core]} -eq ${indexed_docs[$core]} ]
  then
    echo "$core" "OK" "${indexed_docs[$core]}" "/${counts[$core]}"
  else
    echo "$core" "--" "${indexed_docs[$core]}" "/${counts[$core]}"
  fi
done | (
  if column --version &>/dev/null
  then
    column --table \
           --table-columns CORE,STATUS,INDEX,DB --table-right INDEX
  else
    (echo CORE STATUS INDEX DB; cat) | column -t
  fi
)

# vi: set et sts=2 sw=2 ts=2 :
