#!/bin/bash
# Starts up postgresql within the container.

# Stop on error
set -e
DATA_DIR="$1"

if [ $DATA_DIR == "" ]; then
	echo 'you need to set a data directory in run.sh'
	exit 1;
    else
    DATA_DIR_MAIN="$DATA_DIR/main"	
fi
if [ ! -d "$DATA_DIR_MAIN" ]; then
	mkdir $DATA_DIR_MAIN
fi
if [[ -e /scripts/firstrun ]]; then
	# Echo out info to later obtain by running `docker logs container_name`
	echo "POSTGRES_DATA_DIR=$DATA_DIR"

	# test if DATA_DIR has content
	if [[ ! "$(ls -A $DATA_DIR_MAIN)" ]]; then
	echo "Initializing PostgreSQL at $DATA_DIR_MAIN"
	# Copy the data that we generated within the container to the empty DATA_DIR.
	cp -R /var/lib/postgresql/9.3/main/* $DATA_DIR_MAIN
	fi
	echo "$(ls -al $DATA_DIR_MAIN)"
	# Ensure we have the right permissions set on the DATA_DIR
	chown -R postgres.root $DATA_DIR_MAIN
	chmod -R 700 $DATA_DIR_MAIN

	rm /scripts/firstrun

fi

echo $(ls -al $DATA_DIR_MAIN)
# Start PostgreSQL
echo "Starting PostgreSQL..."
exec su - postgres -c "/usr/lib/postgresql/9.3/bin/postgres -D /var/lib/postgresql/9.3/main -c config_file=/etc/postgresql/9.3/main/postgresql.conf -c data_directory=$DATA_DIR_MAIN"
