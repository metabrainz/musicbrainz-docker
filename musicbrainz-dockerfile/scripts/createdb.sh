#!/bin/bash

eval $( perl -Mlocal::lib )

FTP_HOST=ftp://ftp.eu.metabrainz.org
FETCH_DUMPS=$1
TMP_DIR=/media/dbdump/tmp

if [[ $2 != "" ]]; then
    FTP_HOST=$2
fi

if [[ $FETCH_DUMPS == "-fetch" ]]; then
  echo "fetching data dumps"

  apt-get install -y wget
  rm -rf /media/dbdump/*
  wget -nd -nH -P /media/dbdump $FTP_HOST/pub/musicbrainz/data/fullexport/LATEST
  LATEST=$(cat /media/dbdump/LATEST)
  wget -P /media/dbdump "$FTP_HOST/pub/musicbrainz/data/fullexport/$LATEST/MD5SUMS"
  wget -P /media/dbdump "$FTP_HOST/pub/musicbrainz/data/fullexport/$LATEST/mbdump.tar.bz2"
  wget -P /media/dbdump "$FTP_HOST/pub/musicbrainz/data/fullexport/$LATEST/mbdump-cdstubs.tar.bz2"
  wget -P /media/dbdump "$FTP_HOST/pub/musicbrainz/data/fullexport/$LATEST/mbdump-cover-art-archive.tar.bz2"
  wget -P /media/dbdump "$FTP_HOST/pub/musicbrainz/data/fullexport/$LATEST/mbdump-derived.tar.bz2"
  wget -P /media/dbdump "$FTP_HOST/pub/musicbrainz/data/fullexport/$LATEST/mbdump-stats.tar.bz2"
  wget -P /media/dbdump "$FTP_HOST/pub/musicbrainz/data/fullexport/$LATEST/mbdump-wikidocs.tar.bz2"
  pushd /media/dbdump && md5sum -c MD5SUMS && popd
fi

if [[ -a /media/dbdump/mbdump.tar.bz2 ]]; then
  echo "found existing dumps"

  mkdir -p $TMP_DIR

  # if the import fails because the DB does not exist yet such as when the DB
  # has been dropped, InitDb will be called again with the create flag
  /musicbrainz-server/admin/InitDb.pl --echo --import -- --skip-editor --tmp-dir $TMP_DIR /media/dbdump/mbdump*.tar.bz2 ||
  /musicbrainz-server/admin/InitDb.pl --create --echo --import -- --skip-editor --tmp-dir $TMP_DIR /media/dbdump/mbdump*.tar.bz2
else
  echo "no dumps found or dumps are incomplete"
fi
