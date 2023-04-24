#!/bin/bash

set -e -o pipefail -u

BASE_DOWNLOAD_URL="${MUSICBRAINZ_BASE_FTP_URL:-$MUSICBRAINZ_BASE_DOWNLOAD_URL}"
IMPORT="fullexport"
FETCH_DUMPS=""
WGET_OPTIONS=""

HELP=$(cat <<EOH
Usage: $0 [-wget-opts <options list>] [-sample] [-fetch] [MUSICBRAINZ_BASE_DOWNLOAD_URL]

Options:
  -fetch      Fetch latest dump from MusicBrainz download server
  -sample     Load sample data instead of full data
  -wget-opts  Pass additional space-separated options list (should be
              a single argument, escape spaces if necessary) to wget

Default MusicBrainz base download URL: $BASE_DOWNLOAD_URL
EOH
)

if [ $# -gt 4 ]; then
    echo "$0: too many arguments"
    echo "$HELP"
    exit 1
fi

while [ $# -gt 0 ]; do
    case "$1" in
        -wget-opts )
            shift
            WGET_OPTIONS=$1
            ;;
        -sample )
            IMPORT="sample"
            ;;
        -fetch  )
            FETCH_DUMPS="$1"
            ;;
        -*      )
            echo "$0: unrecognized option '$1'"
            echo "$HELP"
            exit 1
            ;;
        *       )
            BASE_DOWNLOAD_URL="$1"
            ;;
    esac
    shift
done

TMP_DIR=/media/dbdump/tmp

case "$IMPORT" in
    fullexport  )
        if [[ $MUSICBRAINZ_STANDALONE_SERVER -eq 1 ]]; then
            echo "$0: Only sample data can be loaded in standalone mode"
            echo "$HELP"
            exit 1
        fi
        DUMP_FILES=(
            mbdump.tar.bz2
            mbdump-cdstubs.tar.bz2
            mbdump-cover-art-archive.tar.bz2
            mbdump-derived.tar.bz2
            mbdump-stats.tar.bz2
            mbdump-wikidocs.tar.bz2
        );;
    sample      )
        if [[ $MUSICBRAINZ_STANDALONE_SERVER -eq 0 ]]; then
            echo "$0: Only full data can be loaded in mirror mode"
            echo "$HELP"
            exit 1
        fi
        DUMP_FILES=(
            mbdump-sample.tar.xz
        );;
esac

if [[ $FETCH_DUMPS == "-fetch" ]]; then
    FETCH_OPTIONS=("${IMPORT/fullexport/replica}" --base-download-url "$BASE_DOWNLOAD_URL")
    if [[ -n "$WGET_OPTIONS" ]]; then
        FETCH_OPTIONS+=(--wget-options "$WGET_OPTIONS")
    fi
    fetch-dump.sh "${FETCH_OPTIONS[@]}"
fi

for F in "${DUMP_FILES[@]}"; do
    if ! [[ -a "/media/dbdump/$F" ]]; then
        echo "$0: The dump '$F' is missing"
        exit 1
    fi
done

echo "found existing dumps"
dockerize -wait tcp://db:5432 -timeout 60s sleep 0

mkdir -p $TMP_DIR
cd /media/dbdump

INITDB_OPTIONS='--echo --import'
if ! /musicbrainz-server/script/database_exists MAINTENANCE; then
    INITDB_OPTIONS="--createdb $INITDB_OPTIONS"
fi
# shellcheck disable=SC2086
/musicbrainz-server/admin/InitDb.pl $INITDB_OPTIONS -- --skip-editor --tmp-dir $TMP_DIR "${DUMP_FILES[@]}"
