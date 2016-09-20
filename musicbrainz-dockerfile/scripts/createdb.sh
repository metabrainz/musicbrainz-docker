#!/bin/bash

FTP_HOST=ftp://ftp.musicbrainz.org
FETCH_DUMPS=$1

if [[ $2 != "" ]]; then
    FTP_HOST=$2
fi

if [[ $FETCH_DUMPS == "-fetch" ]]; then
  echo "fetching data dumps"

  apt-get install -y wget
  rm -rf /media/dbdump/*
  wget -nd -nH -P /media/dbdump $FTP_HOST/pub/musicbrainz/data/fullexport/LATEST
  LATEST=$(cat /media/dbdump/LATEST)
  wget -r --no-parent -nd -nH -P /media/dbdump --reject "index.html*, mbdump-edit*, mbdump-documentation*" "$FTP_HOST/pub/musicbrainz/data/fullexport/$LATEST"
  pushd /media/dbdump && md5sum -c MD5SUMS && popd
  /musicbrainz-server/admin/InitDb.pl --createdb --import /media/dbdump/mbdump*.tar.bz2 --echo
elif [[ -a /media/dbdump/mbdump.tar.bz2 ]]; then
  echo "found existing dumps"

  /musicbrainz-server/admin/InitDb.pl --createdb --import /media/dbdump/mbdump*.tar.bz2 --echo
else
  echo "no dumps found or dumps are incomplete"
  /musicbrainz-server/admin/InitDb.pl --createdb --echo
fi
