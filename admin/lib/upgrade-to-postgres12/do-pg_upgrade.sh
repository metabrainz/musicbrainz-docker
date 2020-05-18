#!/bin/bash

set -e
shopt -s extglob

PGDATA=/var/lib/postgresql/data
PGDATA_OLD="$PGDATA"/9.5
PGDATA_NEW="$PGDATA"/12
PGAMQP_DIR=/tmp/pg_amqp

function cleanup() {
	if [[ -d "$PGDATA_NEW" ]]; then
		echo "Clean $PG_DATA_NEW off"
		rm -rf "$PGDATA_NEW"
	fi

	if [[ -d "$PGDATA_OLD" ]]; then
		echo "Clean $PG_DATA_OLD off but 9.5 data"
		rm -rf "$PGDATA"/!(9.5)
		mv -v "$PGDATA_OLD"/* "$PGDATA"
		rmdir "$PGDATA_OLD"
	fi

	if [[ -d "$PGAMQP_DIR" ]]; then
		echo "Clean $PG_DATA_NEW off"
		rm -rf "$PGAMQP_DIR"
	fi
}
trap cleanup EXIT

sudo -u postgres /usr/lib/postgresql/9.5/bin/pg_ctl stop -w -D "$PGDATA" \
	|| echo 'Assuming server is stopped...'

# We use the --link flag on pg_upgrade below to make hard links instead of
# copying files, drastically improving the speed of the upgrade. Hard links,
# of course, require the linked files to be on the same file system, but
# $PGDATA is the volume *root*. To work around that, we have to move the
# existing v9.5 cluster to a '9.5' subdir, and create the new v12 cluster in
# a '12' subdir. Once we're finished, we'll move the new cluster's files
# back into $PGDATA.
cd "$PGDATA"
sudo -u postgres mkdir -p 9.5 12
chmod 700 9.5 12
sudo -u postgres mv !(9.5|12) 9.5

sudo -u postgres /usr/lib/postgresql/12/bin/initdb \
	--encoding utf8 \
	--username musicbrainz \
	"$PGDATA_NEW"

git clone -b "v0.4.1" --depth=1 https://github.com/omniti-labs/pg_amqp.git "$PGAMQP_DIR"
cd "$PGAMQP_DIR"
make PG_CONFIG=/usr/lib/postgresql/12/bin/pg_config
make install
cd "$PGDATA"

sudo -u postgres /usr/lib/postgresql/12/bin/pg_upgrade \
	--old-bindir=/usr/lib/postgresql/9.5/bin/ \
	--new-bindir=/usr/lib/postgresql/12/bin/ \
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

# Start the new cluster in the background, so we can apply
# 20200518-pg12-after-upgrade.sql via the website container.
sudo -u postgres /usr/lib/postgresql/12/bin/pg_ctl start -w -D "$PGDATA"

./delete_old_cluster.sh
rm delete_old_cluster.sh
