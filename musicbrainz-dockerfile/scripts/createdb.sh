#!/bin/bash
apt-get install -y wget
rm -rf /media/dbdump/*
wget -nd -nH -P /media/dbdump ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/LATEST
LATEST=$(cat /media/dbdump/LATEST)
wget -r --no-parent -nd -nH -P /media/dbdump --reject "index.html*, mbdump-edit*, mbdump-documentation*" "ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$LATEST"
pushd /media/dbdump && md5sum -c MD5SUMS && popd
./admin/InitDb.pl --createdb --import /media/dbdump/mbdump*.tar.bz2 --echo
