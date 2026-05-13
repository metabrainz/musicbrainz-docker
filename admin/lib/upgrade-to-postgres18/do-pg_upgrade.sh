#!/bin/bash

set -e
shopt -s dotglob extglob nullglob

# The v16 `db` container had `PGDATA` as its volume root, i.e.,
# `pgdata:/var/lib/postgresql/data`. To align with changes in the
# official postgres base image (which also simplifies future upgrades),
# the postgres *home directory* is now the volume root, i.e.,
# `pgdata:/var/lib/postgresql`.

PGHOME=/var/lib/postgresql
PGDATA_OLD="$PGHOME"/16/docker
PGDATA_NEW="$PGHOME"/18/docker
PGBIN_OLD=/usr/lib/postgresql/16/bin
PGBIN_NEW=/usr/lib/postgresql/18/bin

cd "$PGHOME"
mkdir -p 16/docker
chmod 700 16 16/docker
mv -- !(16) 16/docker/

mkdir -p 18/docker
chmod 700 18 18/docker

# Setup postgres user/group identically to the official postgres image:
# https://github.com/docker-library/postgres/blob/6edb0a8/18/trixie/Dockerfile#L10-L16
echo "$(date) : Adding 'postgres' user and group"
groupadd -r postgres --gid=999
useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres

echo "$(date) : Ensuring 'postgres' ownership of $PGHOME"
chown -R postgres:postgres "$PGHOME"

echo "$(date) : Installing upgrade dependencies"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install \
    --no-install-suggests \
    --no-install-recommends \
    -qq \
    ca-certificates \
    gcc \
    git \
    locales \
    make \
    postgresql-common \
    sudo

# The v16 cluster uses the en_US.UTF-8 locale.
echo "$(date) : Generating the en_US.UTF-8 locale"
sed -i 's/^# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen en_US.UTF-8

echo "$(date) : Setting up the PGDB APT repository"
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y

echo "$(date) :  Installing PostgreSQL versions 16 and 18"
# Disable default cluster creation so we don't have to drop it later.
sed -i 's/^#create_main_cluster = true/create_main_cluster = false/' \
  /etc/postgresql-common/createcluster.conf

apt-get install \
    --no-install-suggests \
    --no-install-recommends \
    -qq \
    postgresql-16 \
    postgresql-18 \
    postgresql-client-16 \
    postgresql-client-18 \
    postgresql-server-dev-16 \
    postgresql-server-dev-18

# Data checksums are now enabled by default in v18, so we have to enable them
# in the old cluster before running `pg_upgrade`.
echo "$(date) : Enabling checksums in the old cluster"
sudo -u postgres $PGBIN_OLD/pg_checksums --pgdata="$PGDATA_OLD" --enable

echo "$(date) : Initializing the new cluster"
sudo -u postgres $PGBIN_NEW/initdb \
    -D "$PGDATA_NEW" \
    --encoding UTF8 \
    --locale en_US.UTF-8 \
    --username musicbrainz

echo "$(date) : Running the upgrade"
sudo -E -u postgres $PGBIN_NEW/pg_upgrade \
    --old-bindir=$PGBIN_OLD/ \
    --new-bindir=$PGBIN_NEW/ \
    --old-datadir="$PGDATA_OLD" \
    --new-datadir="$PGDATA_NEW" \
    --jobs=3 \
    --old-options="-D $PGDATA_OLD -c config_file=$PGDATA_OLD/postgresql.conf -c hba_file=$PGDATA_OLD/pg_hba.conf -c port=5432" \
    --new-options="-D $PGDATA_NEW -c config_file=$PGDATA_OLD/postgresql.conf -c hba_file=$PGDATA_OLD/pg_hba.conf -c port=6432" \
    --old-port=5432 \
    --new-port=6432 \
    --link \
    --username=musicbrainz

echo "$(date) : Deleting the old cluster"
./delete_old_cluster.sh
rm -rf delete_old_cluster.sh 16

echo "$(date) : Updating the new cluster configuration"
# Set listen_addresses = '*' as in the postgres image:
# https://github.com/docker-library/postgres/blob/2353f03/18/trixie/Dockerfile#L179-L184
sed -ri "s|^#?(listen_addresses)\s*=\s*\S+.*|\1 = '*'|" "$PGDATA_NEW"/postgresql.conf

# Allow password authentication. Note: scram-sha-256 became the default in
# v14, so older setups may have passwords stored with md5 encryption still.
echo 'host all all all md5' >> "$PGDATA_NEW"/pg_hba.conf
echo 'host all all all scram-sha-256' >> "$PGDATA_NEW"/pg_hba.conf

echo "$(date) : Starting the new cluster"
sudo -u postgres $PGBIN_NEW/pg_ctl -D "$PGDATA_NEW" start -w

if [[ -f update_extensions.sql ]]; then
    echo "$(date) : Running update_extensions.sql"
    $PGBIN_NEW/psql -U musicbrainz -d template1 -tA -P pager=off -f update_extensions.sql
    rm update_extensions.sql
fi

echo "$(date) : Stopping the new cluster"
sudo -u postgres $PGBIN_NEW/pg_ctl -D "$PGDATA_NEW" stop -w
