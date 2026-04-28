#!/bin/bash

set -e
shopt -s extglob

PGDATA=/var/lib/postgresql/data
PGDATA_OLD="$PGDATA"/12
PGDATA_NEW="$PGDATA"/16
PGAMQP_DIR=/tmp/pg_amqp

function cleanup() {
	if [[ -d "$PGDATA_NEW" ]]; then
		echo "Clean $PG_DATA_NEW off"
		rm -rf "$PGDATA_NEW"
	fi

	if [[ -d "$PGDATA_OLD" ]]; then
		echo "Clean $PG_DATA_OLD off but 12 data"
		rm -rf "$PGDATA"/!(12)
		mv -v "$PGDATA_OLD"/* "$PGDATA"
		rmdir "$PGDATA_OLD"
	fi

	if [[ -d "$PGAMQP_DIR" ]]; then
		echo "Clean $PG_DATA_NEW off"
		rm -rf "$PGAMQP_DIR"
	fi
}
trap cleanup EXIT

sudo -u postgres /usr/lib/postgresql/12/bin/pg_ctl stop -w -D "$PGDATA" 2>/dev/null \
	|| echo 'Assuming server is stopped...'

# We use the --link flag on pg_upgrade below to make hard links instead of
# copying files, drastically improving the speed of the upgrade. Hard links,
# of course, require the linked files to be on the same file system, but
# $PGDATA is the volume *root*. To work around that, we have to move the
# existing v12 cluster to a '12' subdir, and create the new v16 cluster in
# a '16' subdir. Once we're finished, we'll move the new cluster's files
# back into $PGDATA.
cd "$PGDATA"
sudo -u postgres mkdir -p 12 16
chmod 700 12 16
sudo -u postgres mv !(12|16) 12

sudo -u postgres /usr/lib/postgresql/16/bin/initdb \
	--encoding utf8 \
	--username musicbrainz \
	"$PGDATA_NEW"

# There is no tag v0.4.2 (or 0.5.0) yet
PG_AMQP_GIT_REF="240d477d40c5e7a579b931c98eb29cef4edda164"
git clone https://github.com/omniti-labs/pg_amqp.git "$PGAMQP_DIR"
cd "$PGAMQP_DIR"
git checkout "$PG_AMQP_GIT_REF"
make PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config PG_CPPFLAGS=-Wno-error=implicit-int
make install
cd "$PGDATA"

sudo -u postgres /usr/lib/postgresql/16/bin/pg_upgrade \
	--old-bindir=/usr/lib/postgresql/12/bin/ \
	--new-bindir=/usr/lib/postgresql/16/bin/ \
	--old-datadir="$PGDATA_OLD" \
	--new-datadir="$PGDATA_NEW" \
	--jobs=3 \
	--old-options="-D $PGDATA_OLD -c config_file=$PGDATA_OLD/postgresql.conf -c hba_file=$PGDATA_OLD/pg_hba.conf -c port=5432" \
	--new-options="-D $PGDATA_NEW -c config_file=$PGDATA_OLD/postgresql.conf -c hba_file=$PGDATA_OLD/pg_hba.conf -c port=6432" \
	--old-port=5432 \
	--new-port=6432 \
	--link \
	--username=musicbrainz \
	--verbose

mv "$PGDATA_NEW"/* "$PGDATA"/
rmdir "$PGDATA_NEW"
cp -a "$PGDATA_OLD"/{postgresql.conf,pg_hba.conf} .

./delete_old_cluster.sh
rm delete_old_cluster.sh
