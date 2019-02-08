#!/bin/bash

eval $( perl -Mlocal::lib )

FTP_MB=ftp://ftp.eu.metabrainz.org/pub/musicbrainz
IMPORT="fullexport"
FETCH_DUMPS=""

read -d '' -r HELP <<HELP
Usage: $0 [-sample] [-fetch] [MUSICBRAINZ_FTP_URL]

Options:
  -fetch      Fetch latest dump from MusicBrainz FTP
  -sample     Load sample data instead of full data

Default MusicBrainz FTP URL: $FTP_MB
HELP

if [ $# -gt 3 ]; then
    echo "$0: too many arguments"
    echo "$HELP"
    exit 1
fi

while [ $# -gt 0 ]; do
    case "$1" in
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
    echo "fetching data dumps"

    apt-get install -y wget
    rm -rf /media/dbdump/*
    wget -nd -nH -P /media/dbdump $FTP_MB/data/$IMPORT/LATEST
    LATEST=$(cat /media/dbdump/LATEST)
    if [[ $IMPORT == "fullexport" ]]; then
        for F in MD5SUMS ${DUMP_FILES[@]}; do
            wget -P /media/dbdump "$FTP_MB/data/$IMPORT/$LATEST/$F"
        done
        pushd /media/dbdump && md5sum -c MD5SUMS && popd
    elif [[ $IMPORT == "sample" ]]; then
        for F in ${DUMP_FILES[@]}; do
            wget -P /media/dbdump "$FTP_MB/data/$IMPORT/$LATEST/$F"
        done
    fi
fi

if [[ -a /media/dbdump/"${DUMP_FILES[0]}" ]]; then
    echo "found existing dumps"

    mkdir -p $TMP_DIR
    cd /media/dbdump

    # if the import fails because the DB does not exist yet such as when the DB
    # has been dropped, InitDb will be called again with the create flag
    /musicbrainz-server/admin/InitDb.pl --echo --import -- --skip-editor --tmp-dir $TMP_DIR ${DUMP_FILES[@]} ||
    /musicbrainz-server/admin/InitDb.pl --create --echo --import -- --skip-editor --tmp-dir $TMP_DIR ${DUMP_FILES[@]}
else
    echo "no dumps found or dumps are incomplete"
fi
