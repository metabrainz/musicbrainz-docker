#!/bin/bash

set -e -o pipefail

# liblocal-lib-perl < 2.000019 generates commands using unset variable
eval "$(perl -Mlocal::lib="${MUSICBRAINZ_PERL_LOCAL_LIB}")"

set -u

FTP_MB=ftp://ftp.eu.metabrainz.org/pub/musicbrainz
IMPORT="fullexport"
FETCH_DUMPS=""
WGET_OPTIONS=""

HELP=$(cat <<EOH
Usage: $0 [-wget-opts <options list>] [-sample] [-fetch] [MUSICBRAINZ_FTP_URL]

Options:
  -fetch      Fetch latest dump from MusicBrainz FTP
  -sample     Load sample data instead of full data
  -wget-opts  Pass additional space-separated options list (should be
              a single argument, escape spaces if necessary) to wget

Default MusicBrainz FTP URL: $FTP_MB
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
            FTP_MB="$1"
            ;;
    esac
    shift
done

TMP_DIR=/media/dbdump/tmp

case "$IMPORT" in
    fullexport  )
        DUMP_FILES=(
            mbdump.tar.bz2
            mbdump-cdstubs.tar.bz2
            mbdump-cover-art-archive.tar.bz2
            mbdump-derived.tar.bz2
            mbdump-stats.tar.bz2
            mbdump-wikidocs.tar.bz2
        );;
    sample      )
        DUMP_FILES=(
            mbdump-sample.tar.xz
        );;
esac

if [[ $FETCH_DUMPS == "-fetch" ]]; then
    FETCH_OPTIONS=("${IMPORT/fullexport/replica}" --base-ftp-url "$FTP_MB")
    if [[ -n "$WGET_OPTIONS" ]]; then
        FETCH_OPTIONS+=(--wget-options "$WGET_OPTIONS")
    fi
    fetch-dump.sh "${FETCH_OPTIONS[@]}"
fi

if [[ -a /media/dbdump/"${DUMP_FILES[0]}" ]]; then
    echo "found existing dumps"

    mkdir -p $TMP_DIR
    cd /media/dbdump

    INITDB_OPTIONS='--echo --import'
    if ! /musicbrainz-server/script/database_exists MAINTENANCE; then
        INITDB_OPTIONS="--createdb $INITDB_OPTIONS"
    fi
    # shellcheck disable=SC2086
    /musicbrainz-server/admin/InitDb.pl $INITDB_OPTIONS -- --skip-editor --tmp-dir $TMP_DIR "${DUMP_FILES[@]}"
else
    echo "no dumps found or dumps are incomplete"
fi
